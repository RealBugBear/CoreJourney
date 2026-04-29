# CoreJourney — Open Points Review
**Datum:** 2026-04-25
**Status:** Draft for implementation planning
**Projekt:** CoreJourney (Flutter + Supabase)

---

## Überblick

Die App hat inzwischen viele starke Bausteine: Offline-first Training, Auth-Flows, Trainer-Beziehung, Chat, Video-Grundlage, Community-Erfahrungen, Mood/Journal und ein wachsendes Admin-/Trainer-Modell. Der wichtigste offene Punkt ist nicht ein einzelnes Feature, sondern die **Kohärenz**: mehrere Pläne wurden parallel begonnen, einige Screens folgen schon neuen Ideen, andere noch alten Chat-/Settings-/Navigation-Konzepten.

Für den nächsten Implementierungsplan sollte deshalb zuerst stabilisiert und vereinfacht werden, bevor neue große Features wie Trainer-Discovery vollständig gebaut werden.

---

## Prioritätsübersicht

| Priorität | Bereich | Warum wichtig |
|---|---|---|
| P0 | Navigation & Settings | Nutzerführung fühlt sich aktuell uneindeutig an; Settings ist überladen |
| P0 | Video-Call 1:1 | Existiert, klappt aber nicht zuverlässig genug |
| P0 | Auth/Account Deployment | Account löschen, Passwort-Reset und Deep Links brauchen Ende-zu-Ende-Verifikation |
| P1 | Community-Pinnwand | Produktidee ist klar, technische Umsetzung ist noch Chat/Experience-Mischform |
| P1 | Trainer-Beziehung | Invite/Trainerwechsel existieren, Discovery/Verifizierung kommt später dazu |
| P1 | Sync & Onboarding-Gates | Kritisch für Wiederkehrer, frische Geräte, Offline-Nutzung |
| P2 | Training Experience Polish | Immersive Training ist Kernwert, aber noch UX-/QA-lastig |
| P2 | Admin/Operations | Admin-Panel existiert, aber noch nicht als verlässlicher Betriebsbereich |
| P3 | Enterprise Hardening | Rate Limits, Audit Logs, Monitoring, Push, Rollenmodell |

---

## 1. Navigation & Settings

### Aktueller Befund

- `AppShell` hat aktuell Home, Community, Profil.
- DM existiert, liegt aber nicht konsistent als Shell-Tab.
- Settings enthält Präferenzen, Account, Trainer, Admin, Sync, Sonderfälle und destruktive Aktionen.
- Die neue Zielrichtung ist klar: Settings nur für App-Verhalten, Account ins Profil, Trainer in eigenen Bereich.

### Offene Punkte

- Settings entschlacken.
- Profil um Account-Verwaltung erweitern.
- Rollen-/Admin-/Trainer-Zugänge aus Settings entfernen.
- Trainer-Home als eigener Kontext vorbereiten.
- Community nicht mehr als “Kanal” oder “Chat” darstellen.

### Empfehlung

Als erstes umsetzen. Das verbessert die App sofort und reduziert spätere Umbau-Reibung.

Referenz:
- `docs/superpowers/plans/2026-04-25-navigation-settings-cleanup.md`

---

## 2. Chat, Community & Video

### Aktueller Befund

- Direct Chat existiert.
- Community ist technisch noch über Chat/Channel-Logik angebunden, soll produktseitig aber eine Pinnwand aus geteilten Journal-/Erfahrungseinträgen sein.
- Video-Call nutzt Agora, aber der Lifecycle ist noch nicht robust.

### Offene Punkte Direct Chat

- Direct Chat an aktive Trainer-Beziehung binden.
- Alte Direct Channels bei Trainerwechsel archivieren oder schreibschützen.
- Keine Nutzer-zu-Nutzer-DMs.
- Chat als Trainer-Kommunikation führen, nicht als generisches Nachrichten-System.

### Offene Punkte Community

- Langfristig eigenes Datenmodell statt `chat_messages`.
- UI-Texte und Navigationssprache auf “Erfahrungen/Pinnwand” umstellen.
- Freiwilliges Teilen aus Journal/Training klarer absichern.
- Moderation: eigene Posts ausblenden/löschen, Trainer/Admin ausblenden.
- Keine freien Kommentare in Phase 1.

### Offene Punkte Video

- Android Kamera-/Mikrofon-Permissions fehlen im Manifest.
- Incoming Calls werden nur im offenen Chat-Screen erkannt.
- Kein app-weiter Call-Listener.
- Kein Push für Hintergrund/geschlossene App.
- Token-Fehler werden aktuell zu leicht auf leeren Dev-Token reduziert.
- Beide Teilnehmer müssen Call beenden können.
- Maximal ein aktiver Call pro Direct-Channel sollte DB-seitig garantiert werden.

### Empfehlung

