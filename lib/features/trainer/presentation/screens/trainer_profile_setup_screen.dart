import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/trainer_discovery_provider.dart';
import '../widgets/trainer_location_picker_widget.dart';

class TrainerProfileSetupScreen extends ConsumerStatefulWidget {
  const TrainerProfileSetupScreen({super.key});

  @override
  ConsumerState<TrainerProfileSetupScreen> createState() =>
      _TrainerProfileSetupScreenState();
}

class _TrainerProfileSetupScreenState
    extends ConsumerState<TrainerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  LatLng? _pickedLocation;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_pickedLocation == null) {
      setState(() => _errorMessage = l10n.trainerSetupLocationMissing);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(trainerProfileRepositoryProvider);
      await repo.upsertProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      await repo.updateLocation(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );
      ref.invalidate(ownTrainerProfileProvider);
      if (mounted) context.go(Routes.trainerProfilePending);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerSetupTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration:
                  InputDecoration(labelText: l10n.trainerSetupDisplayNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validationRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(labelText: l10n.trainerSetupBioLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration:
                  InputDecoration(labelText: l10n.trainerSetupEmailLabel),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? l10n.validationInvalidEmail : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.trainerSetupPhoneLabel),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Text(l10n.trainerSetupLocationTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.trainerSetupLocationHint,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TrainerLocationPickerWidget(
                  onLocationPicked: (latLng) =>
                      setState(() => _pickedLocation = latLng),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.trainerSetupSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
