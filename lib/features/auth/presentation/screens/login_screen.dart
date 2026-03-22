import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _showPasswordReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final notifier = ref.read(authNotifierProvider.notifier);

    if (_isSignUp) {
      await notifier.signUp(email: email, password: password);
    } else {
      await notifier.signIn(email: email, password: password);
    }

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (!authState.hasError) {
        context.go(Routes.dashboard);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email: email);

    if (mounted) {
      setState(() => _showPasswordReset = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).passwordResetSent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authNotifierProvider, (_, next) {
      if (next.hasError) {
        // Error is shown inline — no snackbar needed
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => ref.read(authNotifierProvider.notifier).clearError(),
              ),
              const SizedBox(height: 16),

              // Password field (hidden in password reset mode)
              if (!_showPasswordReset) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => ref.read(authNotifierProvider.notifier).clearError(),
                ),
                const SizedBox(height: 8),
              ],

              // Error message
              if (authState.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  _localizeAuthError(authState.error.toString(), l10n),
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 24),

              // Primary button
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (_showPasswordReset ? _sendPasswordReset : _submit),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_showPasswordReset
                        ? l10n.resetPassword
                        : (_isSignUp ? l10n.signUp : l10n.signIn)),
              ),
              const SizedBox(height: 16),

              // Toggle sign in / sign up
              if (!_showPasswordReset)
                TextButton(
                  onPressed: () {
                    setState(() => _isSignUp = !_isSignUp);
                    ref.read(authNotifierProvider.notifier).clearError();
                  },
                  child: Text(_isSignUp ? l10n.signIn : l10n.signUp),
                ),

              // Forgot password toggle
              if (!_isSignUp)
                TextButton(
                  onPressed: () {
                    setState(() => _showPasswordReset = !_showPasswordReset);
                    ref.read(authNotifierProvider.notifier).clearError();
                  },
                  child: Text(
                    _showPasswordReset ? l10n.cancel : l10n.forgotPassword,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    if (error.contains('invalid_credentials') ||
        error.contains('Invalid login')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (error.contains('already registered') ||
        error.contains('already been registered')) {
      return l10n.authErrorEmailInUse;
    }
    if (error.contains('weak') || error.contains('password')) {
      return l10n.authErrorWeakPassword;
    }
    return l10n.errorGeneric;
  }
}
