import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trainer/domain/models/trainer_application.dart';
import '../../../trainer/presentation/providers/trainer_application_provider.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref.invalidate(adminUsersProvider);
                ref.invalidate(trainerApplicationsForReviewProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bewerbungen'),
              Tab(text: 'Bestätigte Trainer'),
              Tab(text: 'Premium'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TrainerApplicationsTab(),
            _ConfirmedTrainersTab(),
            _PremiumTab(),
          ],
        ),
      ),
    );
  }
}

// ── Premium Tab ───────────────────────────────────────────────────────────────

class _PremiumTab extends ConsumerWidget {
  const _PremiumTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (users) {
        final practitioners =
            users.where((u) => u.role == 'practitioner').toList();
        if (practitioners.isEmpty) {
          return const Center(child: Text('Keine Nutzer gefunden.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: practitioners.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = practitioners[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(user.isPremium ? 'Premium' : 'Free'),
              trailing: Switch(
                value: user.isPremium,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(adminUsersProvider.notifier)
                        .setTier(user.id, value ? 'premium' : 'free');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── Trainer Applications Tab ──────────────────────────────────────────────────

class _TrainerApplicationsTab extends ConsumerWidget {
  const _TrainerApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApplications = ref.watch(trainerApplicationsForReviewProvider);

    return asyncApplications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (applications) {
        final openApplications = applications.where((a) => a.isOpen).toList();
        if (openApplications.isEmpty) {
          return const Center(child: Text('Keine Trainer-Bewerbungen.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: openApplications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _TrainerApplicationCard(application: openApplications[i]),
        );
      },
    );
  }
}

class _ConfirmedTrainersTab extends ConsumerWidget {
  const _ConfirmedTrainersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApplications = ref.watch(trainerApplicationsForReviewProvider);

    return asyncApplications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (applications) {
        final confirmed = applications
            .where((a) => a.status == TrainerApplicationStatus.approved)
            .toList();
        if (confirmed.isEmpty) {
          return const Center(child: Text('Noch keine bestätigten Trainer.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: confirmed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _ConfirmedTrainerCard(application: confirmed[i]),
        );
      },
    );
  }
}

class _ConfirmedTrainerCard extends StatelessWidget {
  const _ConfirmedTrainerCard({required this.application});

  final TrainerApplication application;

  @override
  Widget build(BuildContext context) {
    final displayName =
        application.desiredDisplayName?.trim().isNotEmpty == true
            ? application.desiredDisplayName!.trim()
            : application.fullName;
    final approvedDate = application.reviewedAt?.toLocal().toString().substring(
              0,
              10,
            ) ??
        '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.verified_user_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        application.fullName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        application.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (application.desiredBio?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(application.desiredBio!.trim()),
            ],
            if (application.city != null || application.phone != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (application.city != null) application.city,
                  if (application.phone != null) application.phone,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Bestätigt am $approvedDate'),
                ),
              ],
            ),
            if (application.activationCode != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Code: ${application.activationCode}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: application.reviewChannelId == null
                      ? null
                      : () => context.push(
                            Routes.dmChannel.replaceFirst(
                              ':channelId',
                              application.reviewChannelId!,
                            ),
                          ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Review-Kanal'),
                ),
                if (application.activationCode != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: application.activationCode!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code kopiert')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Code kopieren'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerApplicationCard extends ConsumerWidget {
  const _TrainerApplicationCard({required this.application});

  final TrainerApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(trainerApplicationsForReviewProvider.notifier);

    Future<void> markSeen() async {
      await notifier.markBackgroundCheckSeen(application.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sichtprüfung dokumentiert.')),
        );
      }
    }

    Future<void> approve() async {
      if (!application.canApprove) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vor der Genehmigung muss die Sichtprüfung dokumentiert sein.',
            ),
          ),
        );
        return;
      }

      String code;
      try {
        code = await notifier.approve(application.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code konnte nicht erzeugt werden: $e')),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Aktivierungscode erzeugt'),
            content: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Kopieren'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        );
      }
    }

    Future<void> needsMoreInfo() async {
      await notifier.needsMoreInfo(application.id);
      if (context.mounted) {
        if (application.reviewChannelId != null) {
          context.push(
            Routes.dmChannel.replaceFirst(
              ':channelId',
              application.reviewChannelId!,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rückfrage-Status gesetzt.')),
          );
        }
      }
    }

    Future<void> reject() async {
      await notifier.reject(application.id);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.assignment_ind_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(application.statusLabel,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(application.email,
                          style: Theme.of(context).textTheme.bodySmall),
                      if (application.phone != null)
                        Text(application.phone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (application.city != null) ...[
              const SizedBox(height: 8),
              Text('Region: ${application.city}'),
            ],
            const SizedBox(height: 8),
            Text(application.professionalBackground),
            if (application.motivation != null) ...[
              const SizedBox(height: 8),
              Text(application.motivation!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  application.hasBackgroundCheck
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: application.hasBackgroundCheck
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Führungszeugnis Stufe 2 per Sichtprüfung'),
                ),
              ],
            ),
            if (application.activationCode != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Code: ${application.activationCode}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Eingereicht: ${application.createdAt.toLocal().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: application.hasBackgroundCheck ? null : markSeen,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Sichtprüfung erledigt'),
                ),
                OutlinedButton(
                  onPressed: application.isOpen ? needsMoreInfo : null,
                  child: const Text('Infos anfordern'),
                ),
                OutlinedButton.icon(
                  onPressed: application.reviewChannelId == null
                      ? null
                      : () => context.push(
                            Routes.dmChannel.replaceFirst(
                              ':channelId',
                              application.reviewChannelId!,
                            ),
                          ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Review-Kanal'),
                ),
                OutlinedButton(
                  onPressed: application.isOpen ? reject : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Ablehnen'),
                ),
                FilledButton(
                  onPressed: application.isOpen ? approve : null,
                  child: const Text('Genehmigen & Code erzeugen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
