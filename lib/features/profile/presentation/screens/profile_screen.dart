import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _version = '';

  bool get _isDevAccount {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return email.endsWith('@corejourney.dev');
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted)
        setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        children: [
          // ── Account info ──────────────────────────────────────────────────
          if (user != null) ...[
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  (user.email ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user.email ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // ── Admin Panel (role = admin only) ───────────────────────────────
          _AdminTile(),

          // ── Trainer View (role = trainer only) ────────────────────────────
          _TrainerViewTile(),

          // ── Become trainer (practitioner only) ────────────────────────────
          _BecomeTrainerTile(),

          // ── Connect to trainer (practitioner only) ────────────────────────
          _ConnectTrainerTile(),

          // ── Switch trainer (only when already connected) ──────────────────
          _SwitchTrainerTile(),

          // ── Dev Tools (for @corejourney.dev accounts in dev builds) ───────
          if (_isDevAccount) ...[
            _SectionHeader(title: 'Dev Tools'),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('Debug Tools'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.devTools),
            ),
          ],

          // ── Security ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.password),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profileChangePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.changePassword),
          ),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsAccount),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),

          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.error),
            title: Text(
              l10n.profileDeleteAccount,
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () => _confirmDeleteAccount(context, l10n),
          ),

          // ── App info ──────────────────────────────────────────────────────
          const SizedBox(height: 32),
          if (_version.isNotEmpty)
            Center(
              child: Text(
                l10n.profileVersion(_version),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: Text(l10n.profileDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileDeleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Supabase.instance.client.rpc('delete_user');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileDeleteAccountSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileDeleteAccountError)),
        );
      }
    }
  }
}

// ── Admin tile ────────────────────────────────────────────────────────────────

class _AdminTile extends ConsumerWidget {
  const _AdminTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role != 'admin') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Administration'),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Admin Panel'),
          subtitle: const Text(
            'Trainer-Codes generieren und verwalten',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.adminPanel),
        ),
      ],
    );
  }
}

// ── Trainer View tile ─────────────────────────────────────────────────────────

class _TrainerViewTile extends ConsumerWidget {
  const _TrainerViewTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(userRoleProvider);
    final isTrainer = roleAsync.valueOrNull == 'trainer';
    if (!isTrainer) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.trainerView),
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.trainerDashboard),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.trainerDashboard),
        ),
      ],
    );
  }
}

// ── Become Trainer tile ───────────────────────────────────────────────────────

class _BecomeTrainerTile extends ConsumerWidget {
  const _BecomeTrainerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'trainer' || role == 'admin') return const SizedBox.shrink();

    final isDev = ref.watch(appConfigProvider).isDevelopment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Trainer'),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Trainer werden'),
          subtitle: Text(
            isDev
                ? 'DEV: Code wird serverseitig geprüft'
                : 'Code eingeben um Trainer-Rolle zu aktivieren',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showActivationDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showActivationDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final codeCtrl = TextEditingController();
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Trainer werden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gib deinen Trainer-Aktivierungscode ein:'),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Trainer-Code',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                // Code validation happens server-side in the activate-trainer
                // Edge Function — the secret never leaves Supabase.
                final err = await activateTrainerRole(codeCtrl.text);
                if (err != null) {
                  setDialogState(() => errorMsg = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                // userRoleProvider will refresh automatically via authStateProvider,
                // but we also invalidate explicitly to make the UI update instantly.
                ref.invalidate(userRoleProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trainer-Rolle aktiviert!')),
                  );
                }
              },
              child: const Text('Aktivieren'),
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();
  }
}

// ── Connect to Trainer tile ───────────────────────────────────────────────────

class _ConnectTrainerTile extends ConsumerWidget {
  const _ConnectTrainerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'trainer' || role == 'admin') return const SizedBox.shrink();

    final trainerAsync = ref.watch(clientTrainerProvider);
    final l10n = AppLocalizations.of(context);

    final trainerName = trainerAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Trainer'),
        ListTile(
          leading: Icon(
            trainerName != null ? Icons.link : Icons.link_off,
            color: trainerName != null ? AppColors.success : null,
          ),
          title: Text(trainerName != null
              ? 'Verbunden mit $trainerName'
              : l10n.connectToTrainer),
          subtitle: trainerName == null
              ? const Text('Einladungscode vom Trainer eingeben',
                  style: TextStyle(fontSize: 12))
              : null,
          trailing:
              trainerName == null ? const Icon(Icons.chevron_right) : null,
          onTap: trainerName != null
              ? null
              : () => _showInviteDialog(context, ref, l10n),
        ),
        if (trainerName != null)
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Nachricht an Trainer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openTrainerChat(context),
          ),
      ],
    );
  }

  Future<void> _openTrainerChat(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      // Find active trainer
      final rel = await Supabase.instance.client
          .from('trainer_client_relationships')
          .select('trainer_id')
          .eq('client_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      if (rel == null || !context.mounted) return;
      final trainerId = rel['trainer_id'] as String;

      // Get or create direct channel between trainee and trainer
      final channelId = await Supabase.instance.client.rpc(
        'get_or_create_direct_channel',
        params: {'user_a': userId, 'user_b': trainerId},
      ) as String;

      if (context.mounted) {
        context.push(Routes.dmChannel.replaceFirst(':channelId', channelId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat konnte nicht geöffnet werden: $e')),
        );
      }
    }
  }

  Future<void> _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ctrl = TextEditingController();
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.connectToTrainer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Gib den 6-stelligen Code ein, den du von deinem Trainer erhalten hast:'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: l10n.enterInviteCode,
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                  counterText: '',
                  hintText: '000000',
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = ctrl.text.replaceAll(RegExp(r'\s'), '').trim();
                if (code.length != 6) {
                  setDialogState(
                      () => errorMsg = 'Bitte 6-stelligen Code eingeben.');
                  return;
                }
                try {
                  await acceptInvite(code);
                  ref.invalidate(clientTrainerProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.connectToTrainerSuccess)),
                    );
                  }
                } catch (_) {
                  setDialogState(() => errorMsg = l10n.connectToTrainerError);
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }
}

// ── Switch Trainer tile ───────────────────────────────────────────────────────

class _SwitchTrainerTile extends ConsumerWidget {
  const _SwitchTrainerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'trainer' || role == 'admin') return const SizedBox.shrink();

    final trainerAsync = ref.watch(clientTrainerProvider);
    final trainerName = trainerAsync.valueOrNull;
    if (trainerName == null) return const SizedBox.shrink();

    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      title: const Text('Trainer wechseln'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showNewTrainerDialog(context, ref),
    );
  }

  Future<void> _showNewTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ctrl = TextEditingController();
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Neuen Trainer verbinden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Gib den 6-stelligen Einladungscode deines neuen Trainers ein:'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'Einladungscode',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                  counterText: '',
                  hintText: '000000',
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = ctrl.text.replaceAll(RegExp(r'\s'), '').trim();
                if (code.length != 6) {
                  setDialogState(
                      () => errorMsg = 'Bitte 6-stelligen Code eingeben.');
                  return;
                }
                try {
                  await switchTrainer(code);
                  ref.invalidate(clientTrainerProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Trainer erfolgreich gewechselt')),
                    );
                  }
                } catch (_) {
                  setDialogState(
                      () => errorMsg = 'Fehler beim Trainer-Wechsel.');
                }
              },
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
