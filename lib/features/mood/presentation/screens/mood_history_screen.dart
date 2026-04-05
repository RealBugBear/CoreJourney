import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/mood_chart_widget.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).moodHistory)),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: MoodChartWidget(),
        ),
      ),
    );
  }
}
