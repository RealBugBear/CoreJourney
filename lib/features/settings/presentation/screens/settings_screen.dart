import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settingsTraining),
            leading: const Icon(Icons.fitness_center_outlined),
            onTap: () {},
          ),
          ListTile(
            title: Text(l10n.settingsReminders),
            leading: const Icon(Icons.notifications_outlined),
            onTap: () {},
          ),
          ListTile(
            title: Text(l10n.settingsLanguage),
            leading: const Icon(Icons.language_outlined),
            onTap: () {},
          ),
          ListTile(
            title: Text(l10n.settingsTheme),
            leading: const Icon(Icons.palette_outlined),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.signOut),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
