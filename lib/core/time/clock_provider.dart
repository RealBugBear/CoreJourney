import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feature_flags/feature_flag_provider.dart';
import 'app_clock.dart';

final appClockProvider = Provider<AppClock>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppClock(prefs);
});
