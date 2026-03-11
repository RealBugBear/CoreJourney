# CoreJourney Handoff Bug Template

Zweck: Einheitliches Template fuer Bug-Tickets aus der Device-QA (iOS + Android).

## Verwendung
1. Pro Bug ein Ticket anlegen.
2. Pflichtfelder vollstaendig ausfuellen.
3. Cluster korrekt zuordnen:
   - `Reminder-Verhalten`
   - `Audio/Musik`
   - `Offline/Sync`
   - `Dashboard-Konsistenz`
4. Re-Test nach Fix mit Build-Info dokumentieren.

## Ticket-Template (Copy/Paste)

```md
# [Cluster] Kurzer Titel

## Metadaten
- ID: BUG-XXX
- Cluster: Reminder-Verhalten | Audio/Musik | Offline/Sync | Dashboard-Konsistenz
- Prioritaet: P0 | P1 | P2 | P3
- Plattform: iOS | Android
- Device: <z. B. iPhone 15 / Pixel 8>
- OS-Version: <z. B. iOS 18.3 / Android 15>
- App-Build: <Build-Nummer / Commit>
- Gefunden am: <YYYY-MM-DD>
- Gefunden von: <Name>
- Zugehoeriger QA-Case: <z. B. RM-03>

## Kurzbeschreibung
<1-3 Saetze, was falsch ist und warum es relevant ist>

## Preconditions
- <Voraussetzung 1>
- <Voraussetzung 2>

## Schritte zur Reproduktion
1. <Schritt 1>
2. <Schritt 2>
3. <Schritt 3>

## Erwartetes Verhalten
<Soll-Verhalten>

## Tatsachliches Verhalten
<Ist-Verhalten>

## Auswirkungen
- Nutzerwirkung: <hoch/mittel/gering + kurz>
- Release-Risiko: <hoch/mittel/gering + kurz>
- Datenrisiko: <ja/nein + kurz>

## Evidenz
- Screenshot/Video: <Link oder Dateiname>
- Logs/Debug:
  - <relevanter Logauszug 1>
  - <relevanter Logauszug 2>

## Scope-Einschaetzung
- Reproduzierbarkeit: immer | haeufig | sporadisch
- Betrifft auch andere Plattform?: ja | nein | unklar
- Vermutete betroffene Module:
  - <Pfad/Modul 1>
  - <Pfad/Modul 2>

## Fix-Tracking
- Owner: <Name>
- Zielversion: <Milestone/RC>
- Status: Open | In Progress | Fixed | Ready for Re-Test | Closed

## Re-Test
- Re-Test von: <Name>
- Re-Test Datum: <YYYY-MM-DD>
- Re-Test Build: <Build-Nummer / Commit>
- Ergebnis: PASS | FAIL
- Notizen: <optional>
```

## Cluster-spezifische Pflichtchecks

### Reminder-Verhalten
- Cadence dokumentiert (`minimal` oder `balanced`).
- Trainingsstatus am Testtag dokumentiert (heute trainiert: ja/nein).
- Anzahl geplanter Reminder vor/nach Aktion dokumentiert.

### Audio/Musik
- Aktiver Feedback-Modus dokumentiert (`Ton aus`, `Nur Haptik`, `Sprache + Cues + Haptik`).
- Externe Audio-App dokumentiert (z. B. Spotify/Apple Music).
- Zeitpunkt des Konflikts (Start, Uebungswechsel, Abschluss) dokumentiert.

### Offline/Sync
- Netzwerkzustand pro Schritt dokumentiert (online/offline/wechsel).
- Queue-Status dokumentiert (pending count, aeltester Eintrag).
- Datenkonsistenz nach Reconnect dokumentiert.

### Dashboard-Konsistenz
- Vergleichswerte dokumentiert (`Heute`, `Diese Woche`, `Streak`, `Tag x/28`).
- Snapshot-Bezug dokumentiert (welcher Zustand wurde erwartet).
- Sichtbare Abweichung mit Screenshot belegt.

## Definition of Done fuer Bug-Schliessung
- Root Cause adressiert und in Ticket dokumentiert.
- Re-Test auf betroffener Plattform `PASS`.
- Falls relevant: Gegenprobe auf zweiter Plattform erfolgt.
- Kein Regressionseffekt in `make release-readiness-mobile` und manueller Smoke.

## Referenzen
- `/Users/alexandermessinger/dev/corejourney/docs/HANDOFF_QA_MATRIX.md`
- `/Users/alexandermessinger/dev/corejourney/docs/HANDOFF_STATUS.md`
- `/Users/alexandermessinger/dev/corejourney/docs/RELEASE_READINESS_CHECKLIST.md`
