import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/community/presentation/screens/community_screen.dart';

void main() {
  testWidgets('CommunityScreen renders placeholder text and icon', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const CommunityScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community'), findsWidgets);
    expect(find.text('Hier entsteht bald deine Community.'), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  });
}
