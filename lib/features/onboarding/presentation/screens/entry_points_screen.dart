import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../providers/entry_points_provider.dart';

class EntryPointsScreen extends ConsumerStatefulWidget {
  const EntryPointsScreen({super.key});

  @override
  ConsumerState<EntryPointsScreen> createState() => _EntryPointsScreenState();
}

class _EntryPointsScreenState extends ConsumerState<EntryPointsScreen> {
  final Set<String> _expanded = {};

  void _toggleCard(String key) => setState(() {
        _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key);
      });

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(entryPointsProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Viele Wege führen hierher',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Reflexintegration ist für sehr unterschiedliche Menschen relevant. '
                'Schau, was für dich klingt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 20),
              ..._kAreas.map(
                (a) => _AreaCard(
                  area: a,
                  expanded: _expanded.contains(a.key),
                  onToggle: () => _toggleCard(a.key),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Was klingt für dich vertraut? (optional, Mehrfachauswahl)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kAreas.map((a) {
                  return FilterChip(
                    label: Text(a.chipLabel),
                    selected: selected.contains(a.key),
                    onSelected: (_) =>
                        ref.read(entryPointsProvider.notifier).toggle(a.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Deine Auswahl ändert nichts am Training — sie hilft uns zu verstehen, wer die App nutzt.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(Routes.dashboard),
                  child: const Text('Weiter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaData {
  const _AreaData({
    required this.key,
    required this.title,
    required this.teaser,
    required this.detail,
    required this.chipLabel,
    this.source,
  });
  final String key;
  final String title;
  final String teaser;
  final String detail;
  final String chipLabel;
  final String? source;
}

const _kAreas = [
  _AreaData(
    key: 'koerper_therapie',
    title: 'Körper & Therapie',
    teaser: 'Verspannungen, Fehlhaltungen, Empfehlung vom Therapeuten',
    detail:
        'Aktive Reflexmuster können zu dauerhafter Muskelanspannung führen — '
        'unabhängig von äußeren Auslösern. Physiotherapeut·innen und Ergotherapeut·innen '
        'empfehlen Reflexintegration häufig ergänzend, wenn klassische Behandlung nicht '
        'vollständig greift.\n\nTypische Hinweise: chronische Rücken- oder Nackenverspannungen, '
        'Kieferspannung, Fehlhaltungen die immer wiederkehren.',
    chipLabel: 'Körper',
    source: 'Vgl. Goddard Blythe: (Über)leben mit Reflexen',
  ),
  _AreaData(
    key: 'koordination_leistung',
    title: 'Koordination & Leistung',
    teaser: 'Bewegungsqualität, Gleichgewicht, sportliche Koordination',
    detail:
        'Unintegrierte Reflexe binden motorische Ressourcen — was sich in eingeschränkter '
        'Koordination, verlangsamten Reaktionen oder Gleichgewichtsproblemen zeigen kann. '
        'Sportler·innen nutzen Reflexintegration um koordinative Grenzen zu erweitern, '
        'die durch klassisches Training nicht erreichbar sind.\n\nTypische Hinweise: '
        'Bewegungsabläufe fühlen sich schwerer an als nötig, Asymmetrien, Gleichgewicht unter Druck.',
    chipLabel: 'Koordination',
    source: 'Vgl. Blomberg: Bewegungen die heilen',
  ),
  _AreaData(
    key: 'emotionale_regulation',
    title: 'Emotionale Regulation & Innenwelt',
    teaser: 'Stressreaktionen, Reizempfindlichkeit, Selbstwahrnehmung',
    detail:
        'Manche Reflexmuster beeinflussen direkt wie das Nervensystem auf Reize reagiert — '
        'Stressempfindlichkeit, emotionale Reaktivität, Reizüberflutung. Rhythmische Bewegung '
        'kann helfen, das Nervensystem zu regulieren und Zugang zu inneren Zuständen zu finden.\n\n'
        'Typische Hinweise: schnelle emotionale Überflutung, Schwierigkeit zur Ruhe zu kommen, '
        'Körperspannung in Stress. Verläuft sehr individuell.',
    chipLabel: 'Emotionale Regulation',
    source: 'Vgl. Blomberg: Bewegungen die heilen',
  ),
  _AreaData(
    key: 'mein_kind',
    title: 'Mein Kind: Schule & Entwicklung',
    teaser: 'Konzentration, Lernen, Schule — als Elternteil',
    detail:
        'Frühkindliche Reflexmuster die nicht vollständig integriert wurden, können sich später '
        'in Schwierigkeiten beim Lesen, Schreiben oder Konzentrieren zeigen — oft ohne klare '
        'organische Ursache.\n\nTypische Hinweise: Kind kommt in der Schule nicht mit, kann sich '
        'schwer fokussieren, ist unruhig im Unterricht, Feinmotorik oder Lesen bereitet Mühe.',
    chipLabel: 'Mein Kind',
    source: 'Vgl. Goddard Blythe: (Über)leben mit Reflexen',
  ),
  _AreaData(
    key: 'neugierde',
    title: 'Neugierde & Entdeckung',
    teaser: 'Kein konkretes Problem — einfach erkunden',
    detail:
        'Manche Menschen kommen ohne konkretes Symptom — sie haben von Reflexintegration gehört '
        'und sind neugierig was rhythmische Bewegung über mehrere Wochen verändert. '
        'Das ist ein vollständig gültiger Einstieg.\n\nDas Training wirkt unabhängig davon ob '
        'man ein "Problem" benennen kann oder nicht.',
    chipLabel: 'Einfach neugierig',
  ),
];

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.expanded,
    required this.onToggle,
  });
  final _AreaData area;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(area.teaser,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expanded ? 'Weniger ↑' : 'Mehr ↓',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.55,
                        ),
                  ),
                  if (area.source != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      area.source!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
