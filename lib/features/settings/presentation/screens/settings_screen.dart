import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../bootstrap/providers.dart';
import '../widgets/theme_selector.dart';
import '../../../../core/reminders/reminder_settings.dart';
import '../../../../core/reminders/reminder_profile_settings.dart';
import '../../../../core/training/handsfree_setup_settings.dart';
import '../../../../core/mood/mood_view_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../core/training/training_launch_settings.dart';
import '../../../../core/training/tutorial_flow_settings.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../training/presentation/services/training_feedback_service.dart';
import '../../../training/presentation/providers/training_flow_provider.dart';
import '../../../../core/services/notification_service.dart';

/// Settings Screen
///
/// Zentrale Einstellungs-Seite der App mit verschiedenen Konfigurations-Optionen.
/// Aktuell: Theme-Auswahl
/// Zukünftig: Benachrichtigungen, Sprache, etc.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeletingAccount = false;
  bool _isHealthLoading = false;
  bool _remindersEnabled = true;
  bool _reminderScheduled = false;
  int _pendingSyncJobs = 0;
  DateTime? _oldestSyncJobAt;
  TrainingFeedbackMode _feedbackMode = TrainingFeedbackMode.voiceAndCues;
  TrainingVoicePreset _voicePreset = TrainingVoicePreset.calm;
  ReminderCadence _reminderCadence = ReminderCadence.minimal;
  SharedPreferences? _prefs;
  final TrainingFeedbackService _feedbackPreview = TrainingFeedbackService();
  final FlutterTts _voiceProbe = FlutterTts();
  bool _isTestingFeedback = false;
  bool _tutorialCompact = false;
  MoodViewScope _moodViewScope = MoodViewScope.package;
  MoodViewRangePreset _moodViewRange = MoodViewRangePreset.days30;
  List<_VoiceOption> _voiceOptions = const [];
  String? _selectedVoiceId;
  bool _isLoadingVoices = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadHealthPanel();
  }

  @override
  void dispose() {
    _voiceProbe.stop();
    _feedbackPreview.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _remindersEnabled = ReminderSettings.dailyRemindersEnabled(prefs);
      _feedbackMode = TrainingFeedbackSettings.feedbackMode(prefs);
      _voicePreset = TrainingFeedbackSettings.voicePreset(prefs);
      final selection = TrainingFeedbackSettings.voiceSelectionOrNull(prefs);
      _selectedVoiceId = selection == null
          ? null
          : _VoiceOption.idFor(selection.name, selection.locale);
      _reminderCadence = ReminderProfileSettings.cadence(prefs);
      _tutorialCompact = TutorialFlowSettings.compactEnabled(prefs);
      _moodViewScope = MoodViewSettings.scope(prefs);
      _moodViewRange = MoodViewSettings.range(prefs);
    });
    await _loadVoiceOptions();
  }

  Future<void> _toggleReminders(bool value) async {
    final previousValue = _remindersEnabled;
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    final messenger = ScaffoldMessenger.of(context);
    final notifications = NotificationService();

    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _remindersEnabled = value;
    });

    try {
      if (value) {
        final granted = await notifications.requestPermissions();
        if (!granted) {
          await ReminderSettings.setDailyRemindersEnabled(prefs, false);
          if (!mounted) return;
          setState(() {
            _remindersEnabled = false;
          });
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Benachrichtigungen sind deaktiviert. Bitte erlaube sie in den Systemeinstellungen.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await ReminderSettings.setDailyRemindersEnabled(prefs, true);
        await ref.read(progressServiceProvider).syncReminderSchedule();
        await _loadHealthPanel();
        messenger.showSnackBar(
          const SnackBar(content: Text('Erinnerungen aktiviert.')),
        );
      } else {
        await ReminderSettings.setDailyRemindersEnabled(prefs, false);
        await ref.read(progressServiceProvider).syncReminderSchedule();
        await _loadHealthPanel();
        messenger.showSnackBar(
          const SnackBar(content: Text('Erinnerungen deaktiviert.')),
        );
      }
    } catch (e) {
      await ReminderSettings.setDailyRemindersEnabled(prefs, previousValue);
      if (!mounted) return;
      setState(() {
        _remindersEnabled = previousValue;
      });
      _showErrorSnackBar('Einstellung konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _setFeedbackMode(TrainingFeedbackMode mode) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _feedbackMode;
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _feedbackMode = mode;
    });
    try {
      await TrainingFeedbackSettings.setFeedbackMode(prefs, mode);
    } catch (e) {
      await TrainingFeedbackSettings.setFeedbackMode(prefs, previous);
      if (!mounted) return;
      setState(() => _feedbackMode = previous);
      _showErrorSnackBar(
          'Training-Feedback konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _setVoicePreset(TrainingVoicePreset preset) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _voicePreset;
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _voicePreset = preset;
    });
    try {
      await TrainingFeedbackSettings.setVoicePreset(prefs, preset);
      await _feedbackPreview.refreshConfiguration();
    } catch (e) {
      await TrainingFeedbackSettings.setVoicePreset(prefs, previous);
      if (!mounted) return;
      setState(() => _voicePreset = previous);
      _showErrorSnackBar('Stimmprofil konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _loadVoiceOptions() async {
    setState(() => _isLoadingVoices = true);
    try {
      await _voiceProbe.setLanguage('de-DE');
      final rawVoices = await _voiceProbe.getVoices;
      final voices = <_VoiceOption>[];
      final seen = <String>{};
      for (final item in rawVoices) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final name = (map['name'] ?? '').toString();
        final locale = (map['locale'] ?? '').toString();
        final identifier = (map['identifier'] ?? '').toString();
        final qualityRaw = map['quality'];
        final quality = qualityRaw is num ? qualityRaw.toInt() : 0;
        if (name.isEmpty) continue;
        if (!locale.toLowerCase().startsWith('de')) continue;
        final voice = _VoiceOption(
          name: name,
          locale: locale,
          quality: quality,
          identifier: identifier.isEmpty ? null : identifier,
        );
        if (seen.add(voice.id)) {
          voices.add(voice);
        }
      }
      voices.sort((a, b) {
        final qualityOrder = b.sortScore.compareTo(a.sortScore);
        if (qualityOrder != 0) return qualityOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _voiceOptions = voices;
        if (_selectedVoiceId != null &&
            !_voiceOptions.any((v) => v.id == _selectedVoiceId)) {
          final selectedName = _VoiceOption.nameFromId(_selectedVoiceId!);
          _selectedVoiceId = _voiceOptions
              .cast<_VoiceOption?>()
              .firstWhere(
                (v) => v != null && v.name == selectedName,
                orElse: () => null,
              )
              ?.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceOptions = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingVoices = false);
      }
    }
  }

  Future<void> _setVoiceSelection(String? voiceId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _selectedVoiceId;
    setState(() {
      _prefs = prefs;
      _selectedVoiceId = voiceId;
    });
    try {
      final selectedOption = _voiceOptions
          .cast<_VoiceOption?>()
          .firstWhere((v) => v != null && v.id == voiceId, orElse: () => null);
      final selection = selectedOption == null
          ? null
          : TrainingVoiceSelection(
              name: selectedOption.name,
              locale: selectedOption.locale,
            );
      await TrainingFeedbackSettings.setVoiceSelection(prefs, selection);
      await _feedbackPreview.refreshConfiguration();
    } catch (e) {
      final previousOption = _voiceOptions.cast<_VoiceOption?>().firstWhere(
            (v) => v != null && v.id == previous,
            orElse: () => null,
          );
      await TrainingFeedbackSettings.setVoiceSelection(
        prefs,
        previousOption == null
            ? null
            : TrainingVoiceSelection(
                name: previousOption.name,
                locale: previousOption.locale,
              ),
      );
      if (!mounted) return;
      setState(() => _selectedVoiceId = previous);
      _showErrorSnackBar('Stimme konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _setReminderCadence(ReminderCadence cadence) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _reminderCadence;
    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      _reminderCadence = cadence;
    });

    try {
      await ReminderProfileSettings.setCadence(prefs, cadence);
      await ref.read(progressServiceProvider).syncReminderSchedule();
      await _loadHealthPanel();
    } catch (e) {
      await ReminderProfileSettings.setCadence(prefs, previous);
      if (!mounted) return;
      setState(() => _reminderCadence = previous);
      _showErrorSnackBar(
          'Reminder-Intensität konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _testFeedback() async {
    if (_isTestingFeedback) return;
    setState(() => _isTestingFeedback = true);
    try {
      await _feedbackPreview.previewFeedbackMode(_feedbackMode);
      if (!mounted) return;
      if (_feedbackMode == TrainingFeedbackMode.silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Stumm-Modus aktiv: nur kurzer haptischer Test ausgeführt.'),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Feedback-Test fehlgeschlagen: $e');
    } finally {
      if (mounted) {
        setState(() => _isTestingFeedback = false);
      }
    }
  }

  Future<void> _setTutorialCompact(bool value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _tutorialCompact;
    setState(() {
      _prefs = prefs;
      _tutorialCompact = value;
    });
    try {
      await TutorialFlowSettings.setCompactEnabled(prefs, value);
    } catch (e) {
      await TutorialFlowSettings.setCompactEnabled(prefs, previous);
      if (!mounted) return;
      setState(() => _tutorialCompact = previous);
      _showErrorSnackBar('Tutorial-Option konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _setMoodViewScope(MoodViewScope value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _moodViewScope;
    setState(() {
      _prefs = prefs;
      _moodViewScope = value;
    });
    try {
      await MoodViewSettings.setScope(prefs, value);
    } catch (e) {
      await MoodViewSettings.setScope(prefs, previous);
      if (!mounted) return;
      setState(() => _moodViewScope = previous);
      _showErrorSnackBar('Mood-Ansicht konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _setMoodViewRange(MoodViewRangePreset value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final previous = _moodViewRange;
    setState(() {
      _prefs = prefs;
      _moodViewRange = value;
    });
    try {
      await MoodViewSettings.setRange(prefs, value);
    } catch (e) {
      await MoodViewSettings.setRange(prefs, previous);
      if (!mounted) return;
      setState(() => _moodViewRange = previous);
      _showErrorSnackBar('Mood-Zeitraum konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _reconfigureHandsfreeSetup() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final currentDirectStart =
        TrainingLaunchSettings.directStartEnabledOrNull(prefs) ?? true;
    var mode =
        currentDirectStart ? TrainingMode.routine : TrainingMode.tutorial;
    var feedbackMode = _feedbackMode;
    var tempoSeconds =
        HandsfreeSetupSettings.defaultTempoSecondsOrNull(prefs) ?? 2.5;

    final result = await showModalBottomSheet<_HandsfreeSetupResult>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hands-free Setup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TrainingMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TrainingMode.routine,
                          icon: Icon(Icons.bolt_outlined),
                          label: Text('Direkt starten'),
                        ),
                        ButtonSegment(
                          value: TrainingMode.tutorial,
                          icon: Icon(Icons.school_outlined),
                          label: Text('Tutorial'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        setModalState(() => mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TrainingFeedbackMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TrainingFeedbackMode.voiceAndCues,
                          label: Text('Stimme'),
                        ),
                        ButtonSegment(
                          value: TrainingFeedbackMode.hapticOnly,
                          label: Text('Haptik'),
                        ),
                        ButtonSegment(
                          value: TrainingFeedbackMode.silent,
                          label: Text('Stumm'),
                        ),
                      ],
                      selected: {feedbackMode},
                      onSelectionChanged: (selection) {
                        setModalState(() => feedbackMode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Starttempo: ${tempoSeconds.toStringAsFixed(tempoSeconds.truncateToDouble() == tempoSeconds ? 0 : 1)}s',
                    ),
                    Slider(
                      min: 1.0,
                      max: 5.0,
                      divisions: 8,
                      value: tempoSeconds,
                      onChanged: (v) {
                        setModalState(() => tempoSeconds = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _HandsfreeSetupResult(
                              mode: mode,
                              feedbackMode: feedbackMode,
                              defaultTempoSeconds: tempoSeconds,
                            ),
                          );
                        },
                        child: const Text('Setup speichern'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    await TrainingLaunchSettings.setDirectStartEnabled(
      prefs,
      result.mode == TrainingMode.routine,
    );
    await TrainingFeedbackSettings.setFeedbackMode(prefs, result.feedbackMode);
    await HandsfreeSetupSettings.setDefaultTempoSeconds(
      prefs,
      result.defaultTempoSeconds,
    );
    await HandsfreeSetupSettings.setCompleted(prefs, true);

    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _feedbackMode = result.feedbackMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hands-free Setup aktualisiert.')),
    );
  }

  Future<void> _loadHealthPanel() async {
    setState(() => _isHealthLoading = true);
    try {
      final sync = ref.read(syncServiceProvider);
      final stats = await sync.getQueueStats();
      final scheduled = await NotificationService().hasScheduledDailyReminder();
      if (!mounted) return;
      setState(() {
        _pendingSyncJobs = stats.pendingJobs;
        _oldestSyncJobAt = stats.oldestJobAt;
        _reminderScheduled = scheduled;
        _isHealthLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isHealthLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final email = user?.email;

    if (email == null) {
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Kein E-Mail-Konto gefunden. Bitte melde dich erneut an.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Link zum Zurücksetzen wurde an $email gesendet.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text('Fehler beim Senden der E-Mail: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unbekannter Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account löschen'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden. '
          'Alle lokal gespeicherten Fortschritte werden entfernt und dein Zugang wird deaktiviert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);
    final messenger = ScaffoldMessenger.of(context);
    final auth = FirebaseAuth.instance;

    final user = auth.currentUser;
    if (user == null) {
      setState(() => _isDeletingAccount = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kein aktives Konto gefunden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await user.delete();
      await auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account wurde gelöscht.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // dismiss progress
      String message = e.message ?? e.code;
      if (e.code == 'requires-recent-login') {
        message = 'Bitte melde dich erneut an und versuche es dann erneut.';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Account konnte nicht gelöscht werden: $message'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // dismiss progress
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unbekannter Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Darstellung Section
          Text(
            'Darstellung',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          const ThemeSelector(),

          const SizedBox(height: 24),

          // Platzhalter für zukünftige Sections
          Text(
            'Benachrichtigungen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Push-Benachrichtigungen'),
              trailing: Switch(
                value: _remindersEnabled,
                onChanged: (value) => _toggleReminders(value),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Reminder Intensität'),
                  subtitle:
                      Text('Steuert Häufigkeit und Abstand der Erinnerungen'),
                ),
                RadioListTile<ReminderCadence>(
                  title: const Text('Minimal (empfohlen)'),
                  subtitle: const Text('Vorsichtiger, anti-spam orientiert'),
                  value: ReminderCadence.minimal,
                  groupValue: _reminderCadence,
                  onChanged: (value) {
                    if (value != null) {
                      _setReminderCadence(value);
                    }
                  },
                ),
                RadioListTile<ReminderCadence>(
                  title: const Text('Ausgewogen'),
                  subtitle:
                      const Text('Etwas reaktiver innerhalb des Zeitfensters'),
                  value: ReminderCadence.balanced,
                  groupValue: _reminderCadence,
                  onChanged: (value) {
                    if (value != null) {
                      _setReminderCadence(value);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Systemstatus'),
              subtitle: Text(
                _isHealthLoading
                    ? 'Status wird geladen...'
                    : 'Reminder geplant: ${_reminderScheduled ? "Ja" : "Nein"}\n'
                        'Pending Sync Jobs: $_pendingSyncJobs'
                        '${_oldestSyncJobAt == null ? "" : "\nÄltester Job: ${_oldestSyncJobAt!.toIso8601String()}"}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isHealthLoading ? null : _loadHealthPanel,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.hearing_outlined),
                  title: Text('Training Feedback'),
                  subtitle: Text(
                    'Steuert Audio/Haptik im Tutorial- und Routine-Modus',
                  ),
                ),
                RadioListTile<TrainingFeedbackMode>(
                  title: const Text('Ton aus'),
                  value: TrainingFeedbackMode.silent,
                  groupValue: _feedbackMode,
                  onChanged: (value) {
                    if (value != null) {
                      _setFeedbackMode(value);
                    }
                  },
                ),
                RadioListTile<TrainingFeedbackMode>(
                  title: const Text('Nur Haptik'),
                  value: TrainingFeedbackMode.hapticOnly,
                  groupValue: _feedbackMode,
                  onChanged: (value) {
                    if (value != null) {
                      _setFeedbackMode(value);
                    }
                  },
                ),
                RadioListTile<TrainingFeedbackMode>(
                  title: const Text('Sprache + Cues + Haptik'),
                  value: TrainingFeedbackMode.voiceAndCues,
                  groupValue: _feedbackMode,
                  onChanged: (value) {
                    if (value != null) {
                      _setFeedbackMode(value);
                    }
                  },
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<TrainingVoicePreset>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TrainingVoicePreset.calm,
                        label: Text('Sanft'),
                      ),
                      ButtonSegment(
                        value: TrainingVoicePreset.neutral,
                        label: Text('Neutral'),
                      ),
                      ButtonSegment(
                        value: TrainingVoicePreset.dynamic,
                        label: Text('Dynamisch'),
                      ),
                    ],
                    selected: {_voicePreset},
                    onSelectionChanged: (selection) {
                      _setVoicePreset(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoadingVoices
                      ? const LinearProgressIndicator(minHeight: 2)
                      : DropdownButtonFormField<String?>(
                          value: _selectedVoiceId,
                          decoration: const InputDecoration(
                            labelText: 'Stimme (deutsch)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Standardstimme (System)'),
                            ),
                            ..._voiceOptions.map(
                              (voice) => DropdownMenuItem<String?>(
                                value: voice.id,
                                child: Text(voice.label),
                              ),
                            ),
                          ],
                          onChanged: _voiceOptions.isEmpty
                              ? null
                              : (value) {
                                  _setVoiceSelection(value);
                                },
                        ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isTestingFeedback ? null : _testFeedback,
                      icon: _isTestingFeedback
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.volume_up_outlined),
                      label: Text(
                        _isTestingFeedback
                            ? 'Teste Feedback...'
                            : 'Stimme testen',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Training',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Hands-free Setup neu konfigurieren'),
              subtitle: const Text(
                'Startmodus, Feedback und Starttempo anpassen',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _reconfigureHandsfreeSetup,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fast_forward_outlined),
              title: const Text('Tutorial kompakt'),
              subtitle: const Text(
                'Überspringt Positionsscreen und startet direkt mit Bewegungsanleitung.',
              ),
              value: _tutorialCompact,
              onChanged: _setTutorialCompact,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.insights_outlined),
                  title: Text('Befindensverlauf'),
                  subtitle: Text(
                    'Anzeige von Scope und Zeitraum im Dashboard festlegen',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<MoodViewScope>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: MoodViewScope.package,
                        label: Text('Paket'),
                      ),
                      ButtonSegment(
                        value: MoodViewScope.overall,
                        label: Text('Gesamt'),
                      ),
                    ],
                    selected: {_moodViewScope},
                    onSelectionChanged: (selection) {
                      _setMoodViewScope(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<MoodViewRangePreset>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: MoodViewRangePreset.days30,
                        label: Text('30T'),
                      ),
                      ButtonSegment(
                        value: MoodViewRangePreset.days90,
                        label: Text('90T'),
                      ),
                      ButtonSegment(
                        value: MoodViewRangePreset.year1,
                        label: Text('1J'),
                      ),
                      ButtonSegment(
                        value: MoodViewRangePreset.all,
                        label: Text('Alle'),
                      ),
                    ],
                    selected: {_moodViewRange},
                    onSelectionChanged: (selection) {
                      _setMoodViewRange(selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Aktionen Section
          Text(
            'Aktionen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Passwort ändern'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handlePasswordReset,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Account löschen',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleDeleteAccount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weitere Sections können hier hinzugefügt werden
          Text(
            'Allgemein',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Sprache'),
                  subtitle: const Text('Deutsch'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement language selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sprachauswahl kommt bald!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Über CoreJourney'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement about screen
                    showAboutDialog(
                      context: context,
                      applicationName: 'CoreJourney',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2024 CoreJourney',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandsfreeSetupResult {
  final TrainingMode mode;
  final TrainingFeedbackMode feedbackMode;
  final double defaultTempoSeconds;

  const _HandsfreeSetupResult({
    required this.mode,
    required this.feedbackMode,
    required this.defaultTempoSeconds,
  });
}

class _VoiceOption {
  final String name;
  final String locale;
  final int quality;
  final String? identifier;

  const _VoiceOption({
    required this.name,
    required this.locale,
    this.quality = 0,
    this.identifier,
  });

  String get id => idFor(name, locale);
  String get label => '$name ($locale)';
  int get sortScore {
    var score = quality;
    final blob = '${name.toLowerCase()} ${(identifier ?? '').toLowerCase()}';
    if (blob.contains('premium')) score += 1000;
    if (blob.contains('enhanced')) score += 700;
    if (blob.contains('siri')) score += 500;
    if (blob.contains('compact')) score -= 500;
    if (blob.contains('eddie') || blob.contains('eddy')) score -= 1500;
    return score;
  }

  static String idFor(String name, String? locale) => '$name|${locale ?? ''}';

  static String nameFromId(String id) {
    final separatorIndex = id.indexOf('|');
    if (separatorIndex < 0) return id;
    return id.substring(0, separatorIndex);
  }
}
