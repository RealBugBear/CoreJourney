import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null; // Skip is allowed
    if (trimmed.length < 3) return 'Mindestens 3 Zeichen';
    if (trimmed.length > 30) return 'Maximal 30 Zeichen';
    if (trimmed.contains('@')) return 'Kein @ erlaubt';
    return null;
  }

  Future<void> _save() async {
    final trimmed = _controller.text.trim();
    final validationError = _validate(trimmed);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileProvider.notifier).save(
            displayName: trimmed.isNotEmpty ? trimmed : null,
          );
      if (!mounted) return;
      context.go(Routes.dashboard);
    } catch (_) {
      if (mounted) setState(() => _error = 'Speichern fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Skips the name setup but still creates the profile row so the prompt
  /// doesn't appear again on next login.
  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      // Upsert with no displayName — creates the row to suppress future prompts.
      await ref.read(profileProvider.notifier).save();
      if (!mounted) return;
      context.go(Routes.dashboard);
    } catch (_) {
      if (mounted) context.go(Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Wie möchtest du heißen?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dein Anzeigename wird sichtbar, wenn du Erfahrungen mit der Community teilst. '
                'Du kannst ihn jederzeit in deinem Profil ändern.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  hintText: 'Dein Name',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Weiter',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: Text(
                    'Überspringen — ich bleibe anonym',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
