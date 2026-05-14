import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftPersistenceService {
  static String _key(String profileId) => 'reflex_draft_$profileId';

  Future<void> saveLocal(String profileId, Map<String, dynamic> draftJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(profileId), jsonEncode(draftJson));
    } catch (e) {
      debugPrint('[DraftPersistenceService] saveLocal failed: $e');
    }
  }

  Future<Map<String, dynamic>?> loadLocal(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(profileId));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await clearLocal(profileId);
      return null;
    }
  }

  Future<void> clearLocal(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(profileId));
    } catch (e) {
      debugPrint('[DraftPersistenceService] clearLocal failed: $e');
    }
  }
}
