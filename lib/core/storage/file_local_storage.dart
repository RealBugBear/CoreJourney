import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// File-based implementation of [LocalStorage] for Supabase session persistence.
///
/// Writes the auth session as a raw string file in [getApplicationSupportDirectory].
/// This bypasses SharedPreferences entirely, making it resilient to iOS
/// UserDefaults / Pigeon channel issues and correct for all platforms.
///
/// All I/O is wrapped with silent catch — if a read fails the session is treated
/// as absent (user logs in again). If a write fails the session is not cached
/// locally but Supabase still works in-memory for the current launch.
class FileLocalStorage extends LocalStorage {
  static const _kFileName = 'supabase_session.bin';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_kFileName');
  }

  @override
  Future<void> initialize() async {
    // No setup needed — file is created lazily on first persistSession call.
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      final f = await _file();
      return await f.exists() && (await f.length()) > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final s = await f.readAsString();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await (await _file()).writeAsString(persistSessionString, flush: true);
    } catch (_) {}
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
