import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitted = false;
  String? _serverError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    final l10n = AppLocalizations.of(context);
    if ((value ?? '').isEmpty) return l10n.validationRequired;
    return null;
  }

  String? _validateNew(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length < 8) return l10n.validationPasswordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return l10n.validationRequired;
    if (v != _newPasswordController.text) return l10n.validationPasswordMismatch;
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    // Re-Auth: aktuelles Passwort verifizieren
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _serverError = l10n.authErrorInvalidCurrentPassword);
      }
      return;
    }

    // Passwort aktualisieren
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.updatePassword(newPassword: newPassword);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      setState(() =>
          _serverError = _localizeAuthError(authState.error.toString(), l10n));
      return;
    }

    // Erfolg
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordChanged)),
      );
    }
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    if (error.contains('same_password')) return l10n.authErrorSamePassword;
    if (error.contains('invalid_credentials') ||
        error.contains('Invalid login')) {
      return l10n.authErrorInvalidCurrentPassword;
    }
    if (error.contains('weak') || error.contains('password')) {
      return l10n.authErrorWeakPassword;
    }
    return l10n.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileChangePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aktuelles Passwort
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: _validateCurrent,
                  onChanged: (_) => setState(() => _serverError = null),
                ),
                const SizedBox(height: 16),

                // Neues Passwort
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: _validateNew,
                  onChanged: (_) => setState(() => _serverError = null),
                ),
                const SizedBox(height: 16),

                // Bestätigung
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.passwordConfirm,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: _validateConfirm,
                  onChanged: (_) => setState(() => _serverError = null),
                  onFieldSubmitted: (_) => _submit(),
                ),

                // Server-Fehler
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serverError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.confirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
