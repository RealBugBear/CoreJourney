# CoreJourney Hands-Free UX Roadmap

Status: In Progress (Updated: 2026-02-24)  
Scope: iOS first, then Android parity  
Owner: Product + Mobile Engineering

## 0) Aktueller Umsetzungsstand (2026-02-24)

Bereits umgesetzt:
1. P0.3 Temporegler erweitert:
- Fruehe Uebungen: 1-7s.
- Spaete Uebungen: 2-12s.
- 0.5s Schritte + Anzeige des aktuellen Werts.
- Millisekunden-genaue Intervalle statt Ganzzahl-Sekunden-Rundung.
2. P0.2 Voice verbessert:
- Ruhigere TTS-Defaults (Rate/Pitch/Volume reduziert).
- Inline Voice Toggle im Trainingsscreen: Stimme / Haptik / Stumm.
3. Startinteraktion im Exercise-Flow vereinfacht:
- Visualizer starten automatisch.
- Bedienung als klare Pause/Weiter/Neu-starten-Buttons.
4. Startfluss fuer Hands-free vereinfacht:
- Modus-Toggle auf der ersten Seite (Dashboard): Direkt starten / Tutorial.
- Direktstart springt ohne "Willkommen"-Screen direkt in Uebung 1.
- Auswahl wird persistiert und beim naechsten Start wiederverwendet.
5. One-Hand Bedienbarkeit verbessert:
- Primäre CTA-Buttons deutlich vergroessert (Dashboard/Start/Uebung).
- Uebungs-Abschlussbutton ist unten fix und ohne Scrollen direkt tappbar.
6. P1.2 begonnen:
- Reduzierte In-Session-Control-Bar im Uebungs-Screen (Langsamer, Schneller, Feedback-Wechsel) als grosse Touchflaechen.
7. P1.2 Feinschliff umgesetzt:
- Quick-Control-Buttons im Uebungs-Screen vergroessert und haptisch bestaetigt.
- Bedienhinweis fuer One-Tap-Anpassungen ergaenzt.
8. P1.1 Setup Sheet implementiert:
- Einmaliger Hands-free Setup Sheet vor dem ersten Trainingsstart.
- Konfigurierbar: Startmodus, Feedbackmodus, Starttempo.
- Persistenz aktiv und Starttempo wird in Uebungsscreen uebernommen.

Offen (naechster Fokus):
1. P1.2 Alltagstest auf realen Sessions (Label/Ikonographie ggf. nachschleifen).
2. P1.1 Feinschliff: Setup-Sheet bei Bedarf erneut aus Settings aufrufbar machen.
3. P0.1 Fine-Tuning: Tutorial-Flow optionale kuerzere Variante.

Update:
1. P1.1 Feinschliff umgesetzt:
- Hands-free Setup ist nun aus den Settings erneut aufrufbar.
2. P0.1 Fine-Tuning umgesetzt:
- Option "Tutorial kompakt" in Settings eingefuehrt.
- Kompakter Tutorial-Flow ueberspringt den Positionsscreen.
3. P1.3 umgesetzt:
- Voice Presets in Settings: Sanft / Neutral / Dynamisch.
- Presets wirken direkt auf TTS-Rate, Pitch und Lautstaerke im Trainingsfeedback.
4. TASK-A3 / TASK-D3 teilweise umgesetzt:
- Analytics-Events fuer Start-Funnel implementiert:
  - `training_start_tap`
  - `training_first_exercise_entered` inkl. `time_to_first_exercise_ms`
5. TASK-D1 umgesetzt:
- Manuelle Hands-free Testcheckliste erstellt:
  `docs/HANDSFREE_MANUAL_TEST_CHECKLIST.md`
6. TASK-D2 umgesetzt:
- Automatisierte Regression-Tests hinzugefuegt:
  - `test/features/training/training_flow_provider_test.dart`
  - `test/core/training/training_tempo_defaults_test.dart`
7. TASK-D3 umgesetzt:
- Funnel-Review-Guide erstellt:
  `docs/HANDSFREE_FUNNEL_REVIEW_GUIDE.md`
8. P2.1 (v1) umgesetzt:
- Adaptives Tempo pro Uebung (letztes genutztes Tempo wird gespeichert und als Startvorschlag wiederverwendet).
- Sichere Min/Max-Clamps bleiben aktiv.
9. P2.2 umgesetzt:
- Personalisierte Stimmenauswahl in Settings (deutsche verfuegbare Stimmen vom Geraet).
- Auswahl wird gespeichert und fuer Training-Feedback verwendet.
10. P2.3 (v1) umgesetzt:
- Accessibility-Basis im Trainingsflow erweitert (VoiceOver/TalkBack Labels fuer Fortschritt und Hauptaktionen).
- CTA-Buttons in Intro/Position/Movement/Exercise/Outro Dynamic-Type robuster gemacht (scale-down statt Text-Clipping).
- Tempo- und Feedback-Wechsel kuendigen Status zusaetzlich per Accessibility-Announcement an.

