# Reflexprofil & Mehrpersonen-Training Architekturplan

Status: Planungsbaseline fuer Umsetzung  
Datum: 2026-05-11  
Bereich: CoreJourney App, Reflexprofil, Training, Eltern/Kinder, Trainerbegleitung

## 1. Ausgangslage

CoreJourney war urspruenglich stark auf einen trainierenden Nutzer pro Account ausgelegt. Durch das Reflexprofil und den Elternfragebogen ist klar geworden, dass ein Account mehrere reale Trainingspersonen verwalten koennen muss:

- ein erwachsener Nutzer trainiert fuer sich selbst
- ein Elternteil trainiert mit einem Kind
- ein Elternteil verwaltet mehrere Kinder
- ein Elternteil kann zusaetzlich selbst trainieren
- Trainer und Admins sollen ebenfalls ihr eigenes Training und Reflexprofil nutzen koennen
- Trainer begleiten nicht nur Accounts, sondern einzelne freigegebene Profile innerhalb eines Accounts

Das bisherige Modell `Account = trainierende Person` reicht dafuer nicht mehr aus. Es fuehrt zu Problemen bei Training, Reflexprofil, Trainerfreigabe, Terminen, Auswertungen und Monetarisierung.

## 2. Zielbild

Die App soll sauber zwischen Account und trainierbarer Person unterscheiden.

Ein Account ist der Login, Kontakt, Rollen- und Zahlungsrahmen.

Ein Profil ist die konkrete Person, fuer die Reflexprofil, Training, Verlauf, Termine und Trainerfreigabe gelten.

Das Zielmodell lautet:

- `profiles` / Auth User: Login, Kontaktname, Rolle, Abo, Trainer/Admin-Rechte
- `reflex_subject_profiles`: konkrete trainierbare Profile wie `Ich`, `Max`, `Emma`
- Training, Reflexprofil, Fortschritt und Termine haengen an `subject_profile_id`
- Trainerverbindung bleibt zuerst accountbezogen
- Sichtbarkeit fuer Trainer wird pro Profil freigegeben

Damit koennen einfache Einzelpersonen und Familien denselben technischen Kern nutzen, ohne dass fuer Eltern, Kinder, Trainer und Admins jeweils Sonderlogik entsteht.

## 3. Begriffe

### Account

Der Account ist der Login und Kontaktanker.

Er enthaelt:

- Authentifizierung
- E-Mail
- Kontaktname
- Rolle: Nutzer, Trainer, Admin
- Abo / Zahlungsstatus
- Trainerverbindung
- globale App-Einstellungen

Der Account ist nicht automatisch die trainierende Person.

### Kontaktname

Der Kontaktname ist der Name, den Trainer und Systemfunktionen fuer Kommunikation, Termine und Verknuepfungen sehen.

Beispiele:

- `Maria Schneider`
- `Max' Eltern`
- `Anna & Tom`
- `Familie Mueller`

Der Kontaktname soll direkt nach der Registrierung verpflichtend abgefragt werden, weil im Trainerdashboard, im Chat und bei Terminen sonst unbrauchbare Namen wie `Ich`, `User` oder E-Mail-Fragmente erscheinen.

Wichtig:

- Der Kontaktname ist nicht automatisch der Community-Name.
- Der Kontaktname ist nicht automatisch ein Reflexprofil.
- Der Kontaktname kann spaeter geaendert werden.
- Trainer sehen den aktualisierten Namen dynamisch.

### Subject Profile / Trainingsprofil

Ein Subject Profile ist die konkrete Person, fuer die trainiert oder ausgewertet wird.

Beispiele:

- `Ich`
- `Max`
- `Emma`
- `Mama`

Ein Profil enthaelt:

- Anzeigename oder Spitzname
- Profiltyp: Kind oder erwachsene Person
- optional Geburtsdatum
- optional berechnetes Alter
- optional Altersgruppe
- Metadaten

