# Immersive Training Redesign — Design Spec

**Datum:** 2026-04-22  
**Status:** Approved  

---

## Überblick

Das Training-System wird zu einer vollständig hands-free, immersiven Erfahrung umgebaut. Kern der Änderung: ein Metronom-System (Beat je Sekunde), ein dunkler Vollbild-Screen mit Pendel-Visualisierung, und ein Auto-Advance-Flow der beide Modi (Tutorial + Routine) trägt.

---

## 1. Übungs-Standard & Beat-System

### Repetitions-Standard
- **Standard:** 6 Wiederholungen × 7 Sekunden
- **Ausnahme:** Manche Übungen haben 3 Wiederholungen × 7 Sekunden
- Die Rep-Anzahl ist **fest pro Übung** im Feld `exercise.repetitions` gespeichert (Supabase + Drift). Aktuell: Moro 1–5 = 3 Reps, alle anderen = 6 Reps.
- `ImmersiveExerciseWidget` und `MetronomeService` lesen **immer** `exercise.repetitions` — niemals einen hardcodierten Wert.
- Die Rep-Segmente im Screen passen sich automatisch an: 3 Segmente bei 3-Rep-Übungen, 6 bei Standard.
- `halfwaySwitch` gilt nur bei 6 Reps (nach Rep 3). Bei 3-Rep-Übungen wird kein Switch ausgelöst, auch wenn das Flag gesetzt wäre.
- Pause zwischen Reps: **3 Sekunden** (kein Beat, kein Ton)

### Metronom (Beat-System)
- **Default:** 1 Schlag pro Sekunde → 7 Schläge pro Rep
- **Einstellbar:** Tempo in 0.5s-Schritten (langsamer = mehr Sekunden pro Schlag = längere Reps)
- Das Tempo-Setting verändert die **Rep-Dauer**, nicht die Schlag-Anzahl. Schläge bleiben immer 7 pro Rep.
- Tempo wird pro Übung persistent gespeichert (AdaptiveTempoSettings — bereits vorhanden)

### Audio pro Übungstyp
| Typ | Beat-Sound | Zusatz-Sound |
|---|---|---|
| `holdRest` | `rhythm_arrive.wav` je Sekunde während Hold | `rhythm_hold_end.wav` am Rep-Ende |
| `phased` | `rhythm_arrive.wav` je Sekunde durch alle Phasen | `rhythm_hold_end.wav` bei jedem Phasen-Übergang |

Beide Player verwenden `AudioContextConfigFocus.mixWithOthers` (bereits implementiert in `RhythmVisualizer`).

---

## 2. Immersiver Übungsscreen

### Layout (dunkles Vollbild, Portrait)
```
┌─────────────────────────────┐
│ Übung 3 · 7 gesamt  [Modus] │  ← Header, sehr klein
│ ████░░░░░░░░░░░░░░░░░░░░░░  │  ← Session-Fortschrittsbalken
│                             │
│         ●                   │
│        /|  ← Pendel         │
│       / |                   │
│                             │
│           4                 │  ← Beat-Nummer (64px, bold)
│        von 7 Schlägen       │
│          HALTEN             │  ← Cue-Wort (aus holdCueDe/En)
│                             │
│    ██ ██ ▓▓ ░░ ░░ ░░        │  ← 6 Rep-Segmente
│      Körperschaukeln        │  ← Übungsname klein
│                             │
│  [−]  1.0s / Schlag  [+]   │  ← Tempo-Steuerung
│  [♫ Musik]  [🔇]  [⏸]     │  ← Quick Controls
└─────────────────────────────┘
```

### Pendel-Animation
- Schwingt links ↔ rechts synchron zum Beat-Interval
- Während Pause: bleibt leicht gedämpft, halb sichtbar
- Bob: leuchtend mit Glow-Effekt (`#a5b4fc` / Indigo)

### Zustände
| Zustand | Beat-Zahl | Cue-Wort | Pendel | Rep-Seg |
|---|---|---|---|---|
| Aktive Rep | 1–7, animiert | `holdCueDe` | aktiv | aktuell animiert |
| Pause (3s) | Countdown 3-2-1, gedimmt | „Pause..." | gedämpft | abgeschlossen → filled |
| HalfwaySwitch | — | „Wechsel!" | kurz aufleuchten | — |

### Controls (immer sichtbar)
- **Tempo −/+**: 0.5s Schritte, deaktiviert an Min/Max
- **Musik**: zeigt ob Musik aktiv (grün = an). Öffnet Musik-Picker als Bottom Sheet.
- **Stumm**: wechselt Feedback-Modus (voiceAndCues → hapticOnly → silent)
- **Pause**: pausiert Metronom + Animation

### Ganzer Screen als Tap-Zone (Routine-Modus, nur Übergangs-Screen)
Während der laufenden Übung läuft alles automatisch — kein Tap nötig oder erwartet.
Auf dem **Übergangs-Screen** im Routine-Modus: ganzer Screen = Tap-Zone → überspringt den Countdown und startet die nächste Übung sofort. Die Controls (Tempo, Musik, Pause) bleiben immer tappable.

---

## 3. Session-Flow

### Start
- Einmaliger Tap (ganzer Screen) startet die Session
- Keine weiteren Interaktionen nötig im Routine-Modus

### Ablauf (pro Übung)
```
Rep 1: Beat 1 → 2 → 3 → 4 → 5 → 6 → 7
       3s Pause (kein Beat)
Rep 2–6: identisch, automatisch
→ Übergangs-Screen
→ nächste Übung
```