Video zuerst funktionsfähig machen, dann Community-Pinnwand sauber vom Chat trennen.

Referenz:
- `docs/superpowers/specs/2026-04-25-chat-community-video-enterprise-review.md`

---

## 3. Trainer-System & Discovery

### Aktueller Befund

- Trainerrolle und Invite-Code-System existieren.
- Trainerwechsel ist teilweise atomar ins Backend gewandert.
- Discovery wurde neu als privacy-safe, Login-only, verifiziertes Trainer-Netz geplant.

### Offene Punkte

- Trainer-Home/Trainer-Zentrale fehlt als Nutzerkontext.
- Trainer-Discovery ist geplant, aber noch nicht implementiert.
- Admin-Verifizierung für Trainerprofile fehlt.
- Privacy-safe Standortmodell muss sauber per RPC umgesetzt werden.
- Mehrere offene Trainer-Anfragen sind gewünscht, aber nur eine aktive Beziehung in Phase 1.
- Bestehender Invite-Flow und Discovery-Anfrage-Flow müssen serverseitig konsistent zusammengeführt werden.

### Empfehlung

Vor voller Discovery zuerst Trainer-Bereich und Direct-Chat/Video stabilisieren. Discovery danach als neue Ausbaustufe.

Referenz:
- `docs/superpowers/specs/2026-04-24-trainer-discovery-design.md`

---

## 4. Auth, Account & Consent

### Aktueller Befund

- `app_links` ist eingebunden.
- Deep-Link-Handling existiert in `lib/app.dart`.
- Passwort-Reset und Passwort-Änderung sind konzeptionell geplant.
- Consent-Tabelle existiert als Migration.
- Account löschen hängt an `delete_user()` RPC.

### Offene Punkte

- Universal Links / App Links müssen auf echten Geräten Ende-zu-Ende getestet werden.
- Supabase Auth Redirect URLs müssen für DEV/PROD geprüft sein.
- `delete_user()` muss in DEV/PROD deployed und getestet sein.
- Consent-Versionierung muss klar betrieben werden.
- Account-Aktionen sollen ins Profil wandern.
- Login-Screen ist funktional, aber noch wenig onboarding-/vertrauensbildend.

### Empfehlung

Als P0 prüfen, bevor neue App-Bereiche wachsen. Account-Flows müssen verlässlich sein.

Referenz:
- `docs/superpowers/specs/2026-04-19-auth-enterprise-design.md`

---

## 5. Offline Sync & Rehydration

### Aktueller Befund

- Offline-first Drift + Sync-Jobs existieren.
- Rehydration nach Login ist implementiert und Dashboard-Gates warten teilweise darauf.
- Konflikt-Recovery existiert für bestimmte Enrollment-/Progress-Fälle.

### Offene Punkte

- Rehydration zieht nicht alle neuen Serverdatenarten, z.B. Community/Experience, Trainerprofile, Calls, Appointments.
- Sync-Status ist sichtbar, aber aktuell in Settings zu prominent/technisch.
- Es gibt keinen normalen Nutzer-Flow für “Sync hängt fest” außer manuellem Sync.
- Sync-Jobs nach 5 Fehlversuchen bleiben als failed; Support-/Recovery-Konzept fehlt.
- Cross-device-Szenarien müssen getestet werden.

### Empfehlung

Nicht sofort groß umbauen, aber in Release-Readiness aufnehmen. Für Community/Trainer-Discovery muss entschieden werden, was offline-first ist und was online-only bleibt.

---

## 6. Training Experience

### Aktueller Befund

- Immersive Training ist geplant und teilweise implementiert.
- Dashboard ist bereits stärker auf Tagesstatus + Mood + Training CTA fokussiert.
- Training Experience Sheet teilt optional Erlebnisse in die Community.

### Offene Punkte

- Training-Flow hat alte und neue Screens parallel.
- Disclaimer-Logik enthält TODOs.
- In-App-Musik-Assets sind als Infrastruktur geplant, aber Asset-Reife ist unklar.
- Große visuelle/Audio-Flows brauchen Geräte-QA.
- “Training als abgeschlossen markieren” ist nützlich, kann aber Produktlogik verwässern, wenn zu prominent.
- Community-Sharing aus Training muss klarer mit Journal/Privacy verbunden werden.

### Empfehlung

Training bleibt Kernprodukt, aber erst nach Navigation/Video/Auth stabilisieren. Danach eine fokussierte QA-Runde für immersive Session, Audio, Pausen, Abbruch/Resume.

Referenz:
- `docs/superpowers/specs/2026-04-22-immersive-training-redesign.md`

---

## 7. Community Experience Data Model

### Aktueller Befund

- Es gibt bereits `experience_shares`-Code und Feed-Screen.
- Neue Review empfiehlt langfristig `community_posts`.
- Aktueller Feed erlaubt Moderator-Posts; Produktvision sagt Nutzer teilen Journal-Erfahrungen.

