# CoreJourney App Structure Plan

Status: Planning baseline
Date: 2026-05-01

## 1. Product Core

CoreJourney is not a fitness tracker.

CoreJourney is a calm companion for integrating persistent early developmental reflex patterns through rhythmic movement over several weeks.

The app should help users:

- understand why reflex integration may be relevant for them
- build a regular rhythm with fixed movement packages
- reflect on body, mood, energy, sleep, and emotional reactions
- see patterns over time without pressure or performance framing
- find professional support for isometric partner exercises
- move through a fixed package sequence with clear transitions

The product feeling should be calm, professional, trustworthy, and human. It should not feel like a workout app, gamified challenge app, or social platform.

## 2. Design Principles

### Desired Feeling

- calm
- safe
- clear
- professional
- therapeutic
- warm without being playful
- structured without feeling clinical

### Color

The existing marketing primary color stays fixed.

Use the primary color sparingly:

- primary actions
- active navigation
- selected states
- subtle accents
- important progress markers

Avoid using the primary color everywhere. The app should rely on neutral surfaces, quiet spacing, and clear hierarchy.

### UI Direction

Prefer:

- clean sections
- compact but readable cards
- subtle dividers
- calm graphs
- clear status chips
- stable layouts
- simple line icons
- short, direct text

Avoid:

- trophy language
- fire/streak pressure
- fitness imagery
- heavy gradients
- oversized marketing hero sections
- social-feed energy
- dramatic warning colors unless truly needed

## 3. Language Rules

Use:

- Einheit
- Bewegung
- Rhythmus
- Nachspueren
- Beobachtung
- Regelmaessigkeit
- Reflexprofil
- Hinweisstaerke
- Begleitung
- Paket
- Verlauf

Avoid:

- Workout
- Challenge
- Streak
- Performance
- Score
- Diagnose
- Defizit
- Ziel verpasst
- Push dich
- perfekt gemacht

Tone:

- observational, not judging
- motivating, not pressuring
- clear, not overly medical
- careful with health-related claims

Example:

Use:

> Deine Antworten zeigen Hinweise auf staerker ausgepraegte Moro-bezogene Muster.

Avoid:

> Du hast einen starken Moro-Reflex.

## 4. Role Model

### Normal User

Has access to:

- Heute
- Verlauf
- Begleitung
- Profil

### Trainer

Has access to normal user areas plus:

- Trainer

Trainers can:

- invite clients
- receive and accept client requests
- see connected clients
- see package transition status
- see relevant observations and progress
- plan appointments for partner exercises and conversations
- use messaging and video-call flows

Trainers accompany programs. They do not freely change the fixed package sequence.

### Admin

Admins are always also trainers.

Admins have access to:

- Heute
- Verlauf
- Begleitung
- Trainer
- Admin
- Profil

Admin role means trainer plus platform management rights.

Trainer role and public trainer visibility are separate:

- Trainer role: can use trainer tools
- Public visibility: appears in trainer search / map
- Admin role: can manage platform roles and approvals

Admins may be hidden from public trainer discovery.

## 5. Main Navigation

### Normal User

Tabs:

- Heute
- Verlauf
- Begleitung
- Profil

### Trainer

Tabs:

- Heute
- Verlauf
- Begleitung
- Trainer
- Profil

### Admin

Tabs:

- Heute
- Verlauf
- Begleitung
- Trainer
- Admin
- Profil

Removed from main navigation:

- Community
- separate Messages tab
- separate Trainer search tab

Reassigned:

- messages live in Begleitung and Trainer
- trainer search lives in Begleitung
- experiences become moderated shared experiences, not open community

## 6. Onboarding

### Goal

The onboarding should not only create an account. It should help users understand why they are using the app.

The user should understand:

- some reflexes from early development can remain active
- these patterns can later relate to motor and cognitive symptoms
- symptoms can show parallels to areas such as ADHD-like restlessness, concentration issues, tension, or posture problems
- rhythmic movement is repeated over weeks because the body needs regular, calm input
- the Reflexprofil is orientation, not diagnosis
- trainer support is optional and mainly relevant for isometric partner exercises

