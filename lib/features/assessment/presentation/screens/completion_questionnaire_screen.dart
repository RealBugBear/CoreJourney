import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';

class CompletionQuestionnaireScreen extends StatelessWidget {
  const CompletionQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.completionQuestionnaireTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.completionQuestion,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: mark enrollment complete, navigate to next package
                  context.go(Routes.dashboard);
                },
                child: Text(l10n.completionYes),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: add 1 week to enrollment
                  context.go(Routes.dashboard);
                },
                child: Text(l10n.completionNotYet),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
