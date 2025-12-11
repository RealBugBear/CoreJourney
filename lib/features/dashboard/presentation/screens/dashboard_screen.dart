import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../training/presentation/screens/training_flow_screen.dart';
import '../../../training/presentation/providers/training_flow_provider.dart';
import '../../../training/presentation/widgets/animated_progress_bar.dart';
import '../../../training/presentation/widgets/training_disclaimer_dialog.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize progress on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProgressIfNeeded();
    });
  }

  Future<void> _initializeProgressIfNeeded() async {
    final progressService = ref.read(progressServiceProvider);
    final progress = await progressService.getCurrentProgress();
    
    if (progress == null) {
      // Initialize progress for new user
      await progressService.initializeProgress();
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressService = ref.watch(progressServiceProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreJourney'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: progressService.getCurrentProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = snapshot.data;
          
          if (progress == null) {
            return const Center(
              child: Text('Lade Fortschritt...'),
            );
          }

          final currentDay = progress.currentDay;
          final totalDays = progress.totalDays;
          final goldenDay = progress.goldenDayDate;
          final hasReachedGoldenDay = progress.hasReachedGoldenDay;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Hallo${user?.displayName != null ? " ${user!.displayName}" : ""}!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasReachedGoldenDay
                      ? '🎉 Du hast deinen Golden Day erreicht!'
                      : 'Bereit für dein heutiges Training?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: hasReachedGoldenDay ? theme.colorScheme.primary : Colors.grey[600],
                    fontWeight: hasReachedGoldenDay ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Progress Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.05),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.trending_up,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Dein Fortschritt',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Animated Progress Bar
                          AnimatedProgressBar(
                            currentStep: currentDay,
                            totalSteps: totalDays,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Golden Day Info with icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasReachedGoldenDay 
                                  ? const Color(0xFFFFD700).withOpacity(0.2)
                                  : theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasReachedGoldenDay
                                    ? const Color(0xFFFFD700)
                                    : theme.colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasReachedGoldenDay ? Icons.emoji_events : Icons.calendar_today,
                                  color: hasReachedGoldenDay 
                                      ? const Color(0xFFFFD700)
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasReachedGoldenDay 
                                            ? '🎉 Golden Day erreicht!'
                                            : 'Golden Day',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: hasReachedGoldenDay
                                              ? const Color(0xFFFFD700)
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd.MM.yyyy').format(goldenDay),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (progress.consecutiveInactiveDays > 0) ...[ const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Golden Day verschoben wegen Inaktivität',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Start Training Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      final progressService = ref.read(progressServiceProvider);
                      final currentProgress = await progressService.getCurrentProgress();
                      
                      if (currentProgress == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fehler beim Laden des Fortschritts'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Check if disclaimer should be shown
                      final shouldShowDisclaimer = progressService.shouldShowDisclaimer(currentProgress);
                      
                      if (shouldShowDisclaimer && context.mounted) {
                        // Show disclaimer dialog
                        final accepted = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false, // Must choose
                          builder: (context) => TrainingDisclaimerDialog(
                            onAccept: () => Navigator.of(context).pop(true),
                            onDecline: () => Navigator.of(context).pop(false),
                          ),
                        );
                        
                        // If user declined, don't start training
                        if (accepted != true) {
                          return;
                        }
                        
                        // Record disclaimer acceptance
                        if (context.mounted) {
                          await progressService.recordDisclaimerAcceptance(currentProgress);
                        }
                      }
                      
                      if (!context.mounted) return;
                      
                      // Reset training flow state
                      ref.read(trainingFlowProvider.notifier).startTraining();
                      
                      // Navigate to training flow
                      final completed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => const TrainingFlowScreen(),
                        ),
                      );
                      
                      // If training was completed, increment disclaimer counter and refresh
                      if (completed == true && mounted) {
                        final updatedProgress = await progressService.getCurrentProgress();
                        if (updatedProgress != null) {
                          await progressService.incrementDisclaimerCounter(updatedProgress);
                        }
                        
                        setState(() {}); // Refresh progress
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Training erfolgreich abgeschlossen!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_filled, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Training starten',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Quick Stats
                Text(
                  'Übersicht',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        color: Colors.green,
                        value: '$currentDay',
                        label: 'Abgeschlossen',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                        value: '${totalDays - currentDay}',
                        label: 'Verbleibend',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
