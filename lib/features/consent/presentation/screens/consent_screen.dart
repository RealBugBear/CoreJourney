import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../providers/consent_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';


// ── Screen ────────────────────────────────────────────────────────────────────

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  final _scrollController = ScrollController();
  bool _agreed = false;
  bool _saving = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_agreed || _saving) return;
    setState(() => _saving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Write to Supabase for permanent audit trail.
      // Best-effort — if table is missing we still proceed with local cache.
      try {
        await Supabase.instance.client.from('user_consents').upsert({
          'user_id': userId,
          'consent_version': kConsentVersion,
          'consented_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        // Supabase unavailable or table not yet created — consent is still
        // stored locally below and will sync once the table exists.
      }

      // Cache locally — this is the source of truth for day-to-day checks.
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(consentPrefKey(userId), true);

      ref.invalidate(hasConsentedProvider);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDE = ref.watch(settingsProvider).languageCode == 'de';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDE ? 'Wichtige Hinweise' : 'Important Information'),
        automaticallyImplyLeading: false, // no back button — must agree to proceed
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: _ConsentBody(isDE: isDE),
              ),
            ),

            // ── Agreement checkbox + button ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      isDE
                          ? 'Ich habe diese Hinweise gelesen und verstanden.'
                          : 'I have read and understood the above information.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: (_agreed && !_saving) ? _confirm : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isDE
                                ? 'Ich stimme zu und möchte fortfahren'
                                : 'I agree and want to continue',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Consent body text ─────────────────────────────────────────────────────────

class _ConsentBody extends StatelessWidget {
  final bool isDE;
  const _ConsentBody({required this.isDE});

  @override
  Widget build(BuildContext context) {
    return isDE ? _buildDE(context) : _buildEN(context);
  }

  Widget _buildDE(BuildContext context) {
    return _ConsentContent(
      title: 'Bitte lies diese Hinweise sorgfältig durch',
      intro:
          'Das Reflexintegrations-Programm ist eine intensive körperliche und psychische Arbeit. '
          'Es kann tiefgreifende Veränderungsprozesse in Gang setzen. '
          'Damit du gut informiert starten kannst, möchten wir dich auf Folgendes hinweisen:',
      points: const [
        _ConsentPoint(
          icon: Icons.science_outlined,
          title: 'MVP-Prototyp — Testphase',
          body:
              'Diese App befindet sich in einer frühen Testphase. Du nimmst als freiwilliger Testnutzer teil. '
              'Es bestehen keine Garantien auf Datenschutz, Datensicherheit oder dauerhaften Betrieb. '
              'Alle erhobenen Daten können zur Produktverbesserung verwendet werden. '
              'Kein Anspruch auf Verfügbarkeit oder Fehlerfreiheit. Du kannst die Nutzung jederzeit einstellen.',
        ),
        _ConsentPoint(
          icon: Icons.favorite_border,
          title: 'Kein Ersatz für Arzt, Therapeut oder Psychologe',
          body:
              'Dieses Programm ersetzt keine medizinische, therapeutische oder psychologische Behandlung. '
              'Wenn du unter ernsthaften psychischen Beschwerden leidest, Trauma-Symptome auftreten '
              'oder du dir unsicher bist, wende dich bitte an einen Arzt, Therapeuten, '
              'Psychologen oder eine Krisenhotline.',
        ),
        _ConsentPoint(
          icon: Icons.psychology_outlined,
          title: 'Emotionale und mentale Belastung',
          body:
              'Das Training kann emotionale Reaktionen wie erhöhte Reizbarkeit, '
              'Stimmungsschwankungen oder vorübergehend verstärkten Stress auslösen. '
              'Das ist ein normaler Teil des Integrationsprozesses.',
        ),
        _ConsentPoint(
          icon: Icons.layers_outlined,
          title: 'Verdrängte Erlebnisse können auftauchen',
          body:
              'In manchen Fällen können durch das Training tief liegende, '
              'verdrängte Erlebnisse oder Traumata an die Oberfläche kommen. '
              'Das kann belastend sein. Wir empfehlen, während des Programms '
              'Zugang zu psychologischer Unterstützung zu haben.',
        ),
        _ConsentPoint(
          icon: Icons.bedtime_outlined,
          title: 'Schlafveränderungen möglich',
          body:
              'Vorübergehende Schlafstörungen oder Veränderungen im Schlafrhythmus '
              'können auftreten, insbesondere in intensiveren Phasen des Programms.',
        ),
        _ConsentPoint(
          icon: Icons.self_improvement_outlined,
          title: 'Deine Verantwortung',
          body:
              'Du allein kennst deinen Körper und deine Grenzen. '
              'Höre auf dich selbst, mache Pausen wenn nötig, und suche '
              'professionelle Hilfe, wenn du dich überfordert fühlst. '
              'Du bestimmst das Tempo.',
        ),
      ],
      closing:
          'Indem du fortfährst, bestätigst du, dass du diese Hinweise gelesen und '
          'verstanden hast, und dass du freiwillig und informiert an diesem Programm teilnimmst.',
    );
  }

