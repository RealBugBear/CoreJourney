import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
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
    if (v != _passwordController.text) {
      return l10n.localeName == 'de'
          ? 'Passwörter stimmen nicht überein.'
          : 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPassword = _passwordController.text;
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.updatePassword(newPassword: newPassword);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) return;

    // Erfolg: Recovery-Flag zurücksetzen, zur Login navigieren
    ref.read(passwordRecoveryActiveProvider.notifier).state = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordSet)),
      );
      context.go(Routes.login);
    }
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    if (error.contains('same_password')) return l10n.authErrorSamePassword;
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
      // Kein Back-Button — Nutzer war vor dem Deep Link nicht eingeloggt
      appBar: AppBar(
        title: Text(l10n.resetPassword),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Neues Passwort
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                  onChanged: (_) =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                ),
                const SizedBox(height: 16),

                // Passwort bestätigen
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
                  onChanged: (_) =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                  onFieldSubmitted: (_) => _submit(),
                ),

                // Server-Fehler
                if (authState.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _localizeAuthError(authState.error.toString(), l10n),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.resetPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
