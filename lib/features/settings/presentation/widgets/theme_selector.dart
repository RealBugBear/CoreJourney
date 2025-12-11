import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

/// Widget für Theme-Auswahl
/// 
/// Zeigt die verfügbaren Theme-Modi (Hell, Dunkel, System) und
/// ermöglicht dem Nutzer die Auswahl.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Card(
      child: Column(
        children: [
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.system,
            currentMode: currentTheme,
            icon: Icons.brightness_auto,
            title: 'System',
            subtitle: 'Folgt den System-Einstellungen',
          ),
          const Divider(height: 0),
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.light,
            currentMode: currentTheme,
            icon: Icons.light_mode,
            title: 'Hell',
            subtitle: 'Immer helles Design',
          ),
          const Divider(height: 0),
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.dark,
            currentMode: currentTheme,
            icon: Icons.dark_mode,
            title: 'Dunkel',
            subtitle: 'Immer dunkles Design',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : const Icon(
              Icons.radio_button_unchecked,
              color: AppColors.textSecondary,
            ),
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        
        // Optional: Feedback für den Nutzer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme geändert zu: $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
