import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/onboarding/presentation/providers/entry_points_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('starts empty', () {
    final c = makeContainer();
    expect(c.read(entryPointsProvider), isEmpty);
  });

  test('toggle adds key', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    expect(c.read(entryPointsProvider), contains('mein_kind'));
  });

  test('toggle removes already-selected key', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    expect(c.read(entryPointsProvider), isEmpty);
  });

  test('multiple keys selectable simultaneously', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('koerper_therapie');
    c.read(entryPointsProvider.notifier).toggle('neugierde');
    expect(
      c.read(entryPointsProvider),
      containsAll(['koerper_therapie', 'neugierde']),
    );
  });
}
