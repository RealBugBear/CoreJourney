# Hands-free Manual Test Checklist (iOS)

Zweck: Schnelle manuelle Validierung der Hands-free UX nach Aenderungen an Start, Voice, Tempo und In-Session Controls.

Datum: 2026-02-24  
Geraet: Physisches iPhone (kein Simulator)  
Build-Flow: `make iphone`

## Voraussetzungen

1. iPhone ist entsperrt und via Kabel oder im gleichen Netzwerk erreichbar.
2. App ist mit aktuellem Branch-Stand installiert.
3. Settings sind erreichbar (fuer Reconfigure/Voice Presets/Tutorial kompakt).

## Testfaelle

| ID | Bereich | Schrittfolge | Erwartung |
|---|---|---|---|
| HF-01 | Start Direkt | Dashboard: Modus `Direkt starten`, dann `Training starten` | Startet ohne Welcome direkt in Übung 1 |
| HF-02 | Start Tutorial Normal | Dashboard: Modus `Tutorial`, `Tutorial kompakt` aus, Start | Intro/Position/Movement-Pfad sichtbar |
| HF-03 | Start Tutorial Kompakt | Settings: `Tutorial kompakt` an, Dashboard Modus `Tutorial`, Start | Positionsscreen wird uebersprungen, direkt Bewegungsanleitung |
| HF-04 | Setup Sheet First Run | Falls noch nicht abgeschlossen: erster Trainingsstart | Setup Sheet erscheint, Speichern moeglich, Start setzt gewaehlte Defaults |
| HF-05 | Setup Reconfigure | Settings: `Hands-free Setup neu konfigurieren` | Modus/Feedback/Starttempo aenderbar und persistent |
| HF-06 | One-Hand CTA Sichtbarkeit | In Übung: ohne Scrollen unteren Hauptbutton pruefen | `Weiter/Abschließen` immer direkt sichtbar und tappbar |
| HF-07 | Quick Controls | In Übung: `Langsamer/Schneller/Feedback` mehrfach tippen | Controls reagieren sofort, Touchflaechen ausreichend gross |
| HF-08 | Tempo ohne Reset | Laufende Animation: `Schneller/Langsamer` tippen | Animation/Timer laufen weiter, kein kompletter Neustart |
| HF-09 | Tempo Guardrail | Sehr schnelles Tempo einstellen | Warnhinweis erscheint, Flow bleibt unblocked |
| HF-10 | Voice Presets | Settings: `Sanft/Neutral/Dynamisch` + `Stimme testen` | Deutlich unterscheidbare Stimmcharakteristik ohne Fehler |
| HF-11 | Feedbackmodi | In Übung/Settings: Stimme, Haptik, Stumm wechseln | Verhalten passt zum Modus (Audio/Haptik konsistent) |
| HF-12 | App Reopen | Nach erfolgreichem Start App schließen und vom Home Screen öffnen | App startet normal ohne Debug-Warnbildschirm |
| HF-13 | Launch Robustness Locked | Gerät sperren, `make iphone` ausführen | Klarer Lock-Hinweis im Terminal, keine unklare Fehlersituation |
| HF-14 | Launch Robustness Unplugged | Kabel trennen/Device nicht verfügbar, `make iphone` | Klare Meldung: kein physisches iPhone erkannt |
| HF-15 | Funnel Tracking Smoke | Training starten bis Übung 1 | Events `training_start_tap` + `training_first_exercise_entered` werden ausgelöst (Debug/Analytics-Check) |

## Abnahmekriterien (Hands-free)

1. Start in Übung 1 im Direktmodus reproduzierbar.
2. In Übung ist kein Scrollen notwendig, um weiterzumachen.
3. Tempoaenderung unterbricht den laufenden Rhythmus nicht.
4. Voice Presets und Feedback-Modi sind in <=2 Taps testbar.
5. Launch via `make iphone` ist im Normalfall stabil und nachvollziehbar.

## Fehlerprotokoll (bei FAIL)

1. Commit/Branch
2. iPhone Modell + iOS Version
3. Test-ID aus dieser Liste
4. Exakter Timestamp
5. Kurzvideo/Screenshot
6. Terminal-Auszug (`make iphone` / `make iphone-open`)
