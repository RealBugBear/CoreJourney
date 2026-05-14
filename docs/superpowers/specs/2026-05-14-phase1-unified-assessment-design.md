# Phase 1 — Unified Assessment View & Trainer Navigation Design

## Goal

Unify the assessment result screen so trainer and user see identical content. Replace the inline score card in the trainer client detail screen with tappable profile rows that open the shared result screen. Rename "Relevante Angaben" → "Ergänzende Angaben" and strip chips — only free text and months are shown.

---

## Scope

**Three changes, all frontend:**

1. **`reflex_profile_result_helpers.dart`** — update filter, rename section
2. **`reflex_profile_result_screen.dart`** — rename heading, remove chip rendering
3. **`trainer_client_detail_screen.dart`** — replace inline `_SharedReflexProfileCard` with tappable rows; delete all duplicate trainer assessment widgets

Nothing else changes: radar, score tiles, warning card, trainer share card, PDF button, dashboard button, `_ReflexProfileNotesCard` — all untouched.

---

## Change 1 — Helper filter update

**File:** `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart`

### Filter rule change

Current: item is relevant if `selectedIds.isNotEmpty || hasFreeText || hasMonths`

New: item is relevant if `hasFreeText || hasMonths` (selectedIds condition removed entirely)

### What stays

- `RelevantAnswerItem` keeps `selectedOptionLabels` field (no caller deletion needed; it just becomes always empty)
- `buildRelevanteAngaben` logic unchanged except the filter line
- `reflexModuleLabel` unchanged
- Sort by `question.number` unchanged

### Updated filter lines (inside the loop)

```dart
if (!hasFreeText && months == null) continue;
```

The `selectedIds` / `optionLabels` local variables and the option-label resolution block are **deleted** — they are no longer needed.

---

## Change 2 — Result screen updates

**File:** `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart`

### Rename heading

In `_ResultContent.build`, change:

```dart
Text(
  'Relevante Angaben',
  ...
)
```

to:

```dart
Text(
  'Ergänzende Angaben',
  ...
)
```

### Remove chip rendering from `_RelevantAnswerCard`

The widget currently renders chips when `item.selectedOptionLabels.isNotEmpty`. Since the helper no longer produces items with option labels, this branch is dead code — delete it entirely.

Specifically, remove:
- The `final hasChips = item.selectedOptionLabels.isNotEmpty;` variable
- The entire `if (hasChips) ...` block (chips Wrap + SizedBox)
- The divider that appears only when chips precede free text
- Any spacing logic that references `hasChips`

Simplified card rendering order after the change:
1. Question text (muted, `bodySmall`, `height: 1.4`)
2. Free text if present: `Text('„${item.freeText}"')` — italic, muted 70%
3. Months if present: `Text('${item.months} Monate')` — bold
4. `SizedBox(height: 4)` between free text and months if both are present

No divider, no chips, no `hasChips` variable.

---

## Change 3 — Trainer client detail screen

**File:** `lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart`

### Replace inline card with tappable profile row

In `_ResultContent.build` (the `sharedProfiles.isEmpty` else branch), replace:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _SharedReflexProfileCard(assessment: profile.latestAssessment!),
    const SizedBox(height: 12),
    _ReflexProfileNotesCard(...),
    const SizedBox(height: 16),
  ],
)
```

with:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _TappableProfileRow(profile: profile, clientId: client.clientId),
    const SizedBox(height: 12),
    _ReflexProfileNotesCard(
      assessment: profile.latestAssessment!,
      ownerUserId: client.clientId,
    ),
    const SizedBox(height: 16),
  ],
)
```

The "Noch kein abgeschlossenes Reflexprofil." text branch stays — only shown when `profile.latestAssessment == null`.

### New `_TappableProfileRow` widget

