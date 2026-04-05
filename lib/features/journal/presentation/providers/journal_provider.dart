import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../mood/domain/models/mood_daily_aggregate.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';

class JournalState {
  final List<MoodCheckinsTableData> entries;
  final List<MoodDailyAggregate> aggregates;
  final bool isLoading;
  final String? error;

  const JournalState({
    required this.entries,
    required this.aggregates,
    required this.isLoading,
    this.error,
  });

  factory JournalState.initial() => const JournalState(
        entries: [],
        aggregates: [],
        isLoading: false,
      );

  JournalState copyWith({
    List<MoodCheckinsTableData>? entries,
    List<MoodDailyAggregate>? aggregates,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      aggregates: aggregates ?? this.aggregates,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class JournalNotifier extends StateNotifier<JournalState> {
  final Ref _ref;

  JournalNotifier(this._ref) : super(JournalState.initial()) {
    load();
  }

  String? get _enrollmentId =>
      _ref.read(activeEnrollmentProvider).valueOrNull?.id;

  DateTime _defaultFrom() {
    final now = _ref.read(appClockProvider).now();
    return DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 90));
  }

  void _setStateIfMounted(JournalState newState) {
    if (!mounted) return;
    state = newState;
  }

  Future<void> load({DateTime? from, DateTime? to}) async {
    final enrollmentId = _enrollmentId;
    if (enrollmentId == null) {
      _setStateIfMounted(state.copyWith(
        entries: [],
        aggregates: [],
        isLoading: false,
        clearError: true,
      ));
      return;
    }

    _setStateIfMounted(state.copyWith(isLoading: true, clearError: true));
    try {
      final repo = _ref.read(moodRepositoryProvider);
      final effectiveFrom = from ?? _defaultFrom();
      final effectiveTo = to ?? _ref.read(appClockProvider).now();

      final entries = await repo.getNotesInRange(
        enrollmentId: enrollmentId,
        from: effectiveFrom,
        to: effectiveTo,
      );
      final aggregates = await repo.getDailyAggregatesInRange(
        enrollmentId: enrollmentId,
        from: effectiveFrom,
        to: effectiveTo,
      );

      _setStateIfMounted(state.copyWith(
        entries: entries,
        aggregates: aggregates,
        isLoading: false,
      ));
    } catch (e) {
      _setStateIfMounted(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> addEntry({
    required int mood,
    required int energy,
    required int stress,
    String? note,
  }) async {
    final enrollmentId = _enrollmentId;
    if (enrollmentId == null) return;
    await _ref.read(moodRepositoryProvider).createCheckin(
          enrollmentId: enrollmentId,
          mood: mood,
          energy: energy,
          stress: stress,
          note: note,
          source: 'manual',
        );
    await load();
  }

  Future<void> updateEntry({
    required String id,
    required int mood,
    required int energy,
    required int stress,
    String? note,
  }) async {
    await _ref.read(moodRepositoryProvider).updateCheckin(
          id: id,
          mood: mood,
          energy: energy,
          stress: stress,
          note: note,
        );
    await load();
  }

  Future<void> deleteEntry(String id) async {
    await _ref.read(moodRepositoryProvider).deleteCheckin(id: id);
    await load();
  }
}

final journalProvider =
    StateNotifierProvider.autoDispose<JournalNotifier, JournalState>((ref) {
  ref.watch(activeEnrollmentProvider);
  return JournalNotifier(ref);
});
