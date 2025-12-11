import 'package:isar/isar.dart';

part 'training_session.g.dart';

@collection
class TrainingSession {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String userId;
  
  late DateTime date;
  late int dayNumber; // 1-28 (4 weeks)
  
  late String exercisePackage; // e.g., "moro_reflex"
  late List<String> completedExercises;
  
  late bool isCompleted;
  DateTime? completedAt;
  
  // Sync metadata
  late String firestoreId;
  late bool needsSync;
}
