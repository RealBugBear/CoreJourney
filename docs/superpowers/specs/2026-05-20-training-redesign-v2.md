# Training Redesign v2 — Hands-free Audio-driven Sessions + Vorrunde

## Ziel

Ein Trainingserlebnis das vollständig hands-free funktioniert: Nutzer drückt Start, legt das Gerät hin, und wird durch das gesamte Training per Audio geführt — Übungsname, Ausgangsposition, Phasencues, Wechsel. Parallel dazu wird die Vorrunde als empfohlener Einstieg in den Paket-Flow integriert.

---

## Was sich ändert (Approach B — Refactor)

**Neu:**
- `SessionOrchestrator` — saubere State Machine, ersetzt `TrainingFlowProvider` + `ImmersiveSessionScreen`-Logik
- `AudioAnnouncementService` — spielt voraufgenommene Phrasen-Dateien ab (ElevenLabs generiert)
- Vorrunde-Exercises + Interstitial-Screen beim Paket-Auswählen
- Routine-Modus Onboarding-Tipp nach 2. Session

**Unverändert:**
- `MetronomeService`
- `PendulumAnimationWidget`
- `RepSegmentsWidget`
- `InAppMusicService` (nur neue Tracks)
- `TrainingFeedbackService`
- `AdaptiveTempoSettings`
- Datenbank-Schema (nur neue Exercises hinzugefügt)

---

## 1. Vorrunde

### Beschreibung
4-wöchiges tägliches Programm als Vorbereitung für das erste Reflex-Paket (Moro). Bereitet den Körper vor, sodass Reflexe besser aktiviert und verarbeitet werden können. Wird nach dem Vorrunde-Abschluss durch Moro abgelöst — nie parallel.

### Struktur
- 6 Übungen
- Alle: `holdRest` Rhythmus, 6 Reps × 7s Hold + 3s Rest zwischen Reps
- Alle: rhythmisches Schaukeln (`package_id: 'vorrunde'`)

> **TBD:** Die genauen Namen, Positionen und Bewegungsinstruktionen der 6 Vorrunde-Übungen müssen noch inhaltlich definiert werden (durch den Fachexperten). Erst dann können Audio-Phrasen und Assets erstellt werden.

### Solo vs. Duo
Die App erkennt automatisch ob ein Companion-Profil (Kind) vorhanden ist:
- `companionSubjectProfileIds.isNotEmpty` → Duo-Instruktionen (schaukelnde Person)
- Sonst → Solo-Instruktionen (Selbst-Schaukeln)

Gleiche Übungsstruktur, unterschiedliche `positionInstructions`/`movementInstructions` je Version. Im `Exercise`-Modell werden beide Varianten als separate Felder geführt:
- `positionInstructionsDe` (solo)
- `positionInstructionsDuoDe` (duo)
- entsprechend für `movementInstructions` und Audio-Cues

### Positionierung in der App
**Interstitial-Screen** — einmalig beim ersten Tippen auf "Paket auswählen":

```
Nutzer tippt "Paket auswählen"
  └── vorrunde_status == 'unseen'?
       ├── JA  → Vorrunde-Interstitial-Screen
       │          ├── "Jetzt starten" → Vorrunde startet direkt
       │          └── "Überspringen"  → Paketliste
       └── NEIN → direkt zur Paketliste
```

`vorrunde_status` Werte: `unseen` → `started` | `skipped` | `completed`

Der Screen erscheint nur wenn `status == 'unseen'`. Nach Nutzerentscheidung wird sofort `started` oder `skipped` gesetzt. Gespeichert in SharedPreferences.

**Vorrunde-Interstitial Screen Design:**
- Background: `#121212`
- Heading: "Bevor du startest" (subtitle, `#737373`)
- Title: "Vorrunde" (`#EFEFEF`, bold)
- Body: kurze Erklärung (2 Sätze, `#B3B3B3`)
- Primäre Card (border `#009E6B`): "Vorrunde jetzt starten · empfohlen" + "4 Wochen · 6 Übungen täglich · ca. 8 Min."
- Sekundäre Card: "Direkt mit erstem Paket starten" + "Vorrunde kann jederzeit nachgeholt werden"

