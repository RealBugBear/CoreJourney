import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntryPointsNotifier extends StateNotifier<List<String>> {
  EntryPointsNotifier() : super(const []);

  void toggle(String key) {
    if (state.contains(key)) {
      state = state.where((k) => k != key).toList();
    } else {
      state = [...state, key];
    }
  }
}

final entryPointsProvider =
    StateNotifierProvider<EntryPointsNotifier, List<String>>(
  (ref) => EntryPointsNotifier(),
);
