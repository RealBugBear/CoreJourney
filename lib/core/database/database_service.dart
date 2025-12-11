import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/training/domain/models/training_session.dart';
import '../../features/progress/domain/models/progress_entry.dart';
import '../sync/models/sync_job.dart';

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        TrainingSessionSchema,
        ProgressEntrySchema,
        SyncJobSchema,
      ],
      directory: dir.path,
    );
  }

  Future<void> clean() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
  
  Future<void> close() async {
    await isar.close();
  }
}