---

## 2. Trainings-Modi

### Zwei feste Modi — Nutzer wählt beim Session-Start

**Tutorial-Modus:**
- Transition-Screen: Bild + Instruktionstext + optionaler Video-Button + "Bereit"-Button
- Erstes Mal durch ein Paket: Video wird prominent angeboten (kein separater Button nötig)
- Ab dem zweiten Durchlauf: Bild ist Standard, Video nur via Button
- Nutzer drückt "Bereit" → Übung startet
- Übungs-Screen: identisch zu Routine

**Routine-Modus:**
- Vollständig hands-free
- Transition-Screen: Bild + Instruktionstext + 5s Countdown-Ring → startet automatisch
- Audio kündigt jede Übung an bevor der Countdown läuft
- Kein Berühren des Geräts nötig

**Moduswahl:** Toggle auf dem Session-Start-Screen (vor dem ersten Start). Zuletzt gewählter Modus wird gespeichert (`SharedPreferences`).

### Routine-Modus Onboarding-Tipp
Nach der 2. abgeschlossenen Session erscheint einmalig ein Bottom-Sheet auf dem Dashboard:
> "Du kennst die Übungen jetzt — probiere den Routine-Modus für ein komplett hands-free Erlebnis."

Getrackt via `routine_tip_shown: bool` in SharedPreferences. Erscheint exakt einmal.

---

## 3. SessionOrchestrator

Ersetzt die verteilte Logik in `TrainingFlowProvider` und `ImmersiveSessionScreen`. Ist ein Riverpod `Notifier` mit einer sauberen State Machine.

### States

```dart
enum SessionState {
  idle,
  exerciseAnnounce,   // Audio spielt: "[Name]. [Position]."
  exerciseCountdown,  // 5s warten (Routine) oder auf "Bereit" warten (Tutorial)
  exerciseActive,     // MetronomeService läuft
  exerciseDone,       // kurze 2s Pause nach letzter Rep
  sessionComplete,    // alle Übungen fertig
}
```

### Übergänge Routine

```
idle
  → exerciseAnnounce   (AudioAnnouncementService spielt name + position)
  → exerciseCountdown  (5s Timer)
  → exerciseActive     (MetronomeService.start(), allRepsComplete-Stream wartet)
  → exerciseDone       (2s Pause)
  → exerciseAnnounce   (nächste Übung, falls vorhanden)
  → sessionComplete    (Outro-Screen)
```

### Übergänge Tutorial

```
idle
  → exerciseAnnounce   (kein Audio, Transition-Screen zeigt Bild + Bereit-Button)
  → exerciseCountdown  (wartet auf Nutzer-Tap "Bereit")
  → exerciseActive     (MetronomeService.start())
  → exerciseDone       (zurück zu exerciseAnnounce oder sessionComplete)
```

### Pause/Resume im Routine-Modus
Der Nutzer kann jederzeit über den Pause-Button (bereits vorhanden auf `ImmersiveExerciseScreen`) unterbrechen:
- `MetronomeService.pause()` wird aufgerufen
- `AudioAnnouncementService.play('pause.mp3')` spielt ab
- Musik läuft weiter (kein Ducking)
- Resume: `AudioAnnouncementService.play('weiter.mp3')` → `MetronomeService.resume()`

Im Tutorial-Modus identisches Verhalten.

### Audio-Cues während exerciseActive
Der Orchestrator hört auf `MetronomeService`-Streams und triggert `AudioAnnouncementService`:
- `phaseTransition` → spielt `[exercise_id]_phase_[n].mp3`
- `repComplete` mit `hasRepSwitch` → spielt `wechsel.mp3`
- `repComplete` mit `halfwaySwitch` und rep == 3 → spielt `wechsel.mp3`

---

## 4. AudioAnnouncementService

### Verantwortlichkeit
Spielt voraufgenommene MP3-Dateien sequenziell ab. Queue-basiert. Respektiert laufende Musik (Audio Ducking).

### Audio Ducking
Wenn eine Phrase startet: Musik-Volumen in 300ms auf 30% absenken. Nach Ende der Phrase: in 500ms zurück auf Normalvolumen.

