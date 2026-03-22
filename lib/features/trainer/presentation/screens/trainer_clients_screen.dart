import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class TrainerClientsScreen extends StatelessWidget {
  const TrainerClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerClients)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.trainerNoClients,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: generate invite code
        },
        label: Text(l10n.trainerGenerateCode),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
