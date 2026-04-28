import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trainer/domain/models/trainer_profile.dart';
import '../../../trainer/presentation/providers/trainer_discovery_provider.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref.read(adminProvider.notifier).refresh();
                ref.invalidate(adminUsersProvider);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Trainer-Codes'),
              const Tab(text: 'Premium'),
              Tab(text: l10n.adminTrainerReviewTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TrainerCodesTab(),
            _PremiumTab(),
            _TrainerReviewTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Code generieren'),
          onPressed: () => _generateCode(context, ref),
        ),
      ),
    );
  }

  Future<void> _generateCode(BuildContext context, WidgetRef ref) async {
    try {
      final code = await ref.read(adminProvider.notifier).generate();
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Code generiert'),
            content: SelectableText(
              code.code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code.code));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code kopiert!')),
                  );
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}

// ── Trainer Codes Tab ─────────────────────────────────────────────────────────

class _TrainerCodesTab extends ConsumerWidget {
  const _TrainerCodesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codesAsync = ref.watch(adminProvider);
    return codesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Fehler: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (codes) {
        if (codes.isEmpty) {
          return const Center(
            child: Text(
              'Noch keine Trainer-Codes generiert.\nTippe unten auf „Code generieren".',
              textAlign: TextAlign.center,
            ),
          );
        }
        final active = codes.where((c) => c.isActive).toList();
        final used = codes.where((c) => c.isUsed).toList();
        final expired = codes.where((c) => c.isExpired).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (active.isNotEmpty) ...[
              _SectionHeader('Aktiv (${active.length})'),
              ...active.map((c) => _CodeTile(code: c)),
              const SizedBox(height: 8),
            ],
            if (used.isNotEmpty) ...[
              _SectionHeader('Verwendet (${used.length})'),
              ...used.map((c) => _CodeTile(code: c)),
              const SizedBox(height: 8),
            ],
            if (expired.isNotEmpty) ...[
              _SectionHeader('Abgelaufen (${expired.length})'),
              ...expired.map((c) => _CodeTile(code: c)),
            ],
          ],
        );
      },
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.code});
  final TrainerCode code;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    if (code.isUsed) {
      statusColor = AppColors.textSecondary;
      statusLabel = 'Verwendet';
    } else if (code.isExpired) {
      statusColor = AppColors.error;
      statusLabel = 'Abgelaufen';
    } else {
      statusColor = Colors.green;
      statusLabel = 'Aktiv';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          code.code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        subtitle: Text(
          'Erstellt: ${_formatDate(code.createdAt)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Chip(
          label: Text(statusLabel),
          backgroundColor: statusColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: statusColor, fontSize: 12),
        ),
        onTap: code.isActive
            ? () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code kopiert!')),
                );
              }
            : null,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Trainer Review Tab ────────────────────────────────────────────────────────

class _TrainerReviewTab extends ConsumerWidget {
  const _TrainerReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncTrainers = ref.watch(pendingTrainersProvider);

    return asyncTrainers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (trainers) {
        if (trainers.isEmpty) {
          return Center(child: Text(l10n.adminTrainerNoPending));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trainers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _TrainerReviewCard(trainer: trainers[i]),
        );
      },
    );
  }
}

class _TrainerReviewCard extends ConsumerWidget {
  const _TrainerReviewCard({required this.trainer});

  final TrainerProfile trainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(pendingTrainersProvider.notifier);

    Future<void> onApprove() async {
      await notifier.approve(trainer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminTrainerApproveSuccess)),
        );
      }
    }

    Future<void> onSuspend() async {
      await notifier.suspend(trainer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminTrainerSuspendSuccess)),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (trainer.photoUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(trainer.photoUrl!),
                    radius: 24,
                  )
                else
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.displayName,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (trainer.contactEmail != null)
                        Text(trainer.contactEmail!,
                            style: Theme.of(context).textTheme.bodySmall),
                      if (trainer.contactPhone != null)
                        Text(trainer.contactPhone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (trainer.bio != null) ...[
              const SizedBox(height: 8),
              Text(trainer.bio!),
            ],
            const SizedBox(height: 8),
            Text(
              'Eingereicht: ${trainer.submittedAt.toLocal().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: Text(l10n.adminTrainerApprove),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSuspend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(l10n.adminTrainerSuspend),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