### Dateistruktur

```
assets/sounds/announcements/de/
├── session_start.mp3        "Training beginnt."
├── session_complete.mp3     "Training abgeschlossen."
├── wechsel.mp3              "Wechsel."
├── pause.mp3                "Pause."
├── weiter.mp3               "Weiter."
└── exercises/
    ├── [exercise_id]_name.mp3        z.B. "Moro 6."
    ├── [exercise_id]_position.mp3    z.B. "Leg dich auf den Rücken."
    └── [exercise_id]_phase_[n].mp3   z.B. "Hoch." / "Halten." / "Runter."
```

Gesamt: ca. 80–90 kurze Phrasen für alle Pakete inkl. Vorrunde.

### Generierung
Alle Phrasen werden einmalig mit ElevenLabs (oder gleichwertigem Dienst) generiert und als Assets in die App eingebettet. Keine Laufzeit-API-Calls. Vollständig offline.

### API

```dart
class AudioAnnouncementService {
  Future<void> play(String assetKey);   // einzelne Datei
  Future<void> queue(List<String> assetKeys); // mehrere nacheinander
  void stop();
}
```

---

## 5. Video-Integration

### Verhalten
- **Erstes Mal** durch ein Paket (Session 1): Video wird prominent im Transition-Screen angezeigt (kein Button nötig, direktes Widget)
- **Ab Session 2**: Bild ist Standard, Video nur via Button `▶ Video` (rechts unten auf dem Bild)

### Tracking
`first_run_completed_[package_id]: bool` in SharedPreferences. Gesetzt nach Abschluss der ersten Session eines Pakets.

### Screens
- Tutorial-Modus Transition-Screen zeigt das `ExerciseVideoWidget` (bereits vorhanden) beim ersten Durchlauf
- Danach: `ExerciseVideoWidget` nur on-demand via Button sichtbar

---

## 6. Binaurale Musik

### Änderung
Die drei bestehenden Ambient-Tracks (`ambient_flow.mp3`, `stille_natur.mp3`, `tiefe_toene.mp3`) werden durch binaurale Tracks ersetzt.

**Binaurale Musik benötigt Stereo-Kopfhörer** — ein kurzer Hinweis erscheint beim ersten Öffnen des Music Pickers: "Für den vollen Effekt Kopfhörer verwenden."

### Infrastruktur
`InAppMusicService` bleibt unverändert. Nur die Asset-Pfade und Track-Namen in `InAppMusicSettings` werden ausgetauscht. Track-Beschaffung ist eine separate Content-Aufgabe.

---

## 7. Session-Start Screen

### Layout
- Background: `#121212`
- Paket-Name + Übungszahl (subtitle, `#737373`)
- "Training" (heading, `#EFEFEF`)
- Zwei Toggle-Cards nebeneinander: Routine | Tutorial
  - Aktiv: Border `#009E6B`, Text `#009E6B`
  - Inaktiv: Border `#2A2A2A`, Text `#B3B3B3`
- Start-Button: `background #009E6B`, Text weiß

---

## 8. Transition-Screen

### Routine
- Background: `#121212`
- "Nächste Übung" label (`#737373`)
- Übungsname (`#EFEFEF`, bold)
- Übungsuntertitel (`#B3B3B3`)
- Übungsbild (volle Breite, `#1E1E1E` Platzhalter)
- Ausgangspositionstext (`#B3B3B3`)
- Countdown-Ring (`#009E6B`), Zahl darunter "Startet automatisch" (`#737373`)

### Tutorial (zusätzlich)
- Video-Button (`▶ Video`) über dem Bild unten rechts (`#B3B3B3` auf `rgba(0,0,0,0.75)`)
- "Bereit"-Button statt Countdown (`background #009E6B`)
- Erste Session: `ExerciseVideoWidget` direkt eingebettet

---

## Was nicht in diesem Scope ist

- Englische Audio-Dateien (folgt später)
- Neue locked Pakete (Babkin, ATNR, etc.) — Exercises noch nicht erstellt
- Push-Notifications / Erinnerungen
- Apple Watch Integration
- Detaillierte Fortschrittsanalyse der Vorrunde
