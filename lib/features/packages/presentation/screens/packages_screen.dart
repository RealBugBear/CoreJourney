import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

const _packageNames = [
  'Moro Reflex',
  'Spinaler Galant + Amphibien',
  'Tonischer Labirint Reflex (TLR)',
  'Babkin + Plantar + Greifen',
  'Such-Saug Reflex',
  'ATNR',
  'STNR',
  'Babinski Reflex',
  'Landau Reflex',
];

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.packages)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _packageNames.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final isFirst = index == 0;
          final isCurrent = isFirst;
          final isLocked = index > 0;

          return Card(
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isLocked
                          ? AppColors.divider
                          : AppColors.success,
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
                _packageNames[index],
                style: TextStyle(
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isLocked ? AppColors.textDisabled : null,
                ),
              ),
              subtitle: isCurrent
                  ? Text(
                      l10n.packageCurrent,
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 12),
                    )
                  : isLocked
                      ? Text(
                          l10n.packageLocked,
                          style: TextStyle(
                              color: AppColors.textDisabled, fontSize: 12),
                        )
                      : Text(l10n.packageCompleted,
                          style: TextStyle(
                              color: AppColors.success, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
