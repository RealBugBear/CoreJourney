import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_clock.dart';

final appClockProvider = ChangeNotifierProvider<AppClock>((ref) {
  return AppClock();
});
