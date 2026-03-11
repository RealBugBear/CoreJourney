import 'package:isar/isar.dart';

part 'mood_checkin.g.dart';

enum MoodCheckinSource {
  postTrainingPrompt,
  manualNote,
}

@collection
class MoodCheckin {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String packageId;

  @Index()
  late DateTime recordedAt;

  // Local day key in UTC midnight milliseconds for stable day-grouping queries.
  @Index()
  late int dayKey;

  String? sessionId;
  int? mood; // 1..5
  int? energy; // 1..5
  int? stress; // 1..5
  String? note;

  @enumerated
  late MoodCheckinSource source;

  // Sync metadata
  late String firestoreId;
  late bool needsSync;
}
