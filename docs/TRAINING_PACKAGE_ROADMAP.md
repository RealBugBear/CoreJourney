# Training Package Expansion Roadmap

Status: Draft v1 (2026-02-24)  
Owner: Product + Mobile Engineering  
Scope: Sequential integration of additional prenatal reflex training packages

## 1) Zielbild

Die App soll mehrere Trainingspakete unterstuetzen, die jeweils einem oder mehreren Reflexen zugeordnet sind.

Regeln:
1. Nutzer starten immer mit Paket 1 (Moro).
2. Pakete werden nacheinander freigeschaltet.
3. Ein Paket gilt als abgeschlossen, wenn das 4-Wochen-Kriterium erreicht ist:
- Ziel: 5 Trainingstage pro Woche.
- Wenn eine Woche unter 3 Trainingstagen liegt, zaehlt die Woche nicht und verlaengert die Paketdauer um 1 Woche.
4. Vor Freischaltung des naechsten Pakets ist ein Abschlussfragebogen fuer das aktuelle Paket Pflicht.
5. Im normalen UI ist nur das aktuell aktive Paket sichtbar.
6. Sonderregel in Settings:
- Nutzer kann jederzeit auf Paket 1 (Moro) wechseln.
- Das aktuell aktive Paket wird dabei pausiert.
- Nach Ende des Moro-Blocks startet das pausierte Paket wieder am Anfang.

## 2) Produktentscheidungen (aus den Anforderungen)

1. Paketmetadaten pro Uebung:
- Name
- Ziel-Reflex
- Dauer
- Wiederholungen
- Positionstext
- Bewegungstext
- Hinweise
- Bild/Animation

2. Trainingsflow:
- Vorerst identisch zum bestehenden Flow (Position -> Bewegung -> Uebung -> Outro).

3. Tempo/Feedback:
- Bestehendes adaptives System bleibt aktiv.
- Adaptive Werte werden pro Paket getrennt gespeichert.

4. Migration:
- Alle Nutzer beginnen bei Paket 1.

5. Naechstes Lieferziel:
- Paket 2 als erstes neues Paket integrieren.

## 3) Technische Leitlinien

Bestehende Assets/Modelle, die wir nutzen:
1. `TrainingSession.exercisePackage` ist bereits vorhanden und geeignet fuer Paketzuordnung.
2. Golden-Day/Week-Tracking-Logik existiert bereits und wird erweitert statt ersetzt.
3. Progress-Service liefert Wochenmetriken und Weekly-Ziele; diese werden fuer Paket-Gating wiederverwendet.

Neue Kernobjekte:
1. `TrainingPackageDefinition`
- id (z. B. `moro_p1`, `package_2_reflex_x`)
- title
- reflexTargets (Liste)
- exerciseIds / exerciseDefinitions
- defaultDurationWeeks (4)
- requiredDaysPerWeek (5)
- minimumValidDaysPerWeek (3)

2. `ActivePackageProgress`
- activePackageId
- pausedPackageId (optional)
- packageStartDate
- qualifiedWeeks
- penaltyWeeks
- currentWeekTrainingDays
- isCompletionQuestionnaireDone
- packageState (`active`, `paused`, `completed`, `locked`)

3. `PackageCompletionQuestionnaire`
- packageId
- submittedAt
- answers (JSON/map)
- score/flags (optional, spaeter)

## 4) Roadmap-Phasen

## Phase A - Domain + Data Foundation

Ziel:
Paketfaehigkeit im Datenmodell und in Progress-Logik herstellen, ohne UI-Bruch.

Tasks:
1. Paketdefinitionen als Konfigurationsquelle einfuehren (P1=Moro, P2 placeholder).
2. `ActivePackageProgress` persistieren (lokal + Sync-Strategie).
3. Bestehende Session-Speicherung an aktives Paket binden (nutzt `exercisePackage`).
4. Adaptive-Tempo-Keys paketbezogen machen (z. B. `adaptive_tempo_<package>_<exercise>`).
5. Golden-Day/Week-Logik fuer Paketabschluss kapseln:
- 4 qualifizierte Wochen benoetigt.
- Wochen unter 3 Tagen erzeugen Penalty-Week.

Abnahme:
1. Trainingssessions werden korrekt dem aktiven Paket zugeordnet.
2. Paketabschluss ist nur ueber Wochenlogik moeglich.
3. Regression im bestehenden Moro-Flow ausgeschlossen.

## Phase B - Paket-Gating + Questionnaire Gate

Ziel:
Saubere Freischaltkette P1 -> Fragebogen -> P2.

Tasks:
1. `canUnlockNextPackage()` Service mit klaren Gruenden:
- `insufficient_qualified_weeks`
- `questionnaire_missing`
- `package_not_completed`
2. Abschlussfragebogen-Flow implementieren:
- Trigger nach Erreichen Paketabschluss.
- Pflichtabschluss vor Paketfreischaltung.
3. Questionnaire-Daten speichern + Sync vorbereiten.
4. Event-Tracking:
- `package_completed`
- `package_questionnaire_started`
- `package_questionnaire_submitted`
- `package_unlocked`

