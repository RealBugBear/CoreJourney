# Hands-free Funnel Review Guide

Zweck: Regelmaessige Auswertung des Start-Funnels fuer Hands-free UX.

## Relevante Events

1. `training_start_tap`
- Zeitpunkt: Direkt beim Tap auf `Training starten`.
- Parameter:
  - `mode` (`routine` / `tutorial`)
  - `compact_tutorial` (`true` / `false`)
  - `handsfree_setup_completed` (`true` / `false`)

2. `training_first_exercise_entered`
- Zeitpunkt: Beim Eintritt in Übung 1.
- Parameter:
  - `mode`
  - `compact_tutorial`
  - `time_to_first_exercise_ms`

## Kernmetriken

1. Start -> Übung 1 Conversion
- Formel:
  - `count(training_first_exercise_entered) / count(training_start_tap)`
- Ziel:
  - >= 85% insgesamt
  - >= 90% fuer `mode = routine`

2. Median Time-to-first-exercise
- Quelle:
  - `time_to_first_exercise_ms` aus `training_first_exercise_entered`
- Ziel:
  - < 5000 ms

3. Segmentvergleich
- `routine` vs. `tutorial`
- `compact_tutorial = true` vs. `false`
- `handsfree_setup_completed = true` vs. `false`

## Woechentlicher Review-Ablauf

1. Zeitraum: letzte 7 Tage.
2. Segmentiere nach `mode`.
3. Reporte:
- Conversion pro Segment
- Median `time_to_first_exercise_ms` pro Segment
- Sample Size je Segment
4. Falls Sample Size < 50 je Segment:
- nur Trend notieren, keine harte Produktentscheidung.

## Entscheidungsregeln

1. Wenn `routine` Conversion < 90%:
- zuerst Startscreen CTA und Setup-Hinweise pruefen.

2. Wenn Median `time_to_first_exercise_ms` > 5000:
- Intro-/Ansage-/Autoplay-Verzoegerungen pruefen.

3. Wenn `compact_tutorial = true` besser performt:
- Default fuer Tutorial ueberdenken.

## Operative Notizen

1. Events sind bereits im Code instrumentiert.
2. Auswertung erfolgt im Analytics-Backend (Firebase).
3. Bei anomalen Spikes immer Release/Commit und Datum notieren.
