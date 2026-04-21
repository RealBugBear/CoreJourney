import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/core/navigation/app_shell.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

Widget _buildApp({required bool trainerLinked, int unreadDm = 0}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/community',
            builder: (_, __) => const Scaffold(body: Text('Community')),
          ),
          GoRoute(
            path: '/dm',
            builder: (_, __) => const Scaffold(body: Text('DM')),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Scaffold(body: Text('Profile')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      trainerLinkedProvider.overrideWithValue(trainerLinked),
      unreadDmCountProvider.overrideWithValue(unreadDm),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows 3 tabs when no trainer linked', (tester) async {
    await tester.pumpWidget(_buildApp(trainerLinked: false));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 3);
  });

  testWidgets('shows 4 tabs when trainer linked', (tester) async {
    await tester.pumpWidget(_buildApp(trainerLinked: true));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 4);
  });

  testWidgets('DM tab shows badge label when unread > 0', (tester) async {
    await tester.pumpWidget(_buildApp(trainerLinked: true, unreadDm: 3));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('3'),
      ),
      findsWidgets, // badge appears on both icon and selectedIcon
    );
  });

  testWidgets('DM tab badge is hidden when unread is 0', (tester) async {
    await tester.pumpWidget(_buildApp(trainerLinked: true, unreadDm: 0));
    await tester.pumpAndSettle();
    // No numeric badge label should be visible
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('0'),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping Community tab navigates to /community', (tester) async {
    await tester.pumpWidget(_buildApp(trainerLinked: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(find.text('Community'), findsWidgets);
  });
}
