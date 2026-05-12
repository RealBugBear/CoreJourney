import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../progress/presentation/providers/progress_provider.dart';

const _packages = [
  ('moro', 'Moro Reflex'),
  ('spinal_galant', 'Spinaler Galant + Amphibien'),
  ('tlr', 'Tonischer Labirint Reflex (TLR)'),
  ('babkin', 'Babkin + Plantar + Greifen'),
  ('such_saug', 'Such-Saug Reflex'),
  ('atnr', 'ATNR'),
  ('stnr', 'STNR'),
  ('babinski', 'Babinski Reflex'),
  ('landau', 'Landau Reflex'),
];

// Indices of packages that are free/unlocked
const _freePackageIndices = {0, 1, 2};

class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedPackageId = ref.watch(selectedPackageIdProvider);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final allowDevPackageSwitch = currentEmail.endsWith('@corejourney.dev');

    // Read all user enrollments to derive real per-package status.
    // Do NOT use static frontend logic to determine completion.
    final allEnrollments =
        ref.watch(allUserEnrollmentsProvider).valueOrNull ?? [];
    final completedPackageIds = {
      for (final e in allEnrollments)
        if (e.status == 'completed') e.packageId,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.packages)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (packageId, packageName) = _packages[index];
          final isSelected = packageId == selectedPackageId;
          final isLocked = !_freePackageIndices.contains(index);
          final isCompleted = completedPackageIds.contains(packageId);

          final Color avatarColor;
          if (isSelected) {
            avatarColor = AppColors.primary;
          } else if (isLocked) {
            avatarColor = AppColors.divider;
          } else if (isCompleted) {
            avatarColor = AppColors.success;
          } else {
            avatarColor = AppColors.success.withValues(alpha: 0.4);
          }

          return Card(
            child: ListTile(
              onTap: allowDevPackageSwitch
                  ? () {
                      ref
                          .read(selectedPackageIdProvider.notifier)
                          .select(packageId);
                      context.pop();
                    }
                  : null,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              title: Text(
                packageName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isLocked ? AppColors.textDisabled : null,
                ),
              ),
              subtitle: isSelected
                  ? Text(
                      l10n.packageCurrent,
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12),
                    )
                  : allowDevPackageSwitch
                      ? Text(
                          'Dev-Auswahl verfuegbar',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        )
                      : isLocked
                          ? Text(
                              l10n.packageLocked,
                              style: const TextStyle(
                                  color: AppColors.textDisabled, fontSize: 12),
                            )
                          : isCompleted
                              ? Text(
                                  l10n.packageCompleted,
                                  style: const TextStyle(
                                      color: AppColors.success, fontSize: 12),
                                )
                              : Text(
                                  'Im festen Paketverlauf',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12),
                                ),
              trailing: allowDevPackageSwitch
                  ? const Icon(Icons.chevron_right)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
