import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';
import '../../domain/services/calendar_service.dart';
import '../providers/trainer_provider.dart';

const _uuid = Uuid();

class AppointmentSchedulerScreen extends ConsumerStatefulWidget {
  final TrainerClient client;
  const AppointmentSchedulerScreen({super.key, required this.client});

  @override
  ConsumerState<AppointmentSchedulerScreen> createState() =>
      _AppointmentSchedulerScreenState();
}

class _AppointmentSchedulerScreenState
    extends ConsumerState<AppointmentSchedulerScreen> {
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _calSvc = CalendarService.instance;

  List<TimeSlot>? _freeSlots;
  final Set<TimeSlot> _selectedSlots = {};
  DateTime? _customTime;
  bool _loadingSlots = true;
  bool _sending = false;
  bool _sent = false;

  String? _selectedCalendarId;
  bool _calendarDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _selectedCalendarId = await _calSvc.getSelectedCalendarId();
    if (_selectedCalendarId == null && !_calendarDialogShown) {
      _calendarDialogShown = true;
      await _showCalendarPicker();
    }
    await _loadSlots();
  }

  Future<void> _showCalendarPicker() async {
    final cals = await _calSvc.getAvailableCalendars();
    if (!mounted) return;
    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).appointmentNoCalendars)),
      );
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CalendarPickerDialog(
        calendars: cals,
        onSelected: (id) async {
          await _calSvc.setSelectedCalendarId(id);
          setState(() => _selectedCalendarId = id);
        },
      ),
    );
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final now = DateTime.now();
      final slots = await _calSvc.findFreeSlots(
        from: now,
        until: now.add(const Duration(days: 14)),
      );
      if (mounted) setState(() => _freeSlots = slots);
    } catch (e) {
      appLogger.e('Error loading free slots', error: e);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    final custom = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _customTime = custom;
      // Add as a virtual slot
      _selectedSlots.add(TimeSlot(start: custom, end: custom.add(const Duration(hours: 1))));
    });
  }

  List<DateTime> get _allSelectedDateTimes {
    final times = _selectedSlots.map((s) => s.start).toList();
    return times;
  }

  Future<void> _propose() async {
    final slots = _allSelectedDateTimes;
    if (slots.isEmpty) return;
    if (_selectedCalendarId == null) {
      await _showCalendarPicker();
      if (_selectedCalendarId == null) return;
    }

    setState(() => _sending = true);
    try {
      final trainerId = Supabase.instance.client.auth.currentUser!.id;
      const title = 'Isometrische Partnerübung';

      final appointment = Appointment(
        id: _uuid.v4(),
        trainerId: trainerId,
        traineeId: widget.client.clientId,
        traineeName: widget.client.displayName,
        title: title,
        scheduledFor: null,
        proposedSlots: slots,
        durationMinutes: 60,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: 'proposed',
        trigger: 'manual',
        traineeDayNumber: widget.client.currentDay,
        createdAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from('appointments')
          .insert(appointment.toJson());

      ref.invalidate(appointmentsProvider);

      if (mounted) setState(() => _sent = true);
    } catch (e) {
      appLogger.e('Error proposing appointment', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_sent) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appointmentSchedulerTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  '${_selectedSlots.length} Terminvorschlag${_selectedSlots.length > 1 ? "schläge" : ""} an ${widget.client.displayName} gesendet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dein Klient wählt einen passenden Slot aus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appointmentSchedulerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Text(
            l10n.appointmentWith(widget.client.displayName),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Wähle 2–4 freie Slots aus — dein Klient sucht sich einen aus.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Selection summary ─────────────────────────────────────────────
          if (_selectedSlots.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedSlots.length} Slot${_selectedSlots.length > 1 ? "s" : ""} ausgewählt',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedSlots.clear()),
                    child: Text(
                      'Zurücksetzen',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Free slots ───────────────────────────────────────────────────
          Text(
            l10n.appointmentFreeSlotsTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_loadingSlots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(l10n.appointmentLoadingSlots,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else if (_freeSlots == null || _freeSlots!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.appointmentNoFreeSlots,
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            _SlotGrid(
              slots: _freeSlots!.take(24).toList(),
              selectedSlots: _selectedSlots,
              onTap: (slot) => setState(() {
                if (_selectedSlots.contains(slot)) {
                  _selectedSlots.remove(slot);
                } else {
                  _selectedSlots.add(slot);
                }
              }),
            ),

          const SizedBox(height: 4),

          // ── Custom time ──────────────────────────────────────────────────
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.appointmentOtherTime),
            onPressed: _pickCustomTime,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),

          const Divider(height: 28),

          // ── Location + notes ──────────────────────────────────────────────
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              labelText: l10n.appointmentLocationLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.appointmentNotesLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // ── Propose button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedSlots.isEmpty || _sending ? null : _propose,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _selectedSlots.isEmpty
                    ? 'Slots auswählen'
                    : 'Vorschlag senden (${_selectedSlots.length})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Multi-select slot grid ────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final Set<TimeSlot> selectedSlots;
  final ValueChanged<TimeSlot> onTap;

  const _SlotGrid({
    required this.slots,
    required this.selectedSlots,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TimeSlot>> byDay = {};
    for (final slot in slots) {
      final key = DateFormat('yyyy-MM-dd').format(slot.start);
      byDay.putIfAbsent(key, () => []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byDay.entries.map((entry) {
        final daySlots = entry.value;
        final dayLabel = DateFormat('EEE, d. MMM', 'de_DE').format(daySlots.first.start);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daySlots.map((slot) {
                  final selected = selectedSlots.contains(slot);
                  final timeStr = DateFormat('HH:mm').format(slot.start);
                  return GestureDetector(
                    onTap: () => onTap(slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Calendar picker dialog ────────────────────────────────────────────────────

class _CalendarPickerDialog extends StatefulWidget {
  final List<AppCalendar> calendars;
  final Future<void> Function(String id) onSelected;

  const _CalendarPickerDialog({
    required this.calendars,
    required this.onSelected,
  });

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.appointmentSelectCalendarTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appointmentSelectCalendarSubtitle,
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ...widget.calendars.map((cal) => RadioListTile<String>(
                  value: cal.id,
                  groupValue: _selected,
                  title: Text(cal.name),
                  onChanged: (v) => setState(() => _selected = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _selected == null
              ? null
              : () async {
                  await widget.onSelected(_selected!);
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
