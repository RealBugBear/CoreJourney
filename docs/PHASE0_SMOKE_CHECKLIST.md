# CoreJourney Phase 0 Smoke Checklist (iOS Stabilisierung)

Zweck: Schnelle, reproduzierbare Validierung der Stabilitaetsziele aus Roadmap v0.1 vor jedem RC.

## Voraussetzungen
- iOS Testgeraet mit aktivierten Notifications.
- Build mit aktuellem Branch-Stand.
- Reminder in Settings aktiviert.
- Netzwerk fuer Online/Offline-Tests umschaltbar.

## Testfaelle

| ID | Bereich | Schrittfolge | Erwartung |
|---|---|---|---|
| P0-01 | Reminder (Single) | Reminder aktivieren, Einstellungen mehrfach speichern | Es bleibt genau **1** geplanter Reminder, keine Duplikate |
| P0-02 | Trainingsabschluss sichtbar | Training abschliessen, direkt Dashboard ansehen | `Heute` ist sofort `Erledigt`, KPI aktualisiert ohne Neustart |
| P0-03 | App-Neustart nach Abschluss | Training abschliessen, App komplett schliessen/neu oeffnen | Dashboard bleibt konsistent (`Heute`, `Diese Woche`, `Streak`) |
| P0-04 | Mitternacht-Edge | Training kurz vor Mitternacht abschliessen, nach Mitternacht erneut pruefen | Tageswechsel korrekt, keine doppelte Zaehlung, Reminder logisch verschoben |
| P0-05 | Offline-Abschluss | Flugmodus an, Training abschliessen, Dashboard pruefen | Abschluss lokal sichtbar, keine Crashs/Inkonsistenzen |
| P0-06 | Reconnect-Sync | Nach P0-05 online gehen, Sync beobachten | Queue drain auf 0, Daten bleiben konsistent |
| P0-07 | Reminder nach Aktivitaet | Heute trainieren, Reminder-Status pruefen | Reminder auf naechsten Tag (keine Spam-Planung am selben Tag) |
| P0-08 | Quiet Hours | Quiet Hours setzen, Reminderfenster ueberlappt Quiet Hours | Reminder wird fuer ueberlappendes Fenster nicht geplant |

## Exit-Kriterien (Phase 0)
- Alle P0-Checks `PASS`.
- `make release-readiness-mobile` ist gruen.
- Kein Blocker in Reminder-, Dashboard- oder Offline/Sync-Verhalten.

## Logging-Hinweise
- Bei FAIL immer erfassen:
  - Build/Commit
  - Device + iOS Version
  - exakter Zeitpunkt (inkl. Datum/Uhrzeit)
  - Screenshot/Screenrecord + relevante Logs
