import 'package:flutter/material.dart';
import '../widgets/theme_selector.dart';

/// Settings Screen
/// 
/// Zentrale Einstellungs-Seite der App mit verschiedenen Konfigurations-Optionen.
/// Aktuell: Theme-Auswahl
/// Zukünftig: Benachrichtigungen, Sprache, etc.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              subtitle: const Text('Kommt bald'),
              trailing: Switch(
                value: false,
                onChanged: null, // Deaktiviert für jetzt
              ),
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
                  onTap: () {
                    // TODO: Implement password change
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwort-Änderung kommt bald!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Account löschen',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement account deletion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account-Löschung kommt bald!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
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
