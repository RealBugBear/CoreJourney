import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/training/domain/services/audio_announcement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioAnnouncementService', () {
    test('is a singleton', () {
      expect(
        AudioAnnouncementService.instance,
        same(AudioAnnouncementService.instance),
      );
    });

    test('stop() does not throw when nothing is playing', () {
      expect(() => AudioAnnouncementService.instance.stop(), returnsNormally);
    });
  });
}
