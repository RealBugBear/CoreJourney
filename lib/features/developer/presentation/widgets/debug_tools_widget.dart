import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/app_config.dart';
import '../../../../bootstrap/providers.dart';

/// Developer-only debug tools for manipulating test data
/// Only available in development and staging builds
class DebugToolsWidget extends ConsumerStatefulWidget {
  const DebugToolsWidget({super.key});

  @override
  ConsumerState<DebugToolsWidget> createState() => _DebugToolsWidgetState();
}

class _DebugToolsWidgetState extends ConsumerState<DebugToolsWidget> {
  int? _selectedDay;
  bool _isLoading = false;
  String? _message;
  int _pendingSyncJobs = 0;
  int _pendingCreateJobs = 0;
  int _pendingUpdateJobs = 0;
  int _pendingDeleteJobs = 0;
  DateTime? _oldestSyncJobAt;

  @override
  void initState() {
    super.initState();
    _loadLocalDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    // Only show in dev/staging
    if (AppConfig.current.environment == 'production') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'DEBUG TOOLS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const Divider(),
          _SyncDiagnosticsCard(
            pendingJobs: _pendingSyncJobs,
            createJobs: _pendingCreateJobs,
            updateJobs: _pendingUpdateJobs,
            deleteJobs: _pendingDeleteJobs,
            oldestJobAt: _oldestSyncJobAt,
            isLoading: _isLoading,
            onRefresh: _isLoading ? null : _loadLocalDiagnostics,
            onForceSync: _isLoading ? null : _forceSyncNow,
            onClearQueue: _isLoading ? null : _clearPendingSyncJobs,
          ),
          const SizedBox(height: 12),
          if (_message != null) ...[
            Text(
              _message!,
              style: TextStyle(
                color: _message!.contains('Error') ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text('Quick Actions:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Reset All Progress',
                icon: Icons.restart_alt,
                color: Colors.red,
                onPressed: _isLoading ? null : _resetAllProgress,
              ),
              _ActionButton(
                label: 'Jump to Day 7',
                icon: Icons.fast_forward,
                color: Colors.blue,
                onPressed: _isLoading ? null : () => _jumpToDay(7),
              ),
              _ActionButton(
                label: 'Jump to Day 14',
                icon: Icons.fast_forward,
                color: Colors.blue,
                onPressed: _isLoading ? null : () => _jumpToDay(14),
              ),
              _ActionButton(
                label: 'Jump to Day 27',
                icon: Icons.fast_forward,
                color: Colors.purple,
                onPressed: _isLoading ? null : () => _jumpToDay(27),
              ),
              _ActionButton(
                label: 'Trigger Golden Day',
                icon: Icons.star,
                color: Colors.amber,
                onPressed: _isLoading ? null : () => _jumpToDay(28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Manual Day Selection:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  value: _selectedDay,
                  hint: const Text('Select day'),
                  isExpanded: true,
                  items: List.generate(29, (index) => index)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(
                                'Day $day${day == 28 ? ' (Golden Day)' : ''}'),
                          ))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedDay = value);
                        },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading || _selectedDay == null
                    ? null
                    : () => _jumpToDay(_selectedDay!),
                child: const Text('Set'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Other Actions:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Mark Today Complete',
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: _isLoading ? null : _markTodayComplete,
              ),
              _ActionButton(
                label: 'Complete Questionnaire',
                icon: Icons.question_answer,
                color: Colors.indigo,
                onPressed: _isLoading ? null : _completeQuestionnaire,
              ),
              _ActionButton(
                label: 'View Firestore',
                icon: Icons.cloud,
                color: Colors.teal,
                onPressed: _openFirestoreConsole,
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _resetAllProgress() async {
    final confirmed = await _showConfirmDialog(
      'Reset all progress? This cannot be undone!',
    );
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final firestore = FirebaseFirestore.instance;

      // Delete all progress documents
      final progressDocs = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .get();

      final batch = firestore.batch();
      for (final doc in progressDocs.docs) {
        batch.delete(doc.reference);
      }

      // Reset user summary
      batch.update(
        firestore.collection('users').doc(user.uid),
        {
          'totalDaysCompleted': 0,
          'currentDay': 0,
          'completedDays': [],
          'lastTrainingAt': FieldValue.delete(),
        },
      );

      await batch.commit();

      setState(() {
        _message = '✓ Progress reset!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalDiagnostics() async {
    try {
      final sync = ref.read(syncServiceProvider);
      final stats = await sync.getQueueStats();

      if (!mounted) return;
      setState(() {
        _pendingSyncJobs = stats.pendingJobs;
        _pendingCreateJobs = stats.createJobs;
        _pendingUpdateJobs = stats.updateJobs;
        _pendingDeleteJobs = stats.deleteJobs;
        _oldestSyncJobAt = stats.oldestJobAt;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Error loading diagnostics: $e';
      });
    }
  }

  Future<void> _forceSyncNow() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final sync = ref.read(syncServiceProvider);
      await sync.syncPendingJobs();
      await _loadLocalDiagnostics();
      if (!mounted) return;
      setState(() {
        _message = '✓ Sync manuell ausgelöst';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPendingSyncJobs() async {
    final confirmed = await _showConfirmDialog(
      'Alle ausstehenden Sync-Jobs lokal löschen?',
    );
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final sync = ref.read(syncServiceProvider);
      await sync.clearPendingJobs();
      await _loadLocalDiagnostics();
      if (!mounted) return;
      setState(() {
        _message = '✓ Pending Sync Queue geleert';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _jumpToDay(int targetDay) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Generate completed days list (0 to targetDay-1)
      final completedDays = List.generate(targetDay, (i) => i);

      // Create progress docs for each completed day
      for (int day = 0; day < targetDay; day++) {
        final progressRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('progress')
            .doc('day_$day');

        batch.set(progressRef, {
          'day': day,
          'completed': true,
          'completedAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: targetDay - day - 1)),
          ),
          'exercises': {
            'position': {'completed': true},
            'movement': {'completed': true},
            'exercise': {'completed': true},
          },
        });
      }

      // Update user summary
      batch.update(
        firestore.collection('users').doc(user.uid),
        {
          'totalDaysCompleted': targetDay,
          'currentDay': targetDay,
          'completedDays': completedDays,
          'lastTrainingAt': Timestamp.now(),
        },
      );

      await batch.commit();

      setState(() {
        _message = targetDay == 28
            ? '✨ Golden Day activated! (28/28)'
            : '✓ Jumped to Day $targetDay ($targetDay/28)';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markTodayComplete() async {
    // Implementation depends on your current day tracking logic
    setState(() {
      _message = 'Feature coming soon...';
    });
  }

  Future<void> _completeQuestionnaire() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'questionnaireCompleted': true,
        'questionnaireCompletedAt': Timestamp.now(),
      });

      setState(() {
        _message = '✓ Questionnaire marked as completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _openFirestoreConsole() {
    final user = FirebaseAuth.instance.currentUser;
    final projectId = AppConfig.current.environment == 'production'
        ? 'YOUR_PROD_PROJECT_ID'
        : 'YOUR_DEV_PROJECT_ID';

    setState(() {
      _message =
          'Open: https://console.firebase.google.com/project/$projectId/firestore';
      _message = '$_message\nUser UID: ${user?.uid ?? "not logged in"}';
    });
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _SyncDiagnosticsCard extends StatelessWidget {
  final int pendingJobs;
  final int createJobs;
  final int updateJobs;
  final int deleteJobs;
  final DateTime? oldestJobAt;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onForceSync;
  final VoidCallback? onClearQueue;

  const _SyncDiagnosticsCard({
    required this.pendingJobs,
    required this.createJobs,
    required this.updateJobs,
    required this.deleteJobs,
    required this.oldestJobAt,
    required this.isLoading,
    required this.onRefresh,
    required this.onForceSync,
    required this.onClearQueue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local Sync Diagnostics',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Pending: $pendingJobs'),
          Text('create/update/delete: $createJobs / $updateJobs / $deleteJobs'),
          Text(
            oldestJobAt == null
                ? 'oldest: -'
                : 'oldest: ${oldestJobAt!.toIso8601String()}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Refresh Queue',
                icon: Icons.refresh,
                color: Colors.blueGrey,
                onPressed: isLoading ? null : onRefresh,
              ),
              _ActionButton(
                label: 'Force Sync Now',
                icon: Icons.sync,
                color: Colors.green,
                onPressed: isLoading ? null : onForceSync,
              ),
              _ActionButton(
                label: 'Clear Queue',
                icon: Icons.delete_sweep,
                color: Colors.red,
                onPressed: isLoading ? null : onClearQueue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