### Flow

1. Language selection
2. Welcome
3. Account / login
4. Basic understanding
5. Consent / legal privacy step
6. Reflexprofil: start or skip
7. Reflexprofil result, if completed
8. Ask whether isometric training was already done
9. Package duration recommendation
10. Start first package
11. Optional explanation of trainer support
12. Heute

### Basic Understanding Copy Direction

Use a careful explanation:

> Manche Reflexe aus der fruehen Entwicklung koennen laenger bestehen bleiben. Sie koennen spaeter mit motorischen oder kognitiven Schwierigkeiten zusammenhaengen, zum Beispiel mit Unruhe, Konzentrationsproblemen, Verspannungen oder Fehlhaltungen.

Optional:

> Viele dieser Muster koennen im Alltag Symptomen aehneln, die man auch aus Bereichen wie ADHS, Stressregulation oder Koerperkoordination kennt.

Avoid implying diagnosis or direct causation.

### Consent

Consent must happen before Reflexprofil data is collected.

Consent should explain that the app stores:

- Reflexprofil answers
- daily observations
- progress and package status
- trainer connection status

It should also explain:

- private observations are not shared publicly
- trainer sharing depends on active trainer connection / consent
- shared experiences are separate and voluntary

### Reflexprofil

The first Reflexprofil is free.

It can be skipped.

If skipped:

- the user can still start the first package
- no result is shown
- package duration uses default logic and the isometric-training answer
- the Reflexprofil can be completed later from Verlauf or Profil

Questionnaire content will be delivered later by an expert.

### Reflexprofil Result

The result should be a motivating orientation moment.

Use:

- visual Reflexprofil graphic
- clear categories
- "Hinweisstaerke" language
- short explanation
- connection to the first package

Do not use diagnostic language.

### Package Duration

Recommended package duration is based on:

- Reflexprofil result
- whether isometric training was already done

If Reflexprofil was skipped, duration uses the isometric answer and default rules.

### Trainer Invitation Special Case

If the user enters through a trainer invitation:

1. Invitation is shown
2. User logs in or creates account
3. Basic understanding
4. Consent
5. Reflexprofil start or skip
6. Trainer connection confirmation
7. Package duration
8. Heute

The user must knowingly confirm the trainer connection.

## 7. Package Logic

### Fixed Sequence

The app guides users through a fixed sequence of exercise packages.

After completing one package:

1. package completion
2. intermediate questionnaire
3. updated profile / reflection
4. next fixed package starts

The app should not freely recommend different next packages.

### Stable Exercises Within A Package

Exercises do not change inside a running package.

Each package has a fixed movement sequence that is repeated over several weeks.

The app should explain:

> Die Bewegungen bleiben in diesem Paket bewusst gleich. Regelmaessigkeit ist wichtiger als Intensitaet.

### Moro Special Case

Moro is the only package that can be revisited later.

Reason:

- Moro-related patterns can reactivate through strong stress or trauma

User can choose to restart Moro later.

When restarting Moro:

1. current package is interrupted / aborted
2. Moro starts from day 1
3. after Moro is completed, the previous package starts again from day 1

Example:

- user is in ATNR day 20
- user restarts Moro
- ATNR is interrupted
- Moro is completed
- ATNR restarts at day 1

Moro restart must be a deliberate action with explanation and confirmation.

Suggested location:

- Verlauf > Reflexprofil / package details
- Profil > Program & packages

Do not place it as a prominent daily action on Heute.

## 8. Heute

### Goal

Heute is the daily entry point.

It should answer:

- what is today's unit?
- where am I in the package?
- how long will it take?
- how do I begin?
- how has my week been?
- how can I reflect briefly?

It should feel like:

> Hier ist dein naechster ruhiger Schritt.

### Structure

