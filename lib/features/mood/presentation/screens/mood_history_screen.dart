import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moodCheckIn)),
      body: Center(child: Text(l10n.moodChartEmpty)),
    );
  }
}
