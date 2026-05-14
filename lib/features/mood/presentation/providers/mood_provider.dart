import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../data/repositories/mood_repository.dart';
import '../../domain/models/mood_daily_aggregate.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepository(
    ref.read(databaseProvider),
    ref.read(syncServiceProvider),
    ref.read(appClockProvider),
  );
});

/// 0 = all time, otherwise number of days to look back.
final moodCheckinsProvider = FutureProvider.autoDispose
    .family<List<MoodCheckinsTableData>, int>((ref, days) async {
  final db = ref.read(databaseProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;
  final now = ref.watch(appClockProvider).now();

  if (userId == null || enrollmentId == null) return [];

  final query = db.select(db.moodCheckinsTable)
    ..where(
        (t) => t.userId.equals(userId) & t.enrollmentId.equals(enrollmentId))
    ..orderBy([(t) => drift.OrderingTerm.asc(t.recordedAt)]);

  if (days > 0) {
    final cutoff = now.subtract(Duration(days: days));
    query.where((t) => t.recordedAt.isBiggerOrEqualValue(cutoff));
  }

  return query.get();
});

final moodDailyAggregatesProvider = FutureProvider.autoDispose
    .family<List<MoodDailyAggregate>, int>((ref, days) async {
  final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;
  final now = ref.watch(appClockProvider).now();
  if (enrollmentId == null) return [];

  final from = days <= 0
      ? DateTime(1970)
      : DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

  return ref.read(moodRepositoryProvider).getDailyAggregatesInRange(
        enrollmentId: enrollmentId,
        from: from,
        to: now,
      );
});

final moodNotesProvider = FutureProvider.autoDispose
    .family<List<MoodCheckinsTableData>, int>((ref, days) async {
  final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;
  final now = ref.watch(appClockProvider).now();
  if (enrollmentId == null) return [];

  final from = days <= 0
      ? DateTime(1970)
      : DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

  return ref.read(moodRepositoryProvider).getNotesInRange(
        enrollmentId: enrollmentId,
        from: from,
        to: now,
      );
});

/// Parameter for profile-scoped mood providers.
class ProfileMoodLookup {
  const ProfileMoodLookup({required this.days, required this.subjectProfileId});
  final int days;
  final String subjectProfileId;

  @override
  bool operator ==(Object other) =>
      other is ProfileMoodLookup &&
      other.days == days &&
      other.subjectProfileId == subjectProfileId;

  @override
  int get hashCode => Object.hash(days, subjectProfileId);
}

final profileMoodAggregatesProvider = FutureProvider.autoDispose
    .family<List<MoodDailyAggregate>, ProfileMoodLookup>((ref, lookup) async {
  final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;
  final now = ref.watch(appClockProvider).now();
  if (enrollmentId == null) return [];

  final from = lookup.days <= 0
      ? DateTime(1970)
      : DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: lookup.days));

  return ref.read(moodRepositoryProvider).getDailyAggregatesInRange(
        enrollmentId: enrollmentId,
        from: from,
        to: now,
        subjectProfileId: lookup.subjectProfileId,
      );
});
