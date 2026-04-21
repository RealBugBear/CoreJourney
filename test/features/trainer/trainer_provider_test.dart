import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';

void main() {
  test('trainerLinkedProvider is false when clientTrainerProvider is null', () {
    final container = ProviderContainer(
      overrides: [
        clientTrainerProvider.overrideWith((ref) => Future.value(null)),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(trainerLinkedProvider), false);
  });

  test('trainerLinkedProvider is true when clientTrainerProvider has a name', () async {
    final container = ProviderContainer(
      overrides: [
        clientTrainerProvider.overrideWith((ref) => Future.value('Max Trainer')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(clientTrainerProvider.future);
    expect(container.read(trainerLinkedProvider), true);
  });
}