### Halbzeit-Wechsel (`halfwaySwitch: true`)
Nach Rep 3 (bei 6 Reps): kurze visuelle/haptische Ansage „Wechsel" / „Switch", dann weiter mit Rep 4.

---

## 4. Übergangs-Screen (zwischen Übungen)

### Inhalt (identisch für beide Modi)
- Großes Übungsbild (nächste Übung)
- Übungsname + Nummer (z.B. „Übung 4 von 7")
- Chips: Wiederholungen, Sekunden pro Rep
- Positions-Anweisungen (Bullet-Liste)
- Bewegungsanweisungen (Bullet-Liste)
- Ausführungsguide (kursiv, hervorgehoben)

### Modi-Unterschied
| | Routine | Tutorial |
|---|---|---|
| Trigger | Countdown (10s default) → auto | Button „Übung starten" |
| Tap-Zone | Ganzer Screen überspringt Countdown | — |
| Countdown | Sichtbar als Ring | Nicht vorhanden |

### Übergangs-Dauer
- Default: **10 Sekunden**
- Einstellbar in Settings (5s / 10s / 15s / 20s)

---

## 5. Musik-Integration

### System-Musik (eigene Musik)
- Bereits funktionsfähig durch `AudioContextConfigFocus.mixWithOthers`
- User spielt Spotify/Apple Music etc. → App-Töne mischen sich darunter
- Im Screen: „♫ Musik"-Button zeigt Status, kein weiteres Setup nötig

### In-App Musik
- Kleine Bibliothek an Ambient-Tracks (3–5 Tracks, gebündelt als Assets)
- Bottom Sheet: Track-Liste, Play/Pause, Lautstärke
- Läuft ebenfalls mit `mixWithOthers` → kombinierbar mit Metronom-Tönen
- Auswahl wird persistent gespeichert

### Musik-Picker Bottom Sheet
```
┌─────────────────────────────┐
│ Musik                       │
│ ○ Aus                       │
│ ● Ambient Flow    ▶ [====]  │
│ ○ Stille Natur              │
│ ○ Tiefe Töne                │
│ ─────────────────────────── │
│ Eigene Musik: aktiv ✓       │
└─────────────────────────────┘
```

---

## 6. Architektur

### Neue Komponenten
| Komponente | Typ | Aufgabe |
|---|---|---|
| `ImmersiveSessionScreen` | Widget | Outer shell, verwaltet kompletten Session-Loop |
| `ImmersiveExerciseWidget` | Widget | Dunkler Screen mit Pendel, Beat, Reps |
| `ExerciseTransitionWidget` | Widget | Übergangs-Screen (Bild + Info + Countdown/Button) |
| `MetronomeService` | Service | Beat-Timer, Audio-Playback, Tempo-Management |
| `InAppMusicService` | Service | Ambient-Track Playback mit mixWithOthers |
| `PendulumAnimationWidget` | Widget | Pendel-Animation, synchron zu Beat-Interval |
| `MusicPickerSheet` | Widget | Bottom Sheet für Musik-Auswahl |

### Bestehende Komponenten (wiederverwendet)
| Komponente | Verwendung |
|---|---|
| `TrainingFlowNotifier` | Bleibt als State-Source für Übungsfolge |
| `AdaptiveTempoSettings` | Tempo-Persistierung pro Übung |
| `TrainingFeedbackSettings` | Feedback-Modus (silent/haptic/voice) |
| `HandsfreeSetupSettings` | Default-Tempo |
| `RhythmVisualizer` | Wird durch `ImmersiveExerciseWidget` + `PendulumAnimationWidget` abgelöst |
| `TrainingExerciseScreen` | Wird durch `ImmersiveExerciseWidget` (innerhalb `ImmersiveSessionScreen`) ersetzt |
| `TrainingSessionScreen` | Leitet in `ImmersiveSessionScreen` weiter statt eigenen Step-Flow zu verwalten |

### Session-Loop in `ImmersiveSessionScreen`
```
startSession()
  └─ for each exercise:
       showTransition(exercise) → await tap or countdown
       runExercise(exercise):
         for each rep:
           MetronomeService.startRep() → 7 beats (1/s)
           await repComplete
           if halfwaySwitch && rep == 3: announceSwitch()
           await 3s pause
       exerciseComplete()
  └─ showOutro()
```

### `MetronomeService` API
```dart
class MetronomeService {
  final double tempoSeconds;         // Sekunden pro Schlag (default 1.0)
  Stream<int> get beatStream;        // 1..N (N = exercise.repetitions × 7)
  Stream<int> get repIndexStream;    // aktueller Rep-Index (0-basiert)
  Stream<void> get repComplete;      // nach jedem Rep + 3s Pause
  Stream<void> get allRepsComplete;  // nach allen Reps der Übung
  Stream<void> get phaseTransition;  // für phased exercises: Phasen-Wechsel

  // Startet einen kompletten Übungs-Durchlauf (alle exercise.repetitions Reps)
  Future<void> startExercise(Exercise ex);
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}
```

### Einstellungen (Settings)
Neue Keys in `SharedPreferences`:
- `training_transition_duration_seconds` (int, default: 10)
- `training_in_app_music_track` (String?, null = aus)
- `training_in_app_music_volume` (double, default: 0.7)

---

## 7. Nicht im Scope

- Video-Tutorial-Flow (bleibt vorerst unverändert oder wird separat designt)
- Änderung der Übungsdaten (Reps, Phasendauern) — nur der Screen ändert sich
- Neue Übungspakete
- Online-Streaming für Musik