1. Daily unit card
2. Optional daily impulse
3. Weekly regularity
4. Nachspueren / observation entry
5. Small wellbeing graph
6. Optional active Begleitung notice

### Daily Unit Card

Shows:

- current package
- day X of Y
- movement count
- estimated duration
- primary button: Einheit beginnen

If already completed today:

- Heute abgeschlossen
- secondary action: Beobachtung ergaenzen

If no active package:

- Reflexprofil erstellen or Paket starten

### Daily Impulse

Optional, motivational, not trainer instruction.

Examples:

- Heute zaehlt nicht Perfektion, sondern Regelmaessigkeit.
- Beobachte, ohne zu bewerten.
- Langsam und regelmaessig ist genug.

Do not use this block for trainer exercise instructions.

### Weekly Regularity

Replaces streak/fire logic.

Shows:

- Diese Woche
- X von 7 Tagen geuebt
- seven day dots

No guilt if a day was skipped.

### Nachspueren

Shows:

- recent impressions
- quick action: Beobachtung eintragen

### Wellbeing Graph

Small preview.

Full details live in Verlauf.

### Begleitung Notices

Only show concrete active notices:

- new message
- appointment proposal
- request accepted

Do not show daily trainer instructions.

## 9. Exercise Unit

### Goal

The exercise unit guides users through fixed rhythmic movements.

It should feel calm and safe. It should not feel like a workout session.

### Modes

#### Guided Mode

Default for:

- beginning of a package
- first days
- users who want more instruction
- returning after a longer pause

Includes:

- preparation
- movement explanation
- position
- duration
- rhythm visual
- pause
- next movement
- completion
- reflection

#### Routine Mode

For users who know the fixed movements in the current package.

Includes:

- compact overview
- movement title
- timer / rhythm
- short pauses
- optional Anleitung anzeigen
- completion reflection

Routine mode means less UI, not rushing.

### Preparation

Shows:

- package name
- day in package
- number of movements
- estimated duration
- reminder that regularity matters more than intensity

### Movement Screen

Guided mode:

- Bewegung X von Y
- movement name
- body position
- duration
- short instruction
- rhythm visual
- start / pause

Routine mode:

- movement name
- timer
- rhythm visual
- progress
- pause / continue
- optional instructions

### Pauses

Between movements:

- Kurz nachspueren
- Continue action
- optional observation note

Routine mode can make pauses shorter or auto-advance with control.

### Completion Reflection

Reflection must cover both:

1. direct feeling during the unit
2. overall impression since the last unit

Suggested copy:

> Reflexintegration kann auch nach der Einheit im Alltag spuerbar sein. Halte kurz fest, was du heute oder seit deiner letzten Einheit wahrgenommen hast.

Question 1:

> Wie hat sich die Einheit angefuehlt?

Chips:

- ruhig
- angenehm
- muede
- unruhig
- emotional
- koerperlich unangenehm
- schwer einzuschaetzen

Question 2:

> Was ist dir seit der letzten Einheit aufgefallen?

Chips:

- mehr Ruhe
- mehr Energie
- weniger Energie
- Stimmung schwankte
- emotionaler als sonst
- reizempfindlicher
- besserer Schlaf
- unruhiger Schlaf
- koerperliche Spannung
- keine Besonderheit

Optional:

- Eigene Beobachtung

### Manual Completion

If user practiced without app guidance:

- open short entry flow
- ask whether today's unit was done
- ask the same reflection questions
- save as completed

Avoid wording like "Training als abgeschlossen markieren".

Use:

- Heute geuebt eintragen
- Einheit eintragen

## 10. Verlauf

### Goal

Verlauf is a calm logbook with understandable analysis.

It should show patterns, not performance.

### Structure

1. Diese Woche
2. Befinden im Verlauf
3. Reflexprofil
4. Beobachtungen
5. Aktuelles Paket / Paketverlauf
6. Moro erneut starten, placed carefully

### Diese Woche

Shows:

- regularity
- completed days
- reflections

No guilt language.

### Befinden Im Verlauf

Graph area.

