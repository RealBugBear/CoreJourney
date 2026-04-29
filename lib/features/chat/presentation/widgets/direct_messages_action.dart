import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../providers/chat_providers.dart';

class DirectMessagesAction extends ConsumerWidget {
  const DirectMessagesAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerLinked = ref.watch(trainerLinkedProvider);
    if (!trainerLinked) return const SizedBox.shrink();

    final unreadDm = ref.watch(unreadDmCountProvider);

    return IconButton(
      tooltip: 'Trainer-Kommunikation',
      onPressed: () => context.push(Routes.dm),
      icon: Badge(
        isLabelVisible: unreadDm > 0,
        label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
