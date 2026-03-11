# CoreJourney Handoff QA Matrix

Zweck: Ausfuehrbare QA-Matrix fuer die Drittpartei auf Basis der Release-Readiness-Checkliste.

## Status-Legende
- `TODO`: Noch nicht getestet
- `PASS`: Erfolgreich getestet
- `FAIL`: Fehler gefunden (Ticket anlegen und Re-Test markieren)
- `BLOCKED`: Nicht testbar (Grund dokumentieren)

## Durchfuehrung
1. Plattform waehlen (`iOS`, `Android`).
2. Testfall ausfuehren und Status setzen.
3. Bei `FAIL` Bug-ID erfassen und Cluster zuordnen.
4. Nach Fix Re-Test in separater Spalte dokumentieren.

## Matrix

| ID | Cluster | Plattform | Testfall | Erwartung | Owner | Status | Bug-ID | Re-Test |
|---|---|---|---|---|---|---|---|---|
| HF-01 | Hands-free | iOS | Training in `Routine (Hands-free)` starten | Session startet direkt mit Uebung 1 | QA | TODO | - | TODO |
| HF-02 | Hands-free | iOS | Bildschirm waehrend Session beobachten | Display bleibt aktiv (`wakelock`) | QA | TODO | - | TODO |
| HF-03 | Audio/Musik | iOS | Feedback-Modus `Ton aus` testen | Keine Audio-Cues, kein TTS, Haptik gemaess Modus | QA | TODO | - | TODO |
| HF-04 | Audio/Musik | iOS | Feedback-Modus `Nur Haptik` testen | Nur Haptik bei Start/Wechsel/Abschluss | QA | TODO | - | TODO |
| HF-05 | Audio/Musik | iOS | Feedback-Modus `Sprache + Cues + Haptik` testen | TTS + Cues + Haptik triggern korrekt | QA | TODO | - | TODO |
| HF-06 | Audio/Musik | iOS | Externe Musik (Spotify/Apple Music) laufen lassen + Training starten | Musik laeuft weiter (Mix-Verhalten ok) | QA | TODO | - | TODO |
| RM-01 | Reminder-Verhalten | iOS | Reminder aktivieren, Cadence `minimal` setzen | Genau ein naechster Reminder geplant | QA | TODO | - | TODO |
| RM-02 | Reminder-Verhalten | iOS | Reminder aktivieren, Cadence `balanced` setzen | Genau ein naechster Reminder geplant | QA | TODO | - | TODO |
| RM-03 | Reminder-Verhalten | iOS | Erneut Einstellungen speichern | Kein Duplicate-Scheduling | QA | TODO | - | TODO |
| RM-04 | Reminder-Verhalten | iOS | Heute Training absolvieren | Reminder wird auf naechsten Tag verschoben | QA | TODO | - | TODO |
| RM-05 | Reminder-Verhalten | iOS | Reminder-Zeitfenster kurz vor Zielzeit simulieren | Delayed Scheduling im Fenster greift | QA | TODO | - | TODO |
| SY-01 | Offline/Sync | iOS | Flugmodus aktivieren, Training abschliessen | Daten lokal persistiert, keine App-Fehler | QA | TODO | - | TODO |
| SY-02 | Offline/Sync | iOS | Im Flugmodus Settings aendern | Aenderungen lokal uebernommen | QA | TODO | - | TODO |
| SY-03 | Offline/Sync | iOS | Online gehen | Queue drain auf 0, kein Deadlock | QA | TODO | - | TODO |
| SY-04 | Offline/Sync | iOS | Nach Sync Daten validieren | Server-/UI-Stand konsistent, kein Datenverlust | QA | TODO | - | TODO |
| DB-01 | Dashboard-Konsistenz | iOS | Nach Training Dashboard oeffnen | `Heute`, `Diese Woche`, `Streak`, `Tag x/28` konsistent | QA | TODO | - | TODO |
| DB-02 | Dashboard-Konsistenz | iOS | Momentum-Bar und Journey-Map pruefen | Werte passen zum Snapshot | QA | TODO | - | TODO |
| HF-07 | Hands-free | Android | Training in `Routine (Hands-free)` starten | Session startet direkt mit Uebung 1 | QA | TODO | - | TODO |
| HF-08 | Hands-free | Android | Bildschirm waehrend Session beobachten | Display bleibt aktiv (`WAKE_LOCK`) | QA | TODO | - | TODO |
| HF-09 | Audio/Musik | Android | Alle Feedback-Modi testen | Verhalten entspricht iOS-Funktionalitaet | QA | TODO | - | TODO |
| HF-10 | Audio/Musik | Android | Externe Musik laufen lassen + Training starten | Musik laeuft weiter (Mix-Verhalten ok) | QA | TODO | - | TODO |
| RM-06 | Reminder-Verhalten | Android | Cadence `minimal`/`balanced` testen | Adaptive Planung ohne Duplikate | QA | TODO | - | TODO |
| RM-07 | Reminder-Verhalten | Android | Heute trainiert -> Reminder neu planen | Reminder wird korrekt verschoben | QA | TODO | - | TODO |
| SY-05 | Offline/Sync | Android | Offline Training + Settings aendern | Lokale Persistenz stabil | QA | TODO | - | TODO |
| SY-06 | Offline/Sync | Android | Wieder online + Sync beobachten | Queue drain auf 0, Daten konsistent | QA | TODO | - | TODO |
| DB-03 | Dashboard-Konsistenz | Android | Dashboard nach Training pruefen | KPI + Snapshot-Konsistenz gegeben | QA | TODO | - | TODO |

## Bug-Cluster-Regeln
- `Reminder-Verhalten`: Planung, Cadence, Duplikate, Zeitfenster, Anti-Spam.
- `Audio/Musik`: Haptik, Cue-Sounds, TTS, Musik-Mix/Session-Konflikte.
- `Offline/Sync`: Queue, Retry-Verhalten, Coalescing, Datenverlust.
- `Dashboard-Konsistenz`: KPI-Abweichungen, Snapshot-Mismatch, Anzeige-Inkonsistenzen.

## Exit-Kriterien (Go/No-Go)
- `make release-readiness-mobile` laeuft ohne Fehler.
- Keine kritischen Blocker in Hands-free, Reminder, Offline/Sync, Dashboard.
- Kein Datenverlust und kein Duplicate-Reminder-Verhalten.

## Referenzen
- `/Users/alexandermessinger/dev/corejourney/docs/RELEASE_READINESS_CHECKLIST.md`
- `/Users/alexandermessinger/dev/corejourney/docs/HANDOFF_STATUS.md`
