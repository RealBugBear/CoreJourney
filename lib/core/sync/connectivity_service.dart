import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

class ConnectivityService {
  static Future<bool> isConnected() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // connectivity_plus channel unavailable (e.g. iOS 26 plugin issue).
      // Assume connected so drain() attempts sync — Supabase calls will
      // fail normally and retry if there's truly no network.
      return true;
    }
  }
}