### Offene Punkte

- Entscheiden: `experience_shares` weiterentwickeln oder auf `community_posts` migrieren.
- RLS für Lesen nach Paket/Enrollment prüfen.
- Anonymitätsmodell sauber festlegen.
- Delete vs. Hide: für Moderation besser `hidden/removed` statt Hard Delete.
- Journal-Verknüpfung und spätere DSGVO-Löschung klären.

### Empfehlung

Kurzfristig UI-Sprache korrigieren. Mittelfristig Datenmodell konsolidieren, bevor der Feed produktiv wächst.

---

## 8. Admin & Operations

### Aktueller Befund

- Admin Panel kann Trainer-Codes generieren und Premium umschalten.
- Mehrere Admins sind geplant über `profiles.role = 'admin'`.

### Offene Punkte

- Admin Panel ist kein echter Operations-Hub.
- Trainer-Verifizierung fehlt.
- Moderation für Community fehlt.
- Audit Logs fehlen.
- Premium/RevenueCat ist teilweise kommentiert/deferred.
- Admin-Zugriff sollte nicht in Settings liegen.

### Empfehlung

Admin erstmal klein halten, aber nicht verstecken: Profil → Admin Panel. Später eigener Operations-Bereich mit Verifizierung, Moderation, Audit.

---

## 9. Release, Config & Observability

### Aktueller Befund

- Firebase Analytics/Crashlytics/FCM ist kommentiert.
- Push ist für Calls/Trainer-Benachrichtigungen perspektivisch wichtig.
- Agora ist eingebunden, aber Token-/Certificate-Modus ist noch dev-lastig.
- Es gibt lokale Logger und Bootstrap-Debug-Datei.

### Offene Punkte

- Crash-/Error-Reporting fehlt für echte Nutzer.
- Push-Infrastruktur fehlt.
- DEV/PROD Supabase-Migrationen und Secrets müssen sauber nachvollziehbar sein.
- App-Version/Build/Environment sollte in Support-Diagnose sichtbar sein.
- Feature Flags existieren im Schema, aber App-seitig nicht konsequent als Rollout-Steuerung genutzt.

### Empfehlung

Vor größerem Nutzerkreis mindestens Crashlytics/Logging-Strategie, Migration-Checklist und Push-Entscheidung klären.

---

## 10. Technische Schulden / Inkonsistenzen

### Beobachtungen

- Mehrere alte und neue Plans beschreiben unterschiedliche Navigationen.
- Community ist teils Chat, teils Experience Feed, teils geplante Pinnwand.
- Settings-Screen enthält noch Logik, die in andere Bereiche gehört.
- Direct Chat/DM ist UI-seitig noch nicht sauber in die Produktstruktur integriert.
- Einige Routen existieren außerhalb der Shell, obwohl Specs Shell-Children beschreiben.
- Viele neue Dateien sind untracked; der Arbeitsstand sollte vor großen Umsetzungen stabilisiert werden.

### Empfehlung

Vor dem Gesamt-Implementierungsplan eine kanonische Reihenfolge festlegen und alte/plausibel überholte Pläne als “superseded” markieren oder zumindest nicht mehr als aktive Quelle verwenden.

---

## Empfohlene Gesamt-Reihenfolge

1. **UX-Struktur stabilisieren:** Settings/Profile/Community-Sprache.
2. **Auth/Account verifizieren:** Reset, Change Password, Delete, Consent.
3. **1:1 Video stabilisieren:** Permissions, RPC-Lifecycle, globaler Listener.
4. **Trainer-Zentrale vorbereiten:** Trainer Home, Direct Chat, Termine, Trainerwechsel.
5. **Community-Pinnwand konsolidieren:** Experience/Journal-Share sauber modellieren.
6. **Training QA:** Immersive Flow, Audio, Pause, Completion, Experience Prompt.
7. **Trainer Discovery MVP:** privacy-safe Suche, Verifizierung, Anfragen.
8. **Release Readiness:** Crash/Push/Migration/Secrets/Feature Flags.
9. **Deferred Enterprise:** Audit, Rate Limits, Rollenmodell, Monitoring.

---

## Entscheidung für den nächsten Plan

Der nächste Implementierungsplan sollte nicht alle Features gleichzeitig bauen. Er sollte ein **geordnetes Programm aus Phasen** sein:

- Phase A: App-Struktur und Account-Flows
- Phase B: Kommunikation stabilisieren
- Phase C: Community-Pinnwand und Trainer-Zentrale
- Phase D: Trainer-Discovery
- Phase E: Release-/Enterprise-Hardening

So bleibt die deutschlandweite Vision erhalten, ohne den aktuellen MVP mit zu vielen parallelen Umbauten zu überladen.
