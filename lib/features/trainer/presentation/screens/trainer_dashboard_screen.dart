import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';
import '../providers/trainer_provider.dart';

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() =>
      _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState
    extends ConsumerState<TrainerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainerDashboard),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.trainerTabTrainees),
            Tab(text: l10n.trainerTabCalendar),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(trainerClientsProvider);
              ref.invalidate(appointmentsProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TraineesTab(tabController: _tabController),
          const _AppointmentsTab(),
        ],
      ),
    );
  }
}

// ── Tab 1 — Trainees ─────────────────────────────────────────────────────────

class _TraineesTab extends ConsumerWidget {
  final TabController tabController;
  const _TraineesTab({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final clientsAsync = ref.watch(trainerClientsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(trainerClientsProvider.notifier).refresh(),
      child: ListView(
        children: [
          // ── Invite link section ─────────────────────────────────────────
          _InviteBanner(l10n: l10n, ref: ref),

          // ── Clients ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'TRAINEES',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          clientsAsync.when(
            loading: () =>
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
            error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString()),
                )),
            data: (clients) {
              if (clients.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.trainerNoClients,
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              final appointments = appointmentsAsync.valueOrNull ?? [];
              return Column(
                children: clients
                    .map((c) => _ClientCard(
                          client: c,
                          appointments: appointments,
                          l10n: l10n,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteBanner extends StatefulWidget {
  final AppLocalizations l10n;
  final WidgetRef ref;
  const _InviteBanner({required this.l10n, required this.ref});

  @override
  State<_InviteBanner> createState() => _InviteBannerState();
}

class _InviteBannerState extends State<_InviteBanner> {
  String? _code;
  bool _loading = false;

  String get _formattedCode {
    if (_code == null) return '';
    // Format 6-digit code as "XXX · XXX"
    final c = _code!.padLeft(6, '0');
    return '${c.substring(0, 3)} · ${c.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.trainerMyLink,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (_code != null) ...[
            // Big readable code display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formattedCode,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Einmaliger Code — teile ihn mit deinem Klienten',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Code kopieren'),
                    onPressed: () => _copyCode(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: _loading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Neu'),
                  onPressed: _loading ? null : () => _generate(context),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ],
            ),
          ] else ...[
            // No code yet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_link, size: 18),
                label: Text(_loading ? 'Wird erstellt…' : widget.l10n.trainerGenerateCode),
                onPressed: _loading ? null : () => _generate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final code = await widget.ref
          .read(trainerClientsProvider.notifier)
          .generateInviteCode();
      setState(() { _code = code; _loading = false; });
      if (context.mounted) _copyCode(context);
    } catch (e) {
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  void _copyCode(BuildContext context) {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code $_formattedCode kopiert!')),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final TrainerClient client;
  final List<Appointment> appointments;
  final AppLocalizations l10n;

  const _ClientCard({
    required this.client,
    required this.appointments,
    required this.l10n,
  });

  bool get _needsAppointment {
    final hasUpcoming = appointments.any((a) =>
        a.traineeId == client.clientId &&
        (a.scheduledFor?.isAfter(DateTime.now()) ?? false) &&
        a.status != 'cancelled');
    return !hasUpcoming &&
        (client.currentDay >= 25 || client.currentDay >= 28);
  }

  bool get _isNearCompletion => client.currentDay == 25;
  bool get _isComplete => client.currentDay >= 28;

  @override
  Widget build(BuildContext context) {
    final progress = client.currentDay / 28.0;

    Color badgeColor;
    String? badgeLabel;
    String buttonLabel;

    if (_isComplete) {
      badgeColor = AppColors.success;
      badgeLabel = 'Tag 28 ✓';
      buttonLabel = _needsAppointment ? l10n.trainerAppointmentMissing : l10n.trainerScheduleAppointment;
    } else if (_isNearCompletion) {
      badgeColor = AppColors.warning;
      badgeLabel = 'Tag 25';
      buttonLabel = l10n.trainerBookNow;
    } else {
      badgeColor = AppColors.primary;
      badgeLabel = null;
      buttonLabel = l10n.trainerScheduleAppointment;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  child: Text(
                    client.displayName[0].toUpperCase(),
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            client.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l10n.currentDay(client.currentDay, 28),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(badgeColor),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _needsAppointment
                      ? badgeColor
                      : AppColors.backgroundLight,
                  foregroundColor: _needsAppointment
                      ? AppColors.white
                      : AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => context.push(
                  Routes.appointmentScheduler.replaceFirst(
                      ':clientId', client.clientId),
                  extra: client,
                ),
                child: Text(buttonLabel, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2 — Appointments (Calendar) ─────────────────────────────────────────

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(appointmentsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(e.toString())),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 56, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    l10n.trainerNoAppointments,
                    style:
                        TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(appointmentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: appointments.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) =>
                _AppointmentTile(appointment: appointments[i], l10n: l10n),
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final AppLocalizations l10n;

  const _AppointmentTile({required this.appointment, required this.l10n});

  Color get _statusColor {
    switch (appointment.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'done':
        return AppColors.textDisabled;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (appointment.status) {
      case 'confirmed':
        return l10n.appointmentStatusConfirmed;
      case 'cancelled':
        return l10n.appointmentStatusCancelled;
      case 'done':
        return l10n.appointmentStatusDone;
      default:
        return l10n.appointmentStatusPlanned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledFor != null
        ? DateFormat('E, d. MMM · HH:mm', 'de_DE').format(appointment.scheduledFor!)
        : '–';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _statusColor.withValues(alpha: 0.12),
        child: Icon(Icons.calendar_today_outlined,
            size: 20, color: _statusColor),
      ),
      title: Text(
        appointment.traineeName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 2),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(l10n),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor),
            ),
          ),
        ],
      ),
      trailing: appointment.calendarEventId != null
          ? IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: l10n.appointmentOpenInCalendar,
              onPressed: () => _openInCalendar(appointment),
            )
          : null,
    );
  }

  Future<void> _openInCalendar(Appointment appt) async {
    // iOS deep link directly to the event in Calendar.app
    if (appt.calendarEventId != null) {
      final ts = appt.scheduledFor!.millisecondsSinceEpoch / 1000;
      final uri = Uri.parse('calshow:$ts');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    // Fallback: open Calendar.app
    final uri = Uri.parse('calshow:');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