```dart
class _TappableProfileRow extends StatelessWidget {
  const _TappableProfileRow({
    required this.profile,
    required this.clientId,
  });

  final TrainerSharedProfile profile;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    final assessment = profile.latestAssessment!;
    final cs = Theme.of(context).colorScheme;

    final age = profile.ageYears != null
        ? '${profile.ageYears} Jahr${profile.ageYears == 1 ? '' : 'e'}'
        : (profile.ageGroup ?? '');
    final dateStr = DateFormat('dd.MM.yyyy', 'de_DE')
        .format(assessment.completedAt ?? assessment.createdAt);

    // Determine top band for summary pill
    final topBand = _topScoredBand(assessment);
    final bandLabel = topBand != null ? _bandPillLabel(topBand) : null;
    final bandColor = topBand != null ? _bandPillColor(topBand, cs) : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          Routes.reflexProfileResult,
          extra: {'assessment': assessment},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          [if (age.isNotEmpty) age, dateStr].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        if (bandLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bandColor!.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bandLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: bandColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Band pill helpers (private to file)

`assessment.scores` is `Map<String, dynamic>` where each value is a `Map` with `'band'` (String matching `ReflexScoreBand.name`) and `'percent'` (num). `ReflexScoreBand` enum values: `strong`, `elevated`, `indication`, `inconspicuous`, `insufficientData`.

```dart
/// Returns the worst ReflexScoreBand across all scored reflexes,
/// or null if none are 'strong' or 'elevated'.
ReflexScoreBand? _topScoredBand(ReflexProfileAssessment assessment) {
  ReflexScoreBand? worst;
  for (final raw in assessment.scores.values) {
    if (raw is! Map) continue;
    final band = ReflexScoreBand.values.firstWhere(
      (b) => b.name == (raw['band'] as String? ?? ''),
      orElse: () => ReflexScoreBand.insufficientData,
    );
    if (band == ReflexScoreBand.strong) return band; // can't get worse
    if (band == ReflexScoreBand.elevated) worst = band;
  }
  return worst;
}

String _bandPillLabel(ReflexScoreBand band) => switch (band) {
      ReflexScoreBand.strong => 'stark auffällig',
      ReflexScoreBand.elevated => 'auffällig',
      _ => '',
    };

Color _bandPillColor(ReflexScoreBand band, ColorScheme cs) => switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      _ => cs.onSurface,
    };
```

### Deleted classes

Remove entirely from `trainer_client_detail_screen.dart`:

- `_SharedReflexProfileCard` (line 472)
- `_TrainerScoreBar` (line 588)
- `_TrainerAnswerRow` (line 627)
- `_TrainerScoreRow` (line 664)
- `_trainerScoreRows()` (line 676)
- `_trainerSafetyRows()` (find exact line)
- `_trainerFormatAnswer()` (find exact line)
- `_trainerBandColor()` (line 728)
- `_trainerScoreBandFromName()` (find exact line)
- `_trainerReflexLabel()` (find exact line)

The `_SharedProfileHeader` widget is also replaced — it previously just showed name + age icon as a Row above the card. With the new `_TappableProfileRow` it's no longer needed (name/age are shown inside the row). **Delete `_SharedProfileHeader`.**

The `_ReflexProfileNotesCard` widget is **kept** — it shows trainer-only notes about the assessment and is not part of the result screen.

---

## Navigation

The trainer result screen uses the existing `Routes.reflexProfileResult` route with `extra: {'assessment': assessment}`. This is already supported by `ReflexProfileResultScreen`:

```dart
final passedAssessment = extra is Map<String, dynamic>
    ? extra['assessment'] as ReflexProfileAssessment?
    : null;
```

No router changes needed.

---

## Tests

**`test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart`**

Tests to update:
- Remove or update any test that asserts `selectedOptionLabels` is non-empty (the filter no longer includes selectedIds-only items)
- Update the "only selectedIds, no text, no months → not shown" test if it currently asserts the opposite
- Add: "item with only selectedIds → not shown" (explicit regression)
- Remaining tests (freeText only, months only, both, empty answers, unknown question ID, module ordering) stay as-is

No new widget tests required (chip rendering removal is covered by the filter change — no chip data reaches the widget layer).

---

## Import cleanup

After deleting `_TrainerScoreBar` and related classes from the trainer detail screen, run `flutter analyze` and remove any imports that become unused (likely: none, since `ReflexProfileAssessment` and `DateFormat` are still used by `_TappableProfileRow`).

---

## Testing checklist

- Trainer client detail: tap profile row → navigates to full result screen
- Trainer client detail: profile row shows name, age, date, band pill (if applicable)
- Trainer client detail: "Noch kein Reflexprofil" text still shows when no assessment
- Result screen (user): "Ergänzende Angaben" heading appears (not "Relevante Angaben")
- Result screen (user): no chips rendered even for questions that had selected_options
- Result screen (user): free text shows italic in „quotes"
- Result screen (user): months show bold "N Monate"
- Result screen (trainer): identical layout to user view
- `_ReflexProfileNotesCard` still renders below the tappable row
