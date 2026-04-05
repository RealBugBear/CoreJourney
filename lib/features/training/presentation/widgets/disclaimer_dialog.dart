import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class DisclaimerDialog extends StatelessWidget {
  final VoidCallback onAccept;
  const DisclaimerDialog({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.disclaimer),
      content: SingleChildScrollView(
        child: Text(l10n.disclaimerText),
      ),
      actions: [
        ElevatedButton(
          onPressed: onAccept,
          child: Text(l10n.disclaimerAccept),
        ),
      ],
    );
  }
}