Reflexprofil, Training, Verlauf, Fortschritt, Stimmung, Journal, Termine und Trainerfreigaben sollen an diesem Profil haengen.

## 4. Grundsatzentscheidung

Alle Rollen duerfen trainieren.

Das betrifft:

- normale Nutzer
- Eltern
- Trainer
- Admins

Trainer- und Adminrechte sind Zusatzfunktionen in der Navigation, aber kein eigener Trainingsmodus. Ein Trainer kann also weiterhin seine Trainerbereiche sehen, aber auch ein normales eigenes Profil `Ich` nutzen und selbst trainieren.

## 5. Onboarding

### Neuer Account

Direkt nach Registrierung soll ein kurzer Setup-Flow kommen.

1. Kontaktname abfragen
2. Fragen, fuer wen gestartet werden soll:
   - `Fuer mich`
   - `Fuer mein Kind`
3. Passendes Subject Profile anlegen
4. Danach in die App fuehren

### Wenn der Nutzer fuer sich startet

Die App erstellt ein erwachsenes Profil, standardmaessig `Ich`, mit optionalem Namen.

Der Nutzer kann danach:

- Reflexprofil machen
- Reflexprofil ueberspringen
- Moro kostenlos starten
- spaeter weitere Pakete nach Freischaltung starten

### Wenn der Nutzer fuer ein Kind startet

Die App fragt zuerst nur die wirklich noetigen Daten ab:

- Wie soll das Kind in der App heissen?
- optional Geburtsdatum oder Alter
- Kontaktname fuer Trainer/Termine, falls noch nicht gesetzt

Wichtig: Eltern muessen nicht zuerst ihr eigenes Reflexprofil machen, nur um das Training fuer ihr Kind zu starten.

### Bestehende Accounts

Bestehende Accounts brauchen eine sanfte Migration.

Empfehlung:

- Wenn kein Kontaktname oder nur ein generischer Name vorhanden ist, wird beim naechsten Start ein Kontaktname abgefragt.
- Wenn es noch kein Subject Profile gibt, wird ein Profil `Ich` angelegt.
- Wenn bereits Kinderprofile existieren und alte Trainingsdaten nicht eindeutig zuordenbar sind, soll eine einmalige Zuordnungsfrage erscheinen:
  - `Zu wem gehoert dein bisheriges Training?`

Keine harte Migration, die alte Daten unbrauchbar macht. Erst nullable Spalten, Backfill, Fallbacks, danach strenger machen.

## 6. Profilverwaltung

### Dashboard

Im Dashboard soll oben klar sichtbar sein, fuer welches Profil die App gerade angezeigt wird.

Beispiel:

`Max v`

Beim Tippen kann der Nutzer schnell wechseln:

- Max
- Emma
- Ich
- Profil hinzufuegen

Das aktive Profil steuert:

- heutige Einheit
- aktives Paket
- Verlauf
- Reflexprofil-Hinweise
- Trainerfreigabe-Kontext

### Profil-Tab

Im Profil-Tab liegt die ausfuehrlichere Verwaltung:

- Kontaktname
- eigene Accountdaten
- Kinderprofile
- eigenes Profil
- Trainerverbindung
- Freigaben
- Datenschutz / Account loeschen

### Mehrere Kinder

Kinder koennen jederzeit hinzugefuegt werden. Fuer das MVP ist ein weicher Richtwert von 4 Kinderprofilen sinnvoll.

Das soll nicht hart blockieren, sondern als freundlicher Hinweis oder Abo-/Support-Hinweis erscheinen.

### Elternprofile

Eltern sollen ebenfalls trainieren duerfen. Ein Familienaccount kann bis zu 2 erwachsene Elternprofile enthalten.

Das wird nicht als grosses Mehrpersonen-Feature fuer beliebige Erwachsene vermarktet. Erwachsene Personen ausserhalb der Familie sollen grundsaetzlich einen eigenen Account nutzen.

## 7. Geburtsdatum und Alter