P0.1 Status:
1. Kernziel erreicht:
- Direktstart-Flow ist als primaerer Pfad verankert und startet ohne Intro direkt in Uebung 1.
2. Tutorial bleibt als alternativer Pfad aktiv:
- Fuer Nutzer, die Positions-/Bewegungsdetails brauchen.

## 1) Problem Summary (Current Pain)

Aktuelle Nutzerprobleme im Hands-free Training:

1. Einstieg ist nicht smooth:
- Start wirkt schwer auffindbar/zu klein im Gesamtablauf.
- Zu viele Schritte bis zur eigentlichen Uebung.

2. Voice Experience wirkt unangenehm:
- Aktuelle TTS-Stimme/Prosodie wird als unruhig/unangenehm empfunden.
- Kein schneller Weg, die Stimme sofort zu wechseln oder auszuschalten.

3. Bewegungsanimation ist zu langsam:
- Tempo-Regler ist derzeit zu restriktiv.
- Fuer fruehe Uebungen ist nur 3-7s moeglich, spaetere 6-12s.
- Nutzer will auch unter 3s trainieren koennen.

Relevante aktuelle Stellen im Code:
- TTS Setup: `lib/features/training/presentation/services/training_feedback_service.dart`
- Tempo-Slider + Limits: `lib/features/training/presentation/screens/training_exercise_screen.dart`
- Intro/Preparation Einstieg:  
  `lib/features/training/presentation/screens/training_intro_screen.dart`  
  `lib/features/training/presentation/screens/training_preparation_screen.dart`

---

## 2) Product Goals

1. Hands-free Start in < 5 Sekunden bis zur ersten Bewegung.
2. Voice muss sich "ruhig, freundlich, unaufdringlich" anfuehlen.
3. Trainingsgeschwindigkeit muss fuer Fortgeschrittene deutlich schneller sein.
4. Wichtige Einstellungen muessen direkt im Flow erreichbar sein (ohne Settings-Screen-Wechsel).

---

## 3) Roadmap in Phasen

## Phase 0 - Sofortverbesserungen (1-2 Sessions)

### P0.1 Startfluss vereinfachen
Ziel:
- Nutzer soll mit einem klaren Primary CTA direkt starten koennen.

Loesungsansatz:
1. "Schnellstart"-Variante einfuehren:
- Tap auf Training startet direkt in `Routine` ohne Zwischenschritt-Orgie.
2. CTA visuell priorisieren:
- Hoehere Button-Hoehe, klarerer Labeltext, sticky Position am unteren Bildschirmrand.
3. Optional: "Direkt starten" als Default, "Details ansehen" als Secondary Action.

Akzeptanz:
- Time-to-first-exercise sinkt messbar.
- Kein Suchmoment fuer Startbutton in User-Test (5/5 finden Start sofort).

### P0.2 Voice sofort angenehmer machen
Ziel:
- Erste 10 Sekunden des Trainings fuehlen sich beruhigend an.

Loesungsansatz:
1. TTS-Defaults feinjustieren:
- SpeechRate reduzieren/variabel machen.
- Optional Pitch minimal absenken.
2. "Voice quick toggle" im Trainingsflow:
- Voice / nur Haptik / stumm als Inline-Schnellschalter.
3. "Stimme testen"-Button im Settings-Bereich.

Akzeptanz:
- Keine negativen Erstreaktionen auf Voice in Schnelltest.
- Nutzer kann in < 2 Taps Voice deaktivieren/wechseln.

### P0.3 Temporegler erweitern (wichtig)
Ziel:
- Fortgeschrittene koennen schneller als 3s trainieren.

Loesungsansatz:
1. Reglergrenzen neu definieren:
- Fruehe Uebungen: 1-7s (statt 3-7s)
- Spaete Uebungen: 2-12s (statt 6-12s)
2. Optional "Pro-Modus":
- 0.5s Schritte statt nur ganze Sekunden.
3. Safety-Hinweis bei sehr schnellen Werten:
- Kurzer Hinweistext statt Hard-Block.

Akzeptanz:
- Nutzer kann <= 2s einstellen.
- Animation und Audio/Haptik bleiben synchron/stabil.

---

## Phase 1 - UX-Haertung (2-4 Sessions)

### P1.1 Onboarding fuer Hands-free
Loesungsansatz:
1. Einmaliger "Hands-free Setup Sheet" vor erstem Start:
- Audio-Modus waehlen
- Starttempo waehlen
- "Direktstart aktivieren" toggle
2. Einstellungen persistieren und beim naechsten Training auto-anwenden.

