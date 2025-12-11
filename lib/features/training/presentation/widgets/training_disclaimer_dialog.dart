import 'package:flutter/material.dart';

/// Training Disclaimer Dialog
/// 
/// Shows safety warnings before training about physical and psychological risks.
/// Implements scroll-to-enable pattern: user must scroll to bottom before accepting.
class TrainingDisclaimerDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TrainingDisclaimerDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<TrainingDisclaimerDialog> createState() => _TrainingDisclaimerDialogState();
}

class _TrainingDisclaimerDialogState extends State<TrainingDisclaimerDialog> {
  late ScrollController _scrollController;
  bool _hasScrolledToBottom = false;
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Check after first frame if content is scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  void _checkIfScrollable() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      setState(() {
        _showScrollIndicator = maxScroll > 0;
        // If not scrollable, enable button immediately
        if (!_showScrollIndicator) {
          _hasScrolledToBottom = true;
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    // Consider "bottom" when within 20 pixels of the end
    const threshold = 20.0;
    final isAtBottom = currentScroll >= (maxScroll - threshold);
    
    if (isAtBottom && !_hasScrolledToBottom) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Wichtiger Hinweis'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main warning
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Dieses Training aktiviert den Moro-Reflex und kann intensive körperliche und emotionale Reaktionen auslösen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Physical risks
                  _buildRiskSection(
                    context: context,
                    icon: Icons.fitness_center,
                    color: Colors.red,
                    title: 'KÖRPERLICHE RISIKEN',
                    risks: [
                      'Körper kann überreizt werden',
                      'Erhöhte Belastung - Vorsicht bei zusätzlichem Sport',
                      'Bei Schmerzen oder Unwohlsein: Sofort stoppen',
                    ],
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Psychological risks
                  _buildRiskSection(
                    context: context,
                    icon: Icons.psychology,
                    color: Colors.purple,
                    title: 'PSYCHISCHE RISIKEN',
                    risks: [
                      'Training aktiviert den Stress-Reflex',
                      'Alte Traumata können reaktiviert werden',
                      'Emotionale Reaktionen (Angst, Unruhe) sind möglich',
                    ],
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Recommendations
                  _buildRiskSection(
                    context: context,
                    icon: Icons.health_and_safety,
                    color: Colors.blue,
                    title: 'WICHTIG - WAS TUN?',
                    risks: [
                      'Hören Sie auf Ihren Körper',
                      'Bei psychischen Belastungen: Professionelle Hilfe suchen',
                      'Bei anhaltenden Beschwerden: Arzt konsultieren',
                    ],
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Final warning with hand emoji
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '✋',
                          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nur fortfahren, wenn Sie sich dieser Risiken bewusst sind und die Verantwortung übernehmen.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Add padding at bottom for scroll indicator
                  if (_showScrollIndicator && !_hasScrolledToBottom)
                    const SizedBox(height: 60),
                ],
              ),
            ),
            
            // Scroll indicator overlay
            if (_showScrollIndicator)
              _buildScrollIndicator(theme, isSmallScreen),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onDecline,
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _hasScrolledToBottom ? widget.onAccept : null,
          style: FilledButton.styleFrom(
            backgroundColor: _hasScrolledToBottom
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _hasScrolledToBottom
                  ? 'Verstanden, fortfahren'
                  : 'Bitte scrollen',
              key: ValueKey(_hasScrolledToBottom),
              style: TextStyle(
                color: _hasScrolledToBottom
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollIndicator(ThemeData theme, bool isSmallScreen) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _hasScrolledToBottom ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            height: isSmallScreen ? 70 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.dialogBackgroundColor.withOpacity(0),
                  theme.dialogBackgroundColor,
                  theme.dialogBackgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 8.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: child,
                      );
                    },
                    onEnd: () {
                      // Restart animation
                      if (mounted && !_hasScrolledToBottom) {
                        setState(() {});
                      }
                    },
                    child: Icon(
                      Icons.keyboard_double_arrow_down,
                      color: theme.colorScheme.primary,
                      size: isSmallScreen ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bitte scrollen',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskSection({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required List<String> risks,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isSmallScreen ? 12 : 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...risks.map((risk) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: color,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
              Expanded(
                child: Text(
                  risk,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