Geburtsdatum ist sinnvoller als ein fest gespeichertes Alter, weil die Begleitung ueber Monate oder Jahre laufen kann.

Empfehlung:

- Im Profil optional `birth_date` speichern.
- Alter und Altersgruppe dynamisch berechnen.
- Trainer sehen nur Alter oder Altersgruppe, nicht das Geburtsdatum.
- Bei jedem Reflexprofil wird ein Snapshot gespeichert:
  - `age_years_at_assessment`
  - `age_months_at_assessment`
  - `age_group_at_assessment`

So bleibt eine alte Auswertung auch spaeter korrekt, obwohl das Kind aelter geworden ist.

## 8. Reflexprofil

### Fragebogenarten

Es gibt mindestens diese Fragebogenarten:

- Elternfragebogen fuer Kinder
- spaeter Erwachsenenfragebogen
- oeffentlicher Demo-/Kurzfragebogen

Die Auswertungslogik bleibt gleich aufgebaut:

- Fragen werden Reflexen zugeordnet.
- Eine Frage kann mehrere Reflexe betreffen.
- Zunaechst sind alle Fragen gleich gewichtet.
- Pro Reflex wird berechnet, wie viele zugeordnete Fragen mit `Ja` beantwortet wurden.
- Ergebnis ist ein Prozentwert.

Interpretation:

- unter 50 Prozent: unauffaellig
- ab 50 Prozent: Anzeichen
- ab 80 Prozent: auffaellig
- 100 Prozent: stark ausgepraegt

Diese Schwellen sind v1 und muessen spaeter fachlich nachjustierbar bleiben.

### Antwortoptionen

Standard:

- Ja
- Nein
- Weiss ich nicht

Sondertypen:

- Freitext, z. B. gesundheitliche Probleme in der Schwangerschaft
- Zahl in Monaten, z. B. ab wann gekrabbelt / gelaufen
- Mehrfachauswahl plus Freitext, z. B. Schwangerschaftsprobleme

### Schwangerschaftsprobleme

Fuer Frage 2 sollen feste Optionen plus Freitext angeboten werden:

- Schwangerschaftsvergiftung
- Schwangerschaftsblutung
- Bluthochdruck
- Sonstiges Freitextfeld

Fuer Adminstatistik werden die festen Optionen gezaehlt. Freitext wird zunaechst nur als `Freitext vorhanden` gezaehlt, nicht inhaltlich ausgewertet.

### Sicherheits- und Ruecksprachehinweise

Gelb markierte Fragen aus Tabelle 2 sind Ruecksprachehinweise.

Wenn eine solche Frage mit `Ja` beantwortet wird, soll sofort ein Popup erscheinen.

Der Nutzer muss bestaetigen, dass Training nur nach Ruecksprache und ausdruecklicher Zusage des behandelnden Arztes, Therapeuten oder Psychologen erfolgen darf.

Die Bestaetigung wird gespeichert mit:

- Frage-ID
- Hinweistext
- Antwort
- Zeitstempel
- Nutzer-ID
- Assessment-ID

Fuer besonders sensible Punkte wie Epilepsie und Trisomie 21 gilt:

- Training nicht einfach normal starten lassen.
- Es braucht eine ausdrueckliche Bestaetigung.
- Der Nutzer darf nach Bestaetigung fortfahren, soll aber klar empfohlen bekommen, mit Trainerbegleitung zu arbeiten.

Der Hinweis soll nicht als Diagnose oder Score behandelt werden.

### Sichtbarkeit der Sicherheitsfragen fuer Trainer

Wenn ein Profil fuer einen Trainer freigegeben ist, muss der Trainer konkrete Sicherheits-/Ruecksprachehinweise sehen.

Nicht nur:

`Ruecksprache erforderlich`

Sondern konkret, z. B.:

- ADHS / ADS wurde angegeben
- Autismus wurde angegeben
- Epilepsie wurde angegeben
- Trisomie 21 / Downsyndrom wurde angegeben
- psychologische oder psychiatrische Behandlung wurde angegeben