### P1.2 In-Session Controls (minimal, gross, sicher)
Loesungsansatz:
1. Bottom Control Bar:
- Pause/Weiter
- Tempo +/- (groeere Hit-Areas)
- Voice Mode toggle
2. Touch-Ziele mindestens 44-48 px.

### P1.3 Voice Presets statt nur technischer Werte
Loesungsansatz:
1. Voreinstellungen:
- "Sanft", "Neutral", "Dynamisch"
2. Mapping auf TTS-Parameter intern.
3. Nutzer sieht nur Presets, nicht komplexe Technikwerte.

---

## Phase 2 - Erweiterte Verbesserungen (nach Stabilisierung)

### P2.1 Adaptives Tempo
Loesungsansatz:
1. Vorschlag je Uebung basierend auf letztem erfolgreichen Training.
2. Keine automatische Tempo-Erhoehung; Tempo bleibt voll nutzergesteuert.

### P2.2 Personalisierte Voice
Loesungsansatz:
1. Wenn Plattform mehrere Stimmen anbietet:
- "Stimme A/B" Auswahl in Settings.
2. Sprachstil pro Trainingsmodus.

### P2.3 Accessibility + Friktionsfreiheit
Loesungsansatz:
1. Dynamic Type robust.
2. VoiceOver/TalkBack klare Labels fuer Start und Tempo.
3. Haptik-Only Flow ohne Audio voll nutzbar.

---

## 4) Konkreter Implementierungs-Backlog

## Epic A - Start UX
1. TASK-A1: Schnellstart-CTA auf Dashboard/Startscreen priorisieren.
2. TASK-A2: Intro optional ueberspringen ("Direkt starten").
3. TASK-A3: UI-Tracking fuer Start Funnel (tap -> first exercise).

## Epic B - Voice UX
1. TASK-B1: TTS Defaults ueberarbeiten (`training_feedback_service.dart`).
2. TASK-B2: Inline Voice Toggle in Training Screen.
3. TASK-B3: Voice-Test in Settings einbauen. (Erledigt)

## Epic C - Tempo UX
1. TASK-C1: Slider-Limits auf 1-7s bzw. 2-12s anpassen.
2. TASK-C2: Optional Pro-Modus (0.5s Schritte) hinter Feature Flag.
3. TASK-C3: Guardrails + Hinweistext bei Hochtempo. (Erledigt, nicht-blockierend)

## Epic D - QA und Messung
1. TASK-D1: Manual Testfaelle fuer Start/Voice/Tempo ergaenzen. (Erledigt)
2. TASK-D2: Regression tests fuer neue Tempo-Grenzen und Mapping. (Erledigt)
3. TASK-D3: Nutzungsmetriken fuer Drop-off vor erster Uebung erfassen. (Erledigt)

---

## 5) Messbare Erfolgsmetriken

Primary Metrics:
1. Median Time-to-first-exercise: Ziel < 5s
2. Start-Abbruchrate vor Uebung 1: Ziel -30%
3. Anteil Sessions mit Tempo <= 2s (Power User): Ziel > 20%

Secondary Metrics:
1. Voice-off Umschaltung in den ersten 30s (als Unzufriedenheits-Signal)
2. Completion Rate Uebung 1 -> Uebung 7
3. Qualitatives Feedback: "Start war einfach", "Voice angenehm"

---

## 6) Risiken und Gegenmassnahmen

1. Zu schnelles Tempo verschlechtert Uebungsqualitaet:
- Gegenmassnahme: Hinweis + optionale empfohlene Bereiche.

2. Zu viele Inline Controls machen UI unruhig:
- Gegenmassnahme: nur 3 Kernaktionen im Flow, Rest in Settings.

3. Audio/Haptik Sync bricht bei sehr schnellen Werten:
- Gegenmassnahme: technische Untergrenze validieren, automatische Fallbacks.

---

## 7) Reihenfolge fuer die naechsten Sessions

Empfohlene Abarbeitung:
1. Session 1: P0.3 Tempo erweitern + Basis-QA
2. Session 2: P0.2 Voice Defaults + Inline Toggle
3. Session 3: P0.1 Startfluss vereinfachen
4. Session 4: P1.2 In-Session Controls
5. Session 5: P1.1 Setup Sheet + Persistenz

---

## 8) Definition of Done (Roadmap Step)

Ein Schritt gilt als fertig, wenn:
1. UX-Aenderung implementiert ist,
2. manuelle iOS-Pruefung bestanden ist,
3. keine Regression in Training Completion/Reminder/Sync sichtbar ist,
4. relevante Tracking-Events feuern.