  Widget _buildEN(BuildContext context) {
    return _ConsentContent(
      title: 'Please read this information carefully',
      intro:
          'The Reflex Integration Program involves intensive physical and psychological work. '
          'It can initiate profound processes of change in your body and mind. '
          'To help you start well-informed, please read the following:',
      points: const [
        _ConsentPoint(
          icon: Icons.science_outlined,
          title: 'MVP Prototype — Test Phase',
          body:
              'This app is in an early test phase. You are participating as a voluntary test user. '
              'There are no guarantees regarding data privacy, data security, or continued availability. '
              'Data collected may be used for product improvement. No warranty for uptime or correctness. '
              'You may stop using the app at any time.',
        ),
        _ConsentPoint(
          icon: Icons.favorite_border,
          title: 'Not a replacement for doctors, therapists, or psychologists',
          body:
              'This program does not replace medical, therapeutic, or psychological treatment. '
              'If you are experiencing serious psychological distress, trauma symptoms arise, '
              'or you are unsure about your wellbeing, please consult a doctor, therapist, '
              'psychologist, or a crisis helpline.',
        ),
        _ConsentPoint(
          icon: Icons.psychology_outlined,
          title: 'Emotional and mental stress',
          body:
              'The training may trigger emotional reactions such as increased irritability, '
              'mood changes, or temporarily heightened stress. '
              'This is a normal part of the integration process.',
        ),
        _ConsentPoint(
          icon: Icons.layers_outlined,
          title: 'Buried experiences may surface',
          body:
              'In some cases, deep-seated or suppressed experiences and trauma '
              'may come to the surface during the program. This can be challenging. '
              'We recommend having access to psychological support during the program.',
        ),
        _ConsentPoint(
          icon: Icons.bedtime_outlined,
          title: 'Sleep changes are possible',
          body:
              'Temporary sleep disturbances or changes in sleep patterns may occur, '
              'especially during more intensive phases of the program.',
        ),
        _ConsentPoint(
          icon: Icons.self_improvement_outlined,
          title: 'Your responsibility',
          body:
              'Only you know your body and your limits. '
              'Listen to yourself, take breaks when needed, and seek '
              'professional help if you feel overwhelmed. '
              'You set the pace.',
        ),
      ],
      closing:
          'By continuing, you confirm that you have read and understood this information, '
          'and that you are voluntarily and informedly participating in this program.',
    );
  }
}

class _ConsentContent extends StatelessWidget {
  final String title;
  final String intro;
  final List<_ConsentPoint> points;
  final String closing;

  const _ConsentContent({
    required this.title,
    required this.intro,
    required this.points,
    required this.closing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          intro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        ...points.map((p) => _PointCard(point: p)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            closing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ConsentPoint {
  final IconData icon;
  final String title;
  final String body;
  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _PointCard extends StatelessWidget {
  final _ConsentPoint point;
  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(point.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  point.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
