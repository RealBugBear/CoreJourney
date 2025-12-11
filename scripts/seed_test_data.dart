import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to seed test accounts with different training states
/// 
/// Usage: dart run scripts/seed_test_data.dart --env=dev
/// 
/// Creates 6 test accounts:
/// 1. test-new@corejourney.app - 0/28 days
/// 2. test-week1@corejourney.app - 7/28 days
/// 3. test-halfway@corejourney.app - 14/28 days
/// 4. test-almost@corejourney.app - 27/28 days
/// 5. test-golden@corejourney.app - 28/28 days (Golden Day)
/// 6. test-complete@corejourney.app - All done, ready for questionnaire

void main(List<String> arguments) async {
  // Check environment
  final env = arguments.contains('--env=prod') ? 'prod' : 'dev';
  
  if (env == 'prod') {
    print('⚠️  WARNING: Running in PRODUCTION mode!');
    print('This will create test accounts in your production Firebase.');
    print('Type "yes" to continue or anything else to cancel:');
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'yes') {
      print('Cancelled.');
      exit(0);
    }
  }

  print('🚀 Setting up test accounts for $env environment...\n');

  // Initialize Firebase
  // Note: You'll need to configure this based on your Firebase setup
  // For now, this is a template
  
  try {
    await Firebase.initializeApp(
      options: env == 'prod' 
          ? null // Use production config
          : null, // Use dev config
    );
  } catch (e) {
    print('Firebase already initialized');
  }

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  const password = 'TestDemo2025!';
  
  final accounts = [
    TestAccount(
      email: 'test-new@corejourney.app',
      displayName: 'New User',
      completedDays: 0,
      description: 'Brand new user, no training completed',
    ),
    TestAccount(
      email: 'test-week1@corejourney.app',
      displayName: 'Week 1 Complete',
      completedDays: 7,
      description: 'Completed first week (7/28)',
    ),
    TestAccount(
      email: 'test-halfway@corejourney.app',
      displayName: 'Halfway There',
      completedDays: 14,
      description: 'Completed half the journey (14/28)',
    ),
    TestAccount(
      email: 'test-almost@corejourney.app',
      displayName: 'Almost Done',
      completedDays: 27,
      description: 'One day away from Golden Day (27/28)',
    ),
    TestAccount(
      email: 'test-golden@corejourney.app',
      displayName: 'Golden Day',
      completedDays: 28,
      description: 'Completed all 28 days - Golden Day!',
    ),
    TestAccount(
      email: 'test-complete@corejourney.app',
      displayName: 'Completed Journey',
      completedDays: 28,
      completedQuestionnaire: true,
      description: 'Finished everything, ready for new cycle',
    ),
  ];

  for (final account in accounts) {
    print('Creating: ${account.email}');
    
    try {
      // Try to create user
      UserCredential userCredential;
      try {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: account.email,
          password: password,
        );
        print('  ✓ Auth account created');
      } catch (e) {
        // User might already exist, try to sign in
        userCredential = await auth.signInWithEmailAndPassword(
          email: account.email,
          password: password,
        );
        print('  ℹ️  Account already exists, updating data');
      }

      final user = userCredential.user!;
      
      // Update display name
      await user.updateDisplayName(account.displayName);
      
      // Create progress data in Firestore
      if (account.completedDays > 0) {
        // Generate list of completed days
        final completedDaysList = List.generate(
          account.completedDays,
          (index) => index,
        );
        
        // Create progress entries
        final batch = firestore.batch();
        
        for (int day = 0; day < account.completedDays; day++) {
          // Calculate completion date (going backwards from today)
          final completedDate = DateTime.now().subtract(
            Duration(days: account.completedDays - day - 1),
          );
          
          // Create progress entry
          final progressRef = firestore
              .collection('users')
              .doc(user.uid)
              .collection('progress')
              .doc('day_$day');
          
          batch.set(progressRef, {
            'day': day,
            'completed': true,
            'completedAt': Timestamp.fromDate(completedDate),
            'exercises': _generateMockExercises(),
          });
        }
        
        // Set user summary
        final userRef = firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'email': account.email,
          'displayName': account.displayName,
          'totalDaysCompleted': account.completedDays,
          'currentDay': account.completedDays < 28 
              ? account.completedDays 
              : 28,
          'completedDays': completedDaysList,
          'joinedAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: account.completedDays)),
          ),
          'lastTrainingAt': Timestamp.fromDate(DateTime.now()),
          if (account.completedQuestionnaire)
            'questionnaireCompleted': true,
        }, SetOptions(merge: true));
        
        // Commit batch
        await batch.commit();
        print('  ✓ Progress data created (${account.completedDays} days)');
      } else {
        // Just create empty user document
        await firestore.collection('users').doc(user.uid).set({
          'email': account.email,
          'displayName': account.displayName,
          'totalDaysCompleted': 0,
          'currentDay': 0,
          'completedDays': [],
          'joinedAt': Timestamp.now(),
        });
        print('  ✓ User document created (no progress yet)');
      }
      
      print('  ✓ ${account.description}\n');
      
    } catch (e) {
      print('  ✗ Error: $e\n');
    }
  }

  print('\n🎉 Done! Test accounts ready.');
  print('\n📧 All accounts use password: $password');
  print('\n🔗 Firebase Console: https://console.firebase.google.com');
  print('   Go to: Authentication → Users to see all accounts');
  print('   Go to: Firestore → users collection to see data');
  
  exit(0);
}

class TestAccount {
  final String email;
  final String displayName;
  final int completedDays;
  final bool completedQuestionnaire;
  final String description;

  TestAccount({
    required this.email,
    required this.displayName,
    required this.completedDays,
    this.completedQuestionnaire = false,
    required this.description,
  });
}

/// Generate mock exercise data for completed days
Map<String, dynamic> _generateMockExercises() {
  return {
    'position': {
      'completed': true,
      'duration': 60, // seconds
    },
    'movement': {
      'completed': true,
      'duration': 120,
    },
    'exercise': {
      'completed': true,
      'duration': 180,
      'notes': 'Test data - automatically generated',
    },
  };
}
