import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/experience_repository.dart';
import '../../domain/models/experience_share.dart';

final experienceRepositoryProvider =
    Provider<ExperienceRepository>((_) => ExperienceRepository());

final experienceSharesProvider =
    FutureProvider.autoDispose.family<List<ExperienceShare>, String>(
  (ref, packageId) =>
      ref.read(experienceRepositoryProvider).getShares(packageId),
);

class DeleteShareNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteOwn(String shareId, String packageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(experienceRepositoryProvider).deleteOwnShare(shareId),
    );
    ref.invalidate(experienceSharesProvider(packageId));
  }

  Future<void> deleteModerator(String shareId, String packageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(experienceRepositoryProvider).moderatorDeleteShare(shareId),
    );
    ref.invalidate(experienceSharesProvider(packageId));
  }
}

final deleteShareProvider =
    AsyncNotifierProvider.autoDispose<DeleteShareNotifier, void>(
  DeleteShareNotifier.new,
);