Die Texte sollen aus den sauberen Sicherheitsfragen des Fragebogens kommen.

## 9. Reflexprofil-Freigabe

Nach jedem abgeschlossenen Reflexprofil wird erneut gefragt, ob die Auswertung fuer den verknuepften Trainer sichtbar sein soll.

Wichtig:

- Freigabe ist pro Profil.
- Freigabe ist pro Trainerverbindung.
- Freigabe kann widerrufen werden.
- Bei Trainerwechsel wird die alte Freigabe automatisch beendet.
- Ohne Freigabe sieht der Trainer nur den Kontakt, aber keine Reflexprofil- oder Trainingsdetails.

Die Freigabe soll nicht nur das Diagramm betreffen, sondern zusammengehoerig:

- Reflexprofil
- Sicherheits-/Ruecksprachehinweise
- relevante Trainingsauswertung
- Alter / Altersgruppe, wenn fuer Interpretation noetig

Der Nutzer soll im Begleitung-Tab die Freigabe spaeter aendern koennen. Dort darf es sichtbar sein, aber nicht zu dominant.

## 10. Training und Pakete

### Zentrale Regel

Ein Subject Profile hat immer maximal ein aktives Paket.

Mehrere Profile koennen parallel unterschiedliche Pakete haben.

Beispiele:

- Max macht Moro
- Emma hat noch kein Paket
- Ich macht spaeter ein anderes Paket

### Gemeinsames Starten

Eltern sollen ein Paket fuer mehrere Kinder gemeinsam starten koennen.

Technisch bleibt es getrennt:

- eigenes Enrollment pro Kind
- eigener Fortschritt pro Kind
- eigene Auswertung pro Kind

Die gemeinsame Funktion ist eine UI-Abkuerzung, kein gemeinsamer Datensatz.

### Kostenloser Einstieg

Moro ist fuer alle Profile kostenlos.

Die kostenlose Version soll eher ueber Paket-Locks funktionieren als ueber harte Profil-Limits.

Empfehlung:

- Moro fuer alle freigeschaltet
- andere Pakete hinter Bezahlstatus
- bis ca. 4 Kinderprofile ohne harte Sperre
- danach weicher Hinweis

### Dauerempfehlung

Fuer Moro:

- Wenn kein isometrisches Partnertraining gemacht wurde: 8 Wochen empfehlen.
- Wenn isometrisches Partnertraining gemacht wurde und ein Reflexprofil vorliegt: 4 bis 8 Wochen anhand des Moro-Ausschlags empfehlen.

Moegliche v1-Regel:

- Moro unter 50 Prozent: 4 Wochen
- Moro 50 bis 79 Prozent: 6 Wochen
- Moro ab 80 Prozent: 8 Wochen

Wenn Reflexprofil uebersprungen wurde, wird keine scorebasierte Empfehlung berechnet.

## 11. Trainerverbindung

Die Trainerverbindung bleibt accountbezogen.

Das bedeutet:

- Ein Trainer verbindet sich mit einem Account/Kontakt.
- Innerhalb dieses Kontakts koennen einzelne Profile freigegeben werden.
- Der Trainer sieht nur Profilinhalte, wenn der Nutzer das jeweilige Profil freigegeben hat.

Trainerdashboard-Zielbild:

- Kontakt: `Max' Eltern`
- freigegebene Profile:
  - Max
  - Emma
- nicht freigegebene Profile werden nicht mit Reflexdaten angezeigt

Der Trainer muss in Terminen und Auswertungen Profilnamen sehen, nicht nur `Klient`.

## 12. Termine

Termine muessen profilfaehig werden.

Ein Termin kann sein:

- allgemeiner Eltern-/Kontakttermin ohne Profil
- Termin fuer ein Kind
- Termin fuer mehrere Kinder
- Termin fuer Elternteil plus Kind

Empfohlenes Modell:

