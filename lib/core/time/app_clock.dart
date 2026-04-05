import 'package:flutter/foundation.dart';

// Provides the app's notion of "now". In production this stays unshifted.
class AppClock extends ChangeNotifier {
  Duration _offset = Duration.zero;

  Duration get offset => _offset;

  DateTime now() => DateTime.now().add(_offset);

  void setOffset(Duration offset) {
    if (_offset == offset) return;
    _offset = offset;
    notifyListeners();
  }

  void reset() {
    if (_offset == Duration.zero) return;
    _offset = Duration.zero;
    notifyListeners();
  }
}
