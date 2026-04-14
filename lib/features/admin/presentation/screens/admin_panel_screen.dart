import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Trainer-Codes'),
              Tab(text: 'Premium'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TrainerCodesTab(),
            _PremiumTab(),
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
        child: Text('Fehler: $e',
            style: TextStyle(color: AppColors.error)),
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
        final practitioners = users
            .where((u) => u.role == 'practitioner')
            .toList();
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
          style: TextStyle(color: AppColors.textSecondary),
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