- `appointments` bleibt der Haupttermin
- neue Join-Tabelle `appointment_subject_profiles`
- dadurch kann ein Termin null, ein oder mehrere Profile betreffen

Anzeige:

- `Elterngespraech`
- `Termin fuer Max`
- `Max + Emma`

Im Chat soll bei Terminvorschlaegen ein Button stehen:

- `Vorschlag ansehen`

Dieser fuehrt direkt in den Begleitung-Tab beziehungsweise zur Termin-Auswahl.

Terminvorschlaege gehoeren nicht mehr nur auf das alte Dashboard, weil die App inzwischen ein neues Heute-Dashboard hat. Begleitung ist der passendere Ort.

## 13. Verlauf, Journal und Stimmung

Alles, was eine konkrete trainierende Person betrifft, soll an `subject_profile_id` haengen:

- Trainingseinheiten
- Fortschritt
- Tagesabschluss
- Stimmung
- Journal
- Reflexprofil
- Paketstatus

Accountweite Daten bleiben accountweit:

- Login
- Kontaktname
- Abo
- Rolle
- globale Einstellungen

## 14. Admin-Auswertung

Admin-Auswertungen muessen anonymisiert und aggregiert sein.

Admins sollen sehen koennen:

- welche Reflexe haeufig auffaellig sind
- welche Fragen haeufig mit Ja beantwortet werden
- Verteilung nach Altersgruppen
- Krabbel- und Laufalter als Zahlenstatistik
- feste Schwangerschaftsprobleme als Counter
- Diagnosen / Sicherheitsfragen als Counter

Freitexte werden zunaechst nicht inhaltlich aggregiert, sondern nur als `Freitext vorhanden` gezaehlt.

Die Admin-Statistik darf keine Namen oder identifizierenden Einzelprofile anzeigen.

## 15. Datenmodell-Ziel

### Bestehend

Es gibt bereits `reflex_subject_profiles` aus der Migration `20260510_reflex_profile_questionnaire_v1.sql`.

Diese Tabelle ist der richtige Startpunkt und sollte zum allgemeinen Trainingsprofil ausgebaut werden.

### Benoetigte Erweiterungen

Langfristig sollen diese Tabellen `subject_profile_id` tragen:

- `reflex_profile_assessments`
- `enrollments`
- `training_sessions`
- `progress_entries`
- `completion_questionnaires`
- `mood_checkins`
- `journal_entries`
- Termine ueber Join-Tabelle

Bei lokalen Drift-Tabellen muss das ebenfalls gespiegelt werden.

### Enrollment-Regel

Ein Profil darf nur ein aktives Enrollment haben.

Empfohlene DB-Regel:

- partial unique index auf `subject_profile_id`
- nur fuer `status = 'active'`

Falls spaeter parallele Pakete pro Profil erlaubt werden sollen, kann die Regel erweitert werden. Fuer den aktuellen Produktstand ist ein aktives Paket pro Profil klarer.

## 16. Migration

Die Migration sollte in Phasen passieren.

### Phase 1: Nullable Spalten

Neue `subject_profile_id` Spalten werden nullable hinzugefuegt.

Bestehende Queries behalten Fallbacks.

### Phase 2: Backfill

Fuer bestehende Nutzer wird ein Default-Profil erzeugt:

- Typ: `adult_self`
- Name: `Ich` oder Kontaktname

Bestehende Trainingsdaten werden diesem Profil zugeordnet, wenn keine bessere Information vorhanden ist.

Wenn ein Nutzer bereits Kinderprofile hat, aber alte Trainingsdaten nicht eindeutig sind, soll eine einmalige Zuordnung in der App erscheinen.

### Phase 3: Provider und UI umstellen

Provider filtern nicht mehr nur nach `user_id`, sondern nach aktivem `subject_profile_id`.

### Phase 4: Strenger machen

Wenn alle aktiven Daten migriert sind:

