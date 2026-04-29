import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/trainer_application_provider.dart';
import '../providers/trainer_provider.dart'
    show activateTrainerRole, userRoleProvider;

class TrainerApplicationStatusScreen extends ConsumerWidget {
  const TrainerApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationAsync = ref.watch(ownTrainerApplicationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trainer-Bewerbung')),
      body: applicationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(ownTrainerApplicationProvider),
        ),
        data: (application) {
          if (application == null) {
            return _NoApplicationState(
              onStart: () => context.go(Routes.trainerApplicationIntro),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(ownTrainerApplicationProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  application.statusLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusBody(application.statusLabel),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                const _CheckRow(
                  checked: true,
                  title: 'Bewerbung eingereicht',
                ),
                _CheckRow(
                  checked: application.hasBackgroundCheck,
                  title: 'Führungszeugnis Stufe 2 per Sichtprüfung geprüft',
                ),
                _CheckRow(
                  checked: application.activationCode != null,
                  title: 'Aktivierungscode erzeugt',
                ),
                if (application.reviewChannelId != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      Routes.dmChannel.replaceFirst(
                        ':channelId',
                        application.reviewChannelId!,
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Review-Kanal öffnen'),
                  ),
                ],
                if (application.activationCode != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      final err = await activateTrainerRole(
                          application.activationCode!);
                      if (err != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                        return;
                      }
                      ref.invalidate(userRoleProvider);
                      ref.invalidate(ownTrainerApplicationProvider);
                      if (context.mounted) {
                        context.go(Routes.trainerDashboard);
                      }
                    },
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Trainer aktivieren'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusBody(String label) {
    return switch (label) {
      'Freigegeben' =>
        'Deine Bewerbung wurde freigegeben. Aktiviere jetzt dein verifiziertes Trainerprofil.',
      'Abgelehnt' =>
        'Deine Bewerbung wurde abgelehnt. Details findest du im Review-Kanal.',
      'Rückfrage offen' =>
        'Die Admins benötigen weitere Informationen. Bitte prüfe den Review-Kanal.',
      _ =>
        'Deine Bewerbung ist im Review. Die Admins melden sich im Review-Kanal zur weiteren Prüfung.',
    };
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.checked, required this.title});
  final bool checked;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        checked ? Icons.check_circle : Icons.radio_button_unchecked,
        color: checked ? AppColors.success : AppColors.textSecondary,
      ),
      title: Text(title),
    );
  }
}

class _NoApplicationState extends StatelessWidget {
  const _NoApplicationState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 56),
              const SizedBox(height: 12),
              const Text('Noch keine Trainer-Bewerbung'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onStart,
                child: const Text('Bewerbung starten'),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: onRetry, child: const Text('Erneut versuchen')),
            ],
          ),
        ),
      );
}
