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
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
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

          // ── Trainer View (if already trainer) ─────────────────────────────
          _TrainerViewTile(),

          // ── Become trainer (if not yet trainer) ───────────────────────────
          _BecomeTrainerTile(),

          // ── Connect to trainer (for non-trainer users) ────────────────────
          _ConnectTrainerTile(),

          // ── Switch trainer (only when already connected) ──────────────────
          _SwitchTrainerTile(),

          // ── Dev Tools (for @corejourney.dev accounts) ─────────────────────
          if (_isDevAccount) ...[
            _SectionHeader(title: 'Dev Tools'),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('Admin / Debug Tools'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.devTools),
            ),
          ],

          // ── Security ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.password),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profileChangePassword),
            onTap: () => _sendPasswordReset(context, l10n, user?.email),
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

  Future<void> _sendPasswordReset(
    BuildContext context,
    AppLocalizations l10n,
    String? email,
  ) async {
    if (email == null) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileChangePasswordSent)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
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
    final roleAsync = ref.watch(userRoleProvider);
    final isTrainer = roleAsync.valueOrNull == 'trainer';
    if (isTrainer) return const SizedBox.shrink();

    final config = ref.watch(appConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Trainer'),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Trainer werden'),
          subtitle: Text(
            config.isDevelopment && config.trainerCode.isEmpty
                ? 'DEV: direkt aktivieren'
                : 'Code eingeben um Trainer-Rolle zu aktivieren',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showActivationDialog(context, ref, config),
        ),
      ],
    );
  }

  Future<void> _showActivationDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
  ) async {
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
              if (config.isDevelopment && config.trainerCode.isEmpty)
                Text(
                  'DEV-Modus: kein Code erforderlich.',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                )
              else ...[
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final err = await activateTrainerRole(
                  codeCtrl.text,
                  config.trainerCode as String,
                  config.isDevelopment as bool,
                );
                if (err != null) {
                  setDialogState(() => errorMsg = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(userRoleProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Trainer-Rolle aktiviert! '
                            'Bitte App neu starten.')),
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
    final roleAsync = ref.watch(userRoleProvider);
    if (roleAsync.valueOrNull == 'trainer') return const SizedBox.shrink();

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
          trailing: trainerName == null
              ? const Icon(Icons.chevron_right)
              : null,
          onTap: trainerName != null
              ? null
              : () => _showInviteDialog(context, ref, l10n),
        ),
      ],
    );
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
              const Text('Gib den 6-stelligen Code ein, den du von deinem Trainer erhalten hast:'),
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
                  setDialogState(() => errorMsg = 'Bitte 6-stelligen Code eingeben.');
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
    final roleAsync = ref.watch(userRoleProvider);
    if (roleAsync.valueOrNull == 'trainer') return const SizedBox.shrink();

    final trainerAsync = ref.watch(clientTrainerProvider);
    final trainerName = trainerAsync.valueOrNull;
    if (trainerName == null) return const SizedBox.shrink();

    final config = ref.watch(appConfigProvider);

    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      title: const Text('Trainer wechseln'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showCodeGuardDialog(context, ref, config),
    );
  }

  Future<void> _showCodeGuardDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic config,
  ) async {
    final skipCode = config.isDevelopment as bool && (config.trainerCode as String).isEmpty;

    if (skipCode) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DEV: Code-Guard übersprungen'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      if (context.mounted) await _showNewTrainerDialog(context, ref);
      return;
    }

    final codeCtrl = TextEditingController();
    String? errorMsg;

    final passed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Trainer wechseln'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trainer-Wechsel-Code eingeben:'),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Trainer-Wechsel-Code',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final entered = codeCtrl.text.trim().toUpperCase();
                final expected = (config.trainerCode as String).toUpperCase();
                if (entered != expected) {
                  setDialogState(() => errorMsg = 'Ungültiger Code.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();

    if (passed != true || !context.mounted) return;
    await _showNewTrainerDialog(context, ref);
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
              const Text('Gib den 6-stelligen Einladungscode deines neuen Trainers ein:'),
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
                  setDialogState(() => errorMsg = 'Bitte 6-stelligen Code eingeben.');
                  return;
                }
                try {
                  await switchTrainer(code);
                  ref.invalidate(clientTrainerProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trainer erfolgreich gewechselt')),
                    );
                  }
                } catch (_) {
                  setDialogState(() => errorMsg = 'Fehler beim Trainer-Wechsel.');
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