- `subject_profile_id` fuer neue Trainingsdaten verpflichtend machen
- alte Fallbacks entfernen
- eindeutige Indizes aktivieren

## 17. App-Architektur

### Neuer zentraler Zustand

Es braucht einen zentralen Provider:

- aktiver Account
- aktive Rolle
- aktive Subject Profiles
- aktuell ausgewaehltes Profil

Beispiel:

- `subjectProfilesProvider`
- `selectedSubjectProfileProvider`
- `activeEnrollmentForSubjectProvider`
- `subjectPackageAccessProvider`

### Training Provider

Aktuell wird Training stark ueber `userId` und `selectedPackageId` gesteuert.

Ziel:

- aktives Profil bestimmt das aktive Paket
- Enrollment wird fuer das Profil geladen
- Paketwechsel ist profilbezogen
- `selectedPackageId` wird entweder pro Profil gespeichert oder aus aktivem Enrollment abgeleitet

### Trainer Provider

Trainerdaten muessen account- und profilbezogen liefern:

- verbundene Kontakte
- freigegebene Profile je Kontakt
- aktive Pakete je freigegebenem Profil
- Termine je Kontakt und Profil

## 18. Navigation

Die bisherige Grundidee bleibt:

Normale Nutzer:

- Heute
- Verlauf
- Begleitung
- Profil

Trainer:

- Heute
- Verlauf
- Begleitung
- Trainer
- Profil

Admin:

- Heute
- Verlauf
- Begleitung
- Trainer
- Admin
- Profil

Trainer/Admin sind Zusatzbereiche. Die normale Trainingsapp bleibt fuer alle Rollen verfuegbar.

## 19. Datenschutz

Grundsatz:

Der Nutzer besitzt die Profile und entscheidet, was ein Trainer sehen darf.

Regeln:

- Trainerverbindung allein reicht nicht fuer Reflexprofil-Sichtbarkeit.
- Reflexprofil und Trainingsauswertung werden pro Profil freigegeben.
- Freigabe kann widerrufen werden.
- Bei Trainerwechsel wird Freigabe beendet.
- Adminstatistik ist anonymisiert und aggregiert.
- Trainer sehen keine Geburtsdaten, sondern nur Alter oder Altersgruppen.
- Freitexte werden vorsichtig behandelt und nicht ungeprueft aggregiert.

## 20. Oeffentlicher Demo-Fragebogen

Der Mini-Demo-Fragebogen bleibt oeffentlich und ohne Login.

Ziel:

- Nutzer koennen schnell sehen, wie eine Auswertung wirkt.
- Danach kann Registrierung angeboten werden.
- Der echte Fragebogen und gespeicherte Auswertungen brauchen Account und Profil.

Der Demo-Fragebogen wird nicht in Adminstatistiken oder echte Reflexprofile uebernommen.

## 21. Nicht-MVP, aber vorbereiten

Diese Punkte sollen nicht direkt umgesetzt werden, aber das Datenmodell sollte sie spaeter erlauben.

### Profiluebergabe / Kind exportieren

Wenn ein Kind spaeter selbst die App nutzen moechte, koennte ein Profil auf einen eigenen Account uebertragen werden.

Das ist kein MVP, aber `subject_profiles.owner_user_id` sollte so gedacht werden, dass eine spaetere Uebergabe moeglich bleibt.

### Detailliertere Abo-Modelle

Spaeter moeglich:

- Einzelabo
- Familienabo
- Trainerbegleitete Pakete
- Paketfreischaltungen
- Zusatzprofile

Fuer jetzt reicht:

- Moro frei
- andere Pakete gesperrt, wenn nicht bezahlt
- Familiennutzung ohne harte fruehe Blockade

## 22. Konkrete Umsetzungsreihenfolge

### Schritt 1: Kontaktname stabilisieren

- Pflichtscreen nach Registrierung
- bestehende generische Namen erkennen
- Profilname und Kontaktname sauber trennen
- Community-Name nicht automatisch aus Kontaktname ableiten

