import 'package:flutter/material.dart';

import '../widgets/premium_glassmorphic_card.dart';

class TrainingIntroScreen extends StatelessWidget {
  final VoidCallback onStart;

  const TrainingIntroScreen({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48, // Screen height minus padding
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Hero Icon - Larger and more prominent
                        Icon(
                          Icons.self_improvement,
                          size: 120,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title - Bigger and bolder
                        Text(
                          'Willkommen zum Training',
                          style: theme.textTheme.headlineLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description - Better readability
                        Text(
                          'Heute absolvierst du 7 Übungen für dein pränatales Reflextraining.',
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Nimm dir Zeit und konzentriere dich auf jede Übung.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.75),
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Glassmorphic Info Card - Premium look
                        PremiumGlassmorphicCard(
                          blur: 30,
                          opacity: 0.2,
                          borderRadius: 20,
                          padding: const EdgeInsets.all(20.0),
                          borderColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                context,
                                Icons.fitness_center,
                                '7 Übungen',
                              ),
                              const SizedBox(height: 14),
                              _buildInfoRow(
                                context,
                                Icons.timer,
                                'ca. 15-20 Minuten',
                              ),
                              const SizedBox(height: 14),
                              _buildInfoRow(
                                context,
                                Icons.smartphone,
                                'Bequeme Kleidung empfohlen',
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Start Button - More prominent
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: onStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Los geht\'s!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
