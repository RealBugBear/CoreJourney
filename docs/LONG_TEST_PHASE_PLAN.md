# CoreJourney Long Test Phase Plan

Ziel: Mehrtaegige Stabilitaets- und Verhaltenspruefung auf realen Geraeten (iOS zuerst, danach Android).

## Einstieg

Vor jedem Testtag:

```bash
make long-test-ready
```

Danach die Device-Checks ausfuehren und Ergebnisse dokumentieren.

## Test-Setup
- 1x iPhone (aktuelles iOS), optional 1x Android Vergleichsgeraet.
- Notifications erlaubt.
- Mindestens ein Tag mit Spotify/Apple Music parallel.
- Ein Tag mit laengerem Offline-Abschnitt (Flugmodus).

## Tagesmatrix (7 Tage)

| Tag | Fokus | Pflichtfaelle |
|---|---|---|
| 1 | Baseline | Hands-free Session, Dashboard KPI, Reminder-Planung pruefen |
| 2 | Reminder-Stabilitaet | Mehrfach Settings speichern, keine Duplikate, naechster Reminder korrekt |
| 3 | Audio/Musik | Alle Feedback-Modi + externe Musik parallel |
| 4 | Offline/Sync | Training + Settings offline, Reconnect, Queue drain auf 0 |
| 5 | Mitternacht/Zeitzone | Session vor/nach Tagesgrenze, KPI und Reminder korrekt |
| 6 | App-Lifecycle | Hintergrund/Foreground, App-Neustart, Zustand bleibt konsistent |
| 7 | Belastungstag | Mehrere Trainings + Settings-Wechsel + Reconnect in einem Tag |

## Protokoll je Testlauf
- Datum/Uhrzeit:
- Device/OS:
- Build/Commit:
- Testfall-ID:
- Ergebnis: PASS/FAIL
- Beobachtung:
- Evidenz (Screenshot/Video/Log):

## Harte Abbruchkriterien
- Duplicate Reminder.
- Datenverlust nach Offline-Phase.
- KPI-Inkonsistenz (`Heute`, `Diese Woche`, `Streak`, `Tag x/28`).
- Crash/Freeze in Training oder Dashboard.

## Abschlusskriterien Long Test Phase
- 7 Tage ohne kritischen Blocker.
- Keine offenen P0/P1 Bugs in Reminder, Offline/Sync, Dashboard, Audio/Haptik.
- `make long-test-ready` am letzten Tag weiterhin gruen.