### Schritt 2: Subject Profile als Kern etablieren

- vorhandene `reflex_subject_profiles` als allgemeines Trainingsprofil verwenden
- Default-Profil fuer bestehende Nutzer anlegen
- Profilumschalter im Dashboard
- Profilverwaltung im Profil-Tab

### Schritt 3: Training profilbezogen machen

- Supabase `enrollments` um `subject_profile_id` erweitern
- lokale Drift-Tabellen erweitern
- Provider auf aktives Profil umstellen
- ein aktives Paket pro Profil absichern

### Schritt 4: Reflexprofil sauber anbinden

- Reflexprofil immer einem Subject Profile zuordnen
- Alterssnapshot speichern
- Freigabe nach jedem Fragebogen erneut fragen
- Sicherheitsfragen konkret speichern und anzeigen

### Schritt 5: Traineransicht umbauen

- Trainer sieht Kontakte
- darunter freigegebene Profile
- Reflexprofil und Training nur bei Freigabe
- Widerruf muss sofort greifen

### Schritt 6: Termine profilfaehig machen

- Join-Tabelle fuer Termin-Profile
- Terminvorschlaege im Begleitung-Tab
- Chat-Button zu Terminvorschlaegen
- Trainerdashboard zeigt Profilnamen statt nur `Klient`

### Schritt 7: Adminstatistik erweitern

- altersgruppierte Reflexauswertung
- Frage-Ja-Counter
- Krabbel-/Laufalter
- feste Schwangerschaftsprobleme
- Sicherheitsfragen
- Freitext nur als vorhanden/nicht vorhanden

## 23. Akzeptanzkriterien

Der Umbau gilt als gelungen, wenn:

- ein Single-Adult-Account ohne Kinder einfach trainieren kann
- ein Elternaccount mehrere Kinderprofile anlegen kann
- Eltern nicht gezwungen sind, zuerst selbst ein Reflexprofil zu machen
- Eltern spaeter trotzdem selbst trainieren koennen
- Trainer/Admins weiterhin ihre Sonderbereiche haben und selbst trainieren koennen
- jedes Profil ein eigenes Reflexprofil und eigenes Training haben kann
- ein Profil nur ein aktives Paket hat
- mehrere Profile parallel unterschiedliche Pakete haben koennen
- Trainer nur freigegebene Profile sehen
- Freigabe widerrufen werden kann
- bei Trainerwechsel alte Freigaben verschwinden
- Termine einem oder mehreren Profilen zugeordnet werden koennen
- Trainer in Terminen und Auswertungen konkrete Profilnamen sieht
- Adminstatistik anonym und altersgruppiert funktioniert

## 24. Offene technische Pruefpunkte

Diese Punkte sind keine Produktfragen mehr, sondern Umsetzungspruefungen im Code:

- Welche Supabase-Tabellen haben aktuell schon `subject_profile_id`?
- Welche lokalen Drift-Tabellen brauchen Schema-Bump?
- Welche Provider gehen noch von `user_id = trainierende Person` aus?
- Wo wird `selectedPackageId` aktuell global statt profilbezogen gespeichert?
- Welche RPCs muessen fuer Trainerzugriff erweitert werden?
- Welche RLS-Policies muessen accountbezogene und profilbezogene Sicht sauber trennen?
- Wie werden bestehende Testdaten eindeutig oder halbautomatisch migriert?

## 25. Empfehlung

Die beste Loesung ist nicht, Eltern, Kinder, Erwachsene, Trainer und Admins als getrennte Sonderfaelle zu bauen.

Die beste Loesung ist:

Account als Kontakt- und Rechtehuelle.

Subject Profile als trainierende Person.

Alles Trainingsbezogene haengt am Subject Profile.

Alles Kommunikations-, Rollen- und Zahlungsbezogene haengt am Account.

Das ist fuer den MVP etwas mehr Strukturarbeit, verhindert aber spaeter deutlich groessere Umbauten.
