import 'package:isar/isar.dart';

part 'sync_job.g.dart';

@collection
class SyncJob {
  Id id = Isar.autoIncrement;
  
  late String collection;
  late String docId;
  late String action; // 'create', 'update', 'delete'
  late String payload; // JSON string
  
  late DateTime createdAt;
  DateTime? lastAttempt;
  
  @Index()
  int retryCount = 0;
}
