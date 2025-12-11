import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../bootstrap/providers.dart';
import '../../../progress/domain/services/progress_service.dart';
import '../../../../core/services/notification_service.dart';

final progressServiceProvider = Provider<ProgressService>((ref) {
  final database = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  // We need to access NotificationService. Since it's a singleton, we can use it directly
  // or better, create a provider for it.
  // For now, let's use the singleton as we haven't created a provider for it yet.
  final notifications = NotificationService();
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid ?? 'unknown';
  return ProgressService(database, sync, notifications, userId);
});
