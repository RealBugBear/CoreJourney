# Mood Tracking Roadmap (Training + Paketverlauf)

Status: Draft v1 (2026-02-25)  
Owner: Product + Mobile Engineering  
Scope: Self-reported feeling tracking across sessions, packages, and full user history

## 1) Ziel

Ein leichtgewichtiges System einführen, mit dem Nutzer nach jedem Training kurz ihr Befinden erfassen können.  
Die Entwicklung soll sichtbar werden:
1. pro Trainingspaket
2. über die gesamte Nutzungszeit

Wichtig:
1. Post-Training Prompt soll schnell und klein sein.
2. Erfassung ist überspringbar.
3. Notizen sind jederzeit möglich und unbegrenzt pro Tag.

## 2) Produktentscheidungen (fest)

1. Skala:
- 1 bis 5

2. Kernwerte (v1):
- Stimmung
- Energie
- Stress

3. Erfassung:
- Prompt direkt nach Training
- überspringbar
- optionaler Freitext

4. Notizen:
- jederzeit möglich
- keine Begrenzung pro Tag
- sichtbar in Paket- und Gesamtübersicht

5. Visualisierung:
- freie Dashboard-Fläche für Graph
- pro Metrik eine Linie
- Fläche unter jeder Linie gefüllt (area chart)

6. Erinnerungen:
- in v1 keine separaten Reminder

## 3) Zusätzliche sinnvolle Werte (optional, v2)

Wenn später erweitert werden soll, passen fachlich gut:
1. Körperruhe / innere Unruhe
2. Fokus / Konzentration
3. Körperliches Wohlgefühl (somatisch)
4. Schlafqualität (rückblickend)

Empfehlung:
1. v1 bewusst bei 3 Werten halten (Stimmung, Energie, Stress).
2. v2 optional 1 Zusatzwert als Test, um UX nicht zu überladen.

## 4) UX-Flow

## 4.1 Nach dem Training (Micro Prompt)
1. Sheet/Dialog nach Abschluss.
2. Sehr kurze UI:
- 3 Reihen mit 1-5 Auswahl
- optionales Notizfeld
- Primär: `Speichern`
- Sekundär: `Überspringen`

Designregel:
1. in < 10 Sekunden ausfüllbar.
2. nicht als „Pflichtformular“ wirken.

## 4.2 Notizen jederzeit
Entry Points:
1. Dashboard: kleine Aktion `Notiz hinzufügen`
2. Paketübersicht: `Notiz für heute`

Notiztyp:
1. optional mit oder ohne Werte (reine Tagesnotiz erlaubt)

## 4.3 Einsicht
1. Dashboard: kompakter Verlauf (letzte 14/30 Tage)
2. Paketansicht: Verlauf nur für aktives/gewähltes Paket
3. Notizliste:
- chronologisch
- Tap auf Punkt im Graph zeigt zugehörige Notizen/Scores

## 5) Datenmodell (v1)

## 5.1 Mood Check-in
Entity: `MoodCheckin`
1. `id`
2. `userId`
3. `sessionId` (nullable, falls manuell ohne Session)
4. `packageId`
5. `recordedAt`
6. `mood` (1..5)
7. `energy` (1..5)
8. `stress` (1..5)
9. `note` (optional)
10. `source` (`post_training_prompt` | `manual_note`)
11. `needsSync`
12. `firestoreId`

## 5.2 Tagesnotizen (optional separate entity)
Falls technisch einfacher, kann `MoodCheckin` auch reine Notizen tragen.  
Alternative entity nur wenn nötig:
1. `DailyNote`
2. `userId`
3. `packageId`
4. `createdAt`
5. `text`
6. `needsSync`

Empfehlung v1:
1. Ein gemeinsames Modell `MoodCheckin` reicht.
2. Für reine Notiz `mood/energy/stress` nullable erlauben.

## 6) Auswertung / Graph-Logik

## 6.1 Zeitbereiche
1. 14 Tage
2. 30 Tage
3. Paket gesamt
4. Gesamtzeit

## 6.2 Darstellung
1. Drei Linien:
- Stimmung
- Energie
- Stress
2. Unter jeder Linie gefüllte Fläche (transparente Area)
3. Y-Achse fix 1..5
4. X-Achse Datum

## 6.3 Aggregation
Wenn mehrere Einträge pro Tag:
1. Tagesmittel pro Metrik bilden
2. Notizindikator anzeigen, wenn an dem Tag Notizen vorliegen

## 6.4 KPI-Zusatz (klein)
1. `Ø Stimmung`
2. `Ø Energie`
3. `Ø Stress`
4. Delta Start vs letzte 7 Tage (optional v1.1)

## 7) Implementierungsphasen

## Phase A - Daten & Backend-Schnittstellen
1. Isar-Modell + Migration
2. Repository + CRUD
3. Sync-Jobs für MoodCheckins
4. Query-Funktionen:
- by range
- by package
- latest by day

Abnahme:
1. Check-ins werden lokal + remote zuverlässig gespeichert.

## Phase B - Post-Training Prompt
1. Prompt nach Training-Outro integrieren
2. `Speichern` und `Überspringen`
3. Event-Tracking:
- `mood_prompt_shown`
- `mood_prompt_submitted`
- `mood_prompt_skipped`

Abnahme:
1. Prompt erscheint stabil nach Abschluss.
2. Überspringen blockiert den Flow nicht.

## Phase C - Dashboard Graph (freie Fläche)
1. Area-Line Chart mit 3 Metriken
2. Toggle: `Paket` / `Gesamt`
3. Range-Switch: 14/30 Tage
4. Notizmarker + Detail-Preview

Abnahme:
1. Graph ist performant und verständlich.
2. Werte und Notizen sind pro Scope korrekt gefiltert.

## Phase D - Notizen jederzeit
1. Quick-Add Notiz-Entry auf Dashboard
2. Notizliste in Paket-/Gesamtansicht
3. Tagesgruppierung

Abnahme:
1. Unbegrenzte Notizen/Tag funktionieren.
2. Notizen sind in beiden Übersichten sichtbar.

## 8) UX-Risiken & Gegenmaßnahmen

1. Zu viele Eingaben nach Training
- Gegenmaßnahme: super-kurzes Layout, Standardwerte vermeiden, Skip prominent.

2. Graph wirkt überladen
- Gegenmaßnahme: klare Farbcodierung + simple Legende + weniger Nebeninfos.

3. Inkonsistente Daten bei mehreren Einträgen/Tag
- Gegenmaßnahme: feste Aggregationsregel (Tagesmittel), Notizindikatoren separat.

## 9) Definition of Done (v1)

1. Nach jedem Training erscheint ein überspringbarer 3-Werte-Prompt.
2. Nutzer kann jederzeit freie Notizen hinzufügen (ohne Limit pro Tag).
3. Dashboard zeigt Area-Graph für Stimmung/Energie/Stress.
4. Umschaltbar zwischen Paketverlauf und Gesamtverlauf.
5. Notizen sind im Paket- und Gesamtkontext einsehbar.
6. Keine Reminder-Abhängigkeit in v1.
