import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../data/repositories/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid ?? 'unknown';
  return MoodRepository(database, sync, userId);
});
