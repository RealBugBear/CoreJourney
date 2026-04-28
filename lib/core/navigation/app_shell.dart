import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/trainer/presentation/providers/trainer_provider.dart';
import 'app_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  List<String> _buildTabRoutes(bool trainerLinked) => [
        Routes.dashboard,
        Routes.community,
        Routes.trainerDiscovery,
        if (trainerLinked) Routes.dm,
        Routes.profile,
      ];

  int _currentIndex(BuildContext context, List<String> tabRoutes) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabRoutes.length; i++) {
      if (location.startsWith(tabRoutes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerLinked = ref.watch(trainerLinkedProvider);
    final unreadDm = ref.watch(unreadDmCountProvider);
    final tabRoutes = _buildTabRoutes(trainerLinked);
    final currentIndex = _currentIndex(context, tabRoutes);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabRoutes[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Trainer',
          ),
          if (trainerLinked)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadDm > 0,
                label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadDm > 0,
                label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
                child: const Icon(Icons.chat_bubble),
              ),
              label: 'Nachrichten',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