Abnahme:
1. Ohne Fragebogen kein Wechsel zu P2.
2. Mit Fragebogen wird P2 freigeschaltet.
3. Fehlerzustaende sind fuer Nutzer klar erklaert.

## Phase C - UI/UX fuer aktives Paket + Settings-Sonderregel

Ziel:
Nutzer sieht nur aktuelles Paket, kann aber bewusst zu Moro zurueckspringen.

Tasks:
1. Dashboard:
- Zeigt nur aktives Paket + Fortschritt.
- Kein Browse ueber kommende Pakete.
2. Settings:
- Aktion `Zu Paket 1 (Moro) wechseln`.
- Aktion `Aktives Paket pausieren`.
3. Ruecksprung-Logik:
- Beim Wechsel zu Moro wird aktives Paket pausiert.
- Nach Moro-Block Resume des pausierten Pakets am Anfang.
4. Sicherheitsdialoge:
- Hinweis auf Reset des pausierten Pakets.

Abnahme:
1. Sonderregel funktioniert deterministisch.
2. Kein Datenverlust zwischen pausiert/aktiv.
3. UX bleibt one-hand tauglich.

## Phase D - Paket 2 Content Integration

Ziel:
Paket 2 produktiv nutzbar machen.

Tasks:
1. Paket-2-Definition finalisieren:
- Reflexziele
- Uebungsinhalte (Name, Dauer, Wiederholungen, Texte, Hinweise, Assets)
2. Assets einpflegen (Bilder/Animationen).
3. Validierung der Trainingszeiten/Intensitaet gegen bestehende Hands-free Constraints.
4. Manual QA fuer kompletten P2-Zyklus.

Abnahme:
1. P2 ist nach P1+Fragebogen freischaltbar.
2. P2 laeuft ohne Sondercode im bestehenden Trainingsflow.

## 5) Backlog (konkret, umsetzbar)

Prioritaet P0:
1. Domain-Modell fuer `TrainingPackageDefinition` + `ActivePackageProgress`.
2. Paket-Gating-Service mit 4-Wochen-Regel + Penalty-Week.
3. Questionnaire-Pflichtgate.
4. Adaptive-Tempo pro Paket trennen.

Prioritaet P1:
1. Dashboard nur aktives Paket.
2. Settings-Sonderregel fuer Moro-Rueckkehr inkl. Pause/Reset-Logik.
3. Paket-Tracking-Events und Debug-Ansicht.

Prioritaet P2:
1. Paket-2 Content authoring und QA.
2. Erweiterte Analyseberichte pro Paket.

## 6) Teststrategie

Unit-Tests:
1. Wochenqualifikation:
- 5 Tage => qualifiziert.
- 3-4 Tage => qualifiziert (laut Mindestregel >=3).
- 0-2 Tage => nicht qualifiziert + Penalty +1 Woche.
2. Unlock-Logik:
- Paket fertig + Fragebogen fehlt => locked.
- Paket fertig + Fragebogen da => unlock next.
3. Sonderregel:
- Wechsel zu Moro pausiert aktives Paket.
- Nach Moro Ende Restart des pausierten Pakets bei Woche 1/Start.

Integration/Manual:
1. End-to-end P1 -> Fragebogen -> P2.
2. Mid-cycle Pause zu Moro und Rueckkehr.
3. App-Neustart waehrend pausiert/aktiv.
4. Sync-Konfliktfall (falls mehrere Devices spaeter relevant).

## 7) Offene Entscheidungen fuer v2 (nicht blockierend)

1. Fragebogeninhalt und Scoring-Logik (nur Pflicht oder auch Qualitaetsgate?).
2. Ob 3 Tage/Woche als qualifiziert gelten sollen oder nur 5 als qualifiziert:
- Aktuell in dieser Roadmap: Mindestregel >=3 qualifiziert, <3 ungueltig.
3. Ob Moro-Rueckkehr beliebig oft moeglich sein soll oder mit Cooldown.

## 8) Empfohlene Reihenfolge ab jetzt

1. Sprint 1:
- Phase A komplett + Tests.
2. Sprint 2:
- Phase B komplett + Fragebogen-Gate live hinter Feature Flag.
3. Sprint 3:
- Phase C (Settings-Sonderregel + Dashboard-Umbau).
4. Sprint 4:
- Phase D (Paket 2 Content + QA + Release).

## 9) Definition of Done (Package System v1)

1. Jeder Nutzer startet in Paket 1.
2. Paketwechsel nur sequentiell und nur nach Abschluss + Fragebogen.
3. Sonderregel Moro-Rueckkehr funktioniert inkl. Pause/Neustart des aktiven Pakets.
4. Adaptive Tempoeinstellungen sind paketisoliert.
5. P2 ist live und stabil im bestehenden Trainingsflow nutzbar.