Possible dimensions:

- overall impression
- mood
- energy
- sleep
- calm / unrest

Default should be simple.

### Reflexprofil

Shows:

- first Reflexprofil
- intermediate questionnaire results
- change over time
- Hinweisstaerke per reflex-related category

Use horizontal bars or a calm profile graphic.

### Beobachtungen

Timeline of reflection entries:

- unit impression
- since-last-unit observations
- optional notes

### Package Verlauf

Shows:

- active package
- day in package
- package completion
- intermediate questionnaire status
- next fixed package

## 11. Begleitung

### Goal

Begleitung is the user's professional support area.

It is not the trainer work area.

Main purpose:

- trainer discovery
- trainer connection
- isometric partner exercise context
- appointments
- messages
- trainer change

### Trainer Role For Users

Trainers are especially important for isometric partner exercises.

These exercises:

- happen at the beginning of a package
- help the user physically perceive movement, direction, and force
- are not strength training
- can give the body and brain a start impulse for better orientation

Daily rhythmic units remain self-guided.

### No Trainer Connected

Show:

- explanation of isometric partner exercises
- Trainer finden
- optional: continue without trainer

Suggested copy:

> Manche Uebungen werden mit einer zweiten Person durchgefuehrt. Dabei geht es nicht um Krafttraining, sondern um klares Spueren von Richtung, Bewegung und Widerstand. Ein geschulter Trainer kann dich dabei sicher anleiten.

### Trainer Search

Should feel professional, not like a marketplace.

Trainer cards:

- name
- photo/avatar
- qualification
- location / online
- languages
- experience with reflex integration / isometric partner exercises
- profile action

### Request Open

Show:

- request status
- selected trainer
- withdraw request
- view more trainers

### Trainer Connected

Show:

- current trainer
- messages
- appointments
- trainer profile
- Begleitung wechseln

Appointment types:

- Partneruebung
- Gespraech

### Trainer Change

When user changes trainer:

- old trainer loses client from dashboard
- new trainer receives user in dashboard
- user should confirm the switch
- data sharing implications should be clear

Suggested copy:

> Nach dem Wechsel erscheint dein Verlauf beim neuen Trainer. Dein bisheriger Trainer sieht dich danach nicht mehr in seiner Klientenuebersicht.

## 12. Trainer Area

### Goal

The Trainer tab is the trainer work area.

It helps trainers:

- invite clients
- manage client requests
- track package transitions
- plan appointments for partner exercises and conversations
- see relevant observations
- message clients

Trainer area is not the user's own Begleitung area.

### Dashboard Priorities

Important cards:

1. Paketuebergaenge
2. Offene Einladungen
3. Neue Anfragen
4. Termine
5. Neue Beobachtungen

Package transitions are very important because the isometric partner exercise is done at the beginning of a package.

Example:

> Lisa M. - Moro - Tag 39 von 42
> Paketabschluss in 3 Tagen
> Partneruebungs-Termin fuer das naechste Paket planen

### Client Invitation

Trainers can actively invite clients.

Flow:

1. Trainer creates invitation
2. Client opens link or code
3. Client creates account or logs in
4. Client confirms trainer connection
5. Client completes onboarding / Reflexprofil
6. Trainer sees client in dashboard

### Client Detail

Sections:

- overview
- package status
- observations
- wellbeing / Verlauf
- appointments
- messages

### Appointments

Appointment types:

- Partneruebung
- Gespraech

Video-call function already exists and should support appointment flows.

Availability management is open and should be planned later.

### Trainer Limitations

Trainers:

- accompany programs
- do not freely edit the fixed package sequence
- do not create per-exercise daily instructions
- see client data only through active relationship / consent

## 13. Admin Area

### Goal

Admin manages the platform.

Admins are always trainers.

### Admin Navigation

Admin users see:

- Heute
- Verlauf
- Begleitung
- Trainer
- Admin
- Profil

### Admin Functions

V1:

- trainer applications
- trainer approvals
- user roles
- public trainer visibility
- temporary premium / access management
- shared experience admin approval

Later:

- system/support
- content/package management
- feature flags
- automated payment support

### Trainer Approval

Admin can:

- review trainer applications
- approve trainer role
- reject application
- set public visibility

Trainer role and public visibility are separate.

### Access / Premium

Current manual premium access is temporary.

Long-term:

- monetization should move to a clear paywall / subscription or purchase structure
- admin access management should become support/override, not primary monetization

Premium is a status, not a navigation area.

## 14. Profil

### Goal

Profil is account and app management.

It should not contain daily product workflows.

### Sections

- account
- language
- password / login
- reminders
- app settings
- music / sound / haptics
- program & packages
- Reflexprofil nachholen if skipped
- privacy
- data sharing
- shared experiences
- access / premium later
- logout

For trainers:

- trainer profile editing
- public visibility
- location / online
- qualifications
- languages

Moro restart can live here as part of program management, or in Verlauf package details.

## 15. Shared Experiences

Community as an open main tab is removed for V1.

Users may voluntarily share experiences.

Shared experiences are different from private observations.

Private observation:

- lives in Verlauf
- remains private
- may be visible to connected trainer according to consent

Shared experience:

- intentionally submitted for publication/use
- reviewed before becoming visible

### V1 Review Flow

If user has trainer:

1. user submits experience
2. trainer review
3. admin review
4. publication/use after admin approval

If user has no trainer:

1. user submits experience
2. admin review
3. publication/use after approval

Default sharing should be anonymous unless user explicitly chooses otherwise.

Avoid social mechanics:

- likes
- ranking
- open comments
- unmoderated tips
- healing claims

## 16. Paywall / Premium Later

Paywall is intentionally not part of the immediate restructuring.

Principles:

- Premium is an access status, not a tab.
- Free and premium users should share the same calm app structure.
- Premium may unlock depth, history, advanced insights, or extended support.
- Trainer support may become separate from app premium.
- Current manual admin premium unlock is temporary.

Keep future paywall possible by separating:

- feature access
- role access
- package access
- trainer relationship
- payment status

## 17. Open Questions

- exact Reflexprofil questionnaire content from expert
- exact scoring and result categories
- legal wording for consent and data sharing
- exact package sequence and package durations
- default duration logic when Reflexprofil is skipped
- exact threshold for showing Routine mode
- rhythm visual design
- sound / haptic defaults
- trainer data visibility rules
- appointment availability management
- shared experience publication destination
- premium/free separation later

## 18. Suggested Implementation Phases

### Phase 1: Structure And Language

- update navigation to Heute / Verlauf / Begleitung / Profil
- add Trainer tab for trainer/admin users
- add Admin tab for admins
- remove Community from main navigation
- rename user-facing training language to Einheit / Bewegung / Nachspueren
- replace streak/fire framing with regularity

### Phase 2: Heute And Unit Flow

- redesign Heute
- add guided/routine mode entry
- redesign completion reflection
- support manual completion with reflection

### Phase 3: Verlauf

- build Verlauf tab
- move wellbeing graph here as main view
- add observation timeline
- add package status
- prepare Reflexprofil placeholder/result area

### Phase 4: Begleitung

- restructure trainer search and trainer connection into Begleitung
- add isometric partner exercise explanation
- support trainer change UX
- surface appointment types

### Phase 5: Trainer

- trainer dashboard
- client invitation
- package transition alerts
- client detail with observations and appointments
- shared experience trainer review

### Phase 6: Admin

- trainer applications / approvals
- user roles
- trainer public visibility
- temporary access management
- shared experience admin review

### Phase 7: Reflexprofil

After expert questionnaire arrives:

- implement questionnaire
- implement scoring
- implement result visualization
- integrate onboarding
- integrate Verlauf Reflexprofil
- integrate intermediate questionnaires

### Phase 8: Paywall

Later:

- define free/premium split
- implement purchase flow
- remove manual premium unlock as primary mechanism

