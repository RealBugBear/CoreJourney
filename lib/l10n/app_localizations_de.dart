// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'CoreJourney';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get passwordResetSent =>
      'Wir haben dir eine E-Mail zum Zurücksetzen des Passworts gesendet.';

  @override
  String get authErrorInvalidCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authErrorEmailInUse =>
      'Diese E-Mail-Adresse ist bereits registriert.';

  @override
  String get authErrorWeakPassword =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Training starten';

  @override
  String currentDay(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String get dailyStreak => 'Tages-Streak';

  @override
  String weeklyProgress(int count, int goal) {
    return '$count von $goal diese Woche';
  }

  @override
  String get goldenDay => 'Golden Day';

  @override
  String daysRemaining(int days) {
    return '$days Tage verbleibend';
  }

  @override
  String get trainingMode => 'Trainingsmodus';

  @override
  String get tutorialMode => 'Tutorial';

  @override
  String get routineMode => 'Routine';

  @override
  String get silentMode => 'Silent';

  @override
  String get hapticMode => 'Haptisch';

  @override
  String get voiceCuesMode => 'Stimme & Cues';

  @override
  String get exercisePosition => 'Ausgangsposition';

  @override
  String get exerciseMovement => 'Bewegung';

  @override
  String get exerciseHints => 'Hinweise';

  @override
  String exerciseReps(int count) {
    return '$count Wiederholungen';
  }

  @override
  String get sessionComplete => 'Training abgeschlossen';

  @override
  String get sessionCompleteSubtitle =>
      'Gut gemacht! Du hast dein Training für heute abgeschlossen.';

  @override
  String get moodCheckIn => 'Wie geht es dir?';

  @override
  String get moodLabel => 'Stimmung';

  @override
  String get energyLabel => 'Energie';

  @override
  String get stressLabel => 'Stress';

  @override
  String get moodSkip => 'Überspringen';

  @override
  String get moodSubmit => 'Speichern';

  @override
  String get moodChartEmpty =>
      'Schließe eine Trainingseinheit ab, um deine Stimmung zu verfolgen.';

  @override
  String get intakeAssessmentTitle => 'Programmstart';

  @override
  String get intakeWelcomeTitle =>
      'Willkommen in deinem Reflexintegrations-Programm';

  @override
  String get intakeWelcomeBody =>
      'CoreJourney begleitet dich bei der Integration pränataler Reflexe — ein Prozess, der dabei helfen kann, tief verwurzelte körperliche und emotionale Muster zu transformieren.';

  @override
  String get intakeTrainerTitle => 'Empfehlung: Mit Trainer starten';

  @override
  String get intakeTrainerBody =>
      'Wir empfehlen, das Programm mit einem zertifizierten Trainer zu beginnen und begleiten zu lassen. Ein Trainer führt isometrisches Aktivierungstraining durch, das die betreffenden Reflexe gezielt anspricht. Diese gezielte Aktivierung beschleunigt den Integrationsprozess. Ohne sie braucht der Körper in der Regel länger, bis die Reflexe ausreichend angesprochen werden.';

  @override
  String get intakeQuestionLabel => 'Eine Frage zu deinem Start';

  @override
  String get questionIsometricWithTrainer =>
      'Hast du bereits isometrisches Aktivierungstraining mit einem Trainer durchgeführt?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String durationRecommendation(int weeks) {
    return 'Empfohlene Dauer: $weeks Wochen';
  }

  @override
  String get adjustDuration => 'Dauer anpassen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get completionQuestionnaireTitle => 'Abschlussreflexion';

  @override
  String get completionCelebrationTitle => 'Block abgeschlossen! ⭐';

  @override
  String get completionCelebrationSubtitle =>
      'Du hast einen wichtigen Schritt in deiner Entwicklung abgeschlossen. Gut gemacht.';

  @override
  String get completionNextPackage => 'Weiter zum nächsten Paket';

  @override
  String get completionBackToDashboard => 'Zum Dashboard';

  @override
  String get completionExtendedTitle => 'Noch eine Woche';

  @override
  String get completionExtendedSubtitle =>
      'Kein Problem — du hast 7 weitere Tage. Mach weiter so.';

  @override
  String get completionQuestion =>
      'Hattest du durch das Training eine verstärkte emotionale oder stressige Zeit und konntest dich mit diesen Themen konfrontieren – zu erkennen, dass deine emotionale Reaktion nicht immer mit der Realität übereinstimmt – und anfangen dich zu regulieren?';

  @override
  String get completionYes => 'Ja, ich bin bereit';

  @override
  String get completionNotYet => 'Noch nicht';

  @override
  String get packages => 'Programm';

  @override
  String get packageLocked => 'Gesperrt';

  @override
  String get packageCurrent => 'Aktuell';

  @override
  String get packageCompleted => 'Abgeschlossen';

  @override
  String get packageAvailable => 'Verfügbar';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsTraining => 'Training';

  @override
  String get settingsReminders => 'Erinnerungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsTheme => 'Erscheinungsbild';

  @override
  String get settingsWeeklyGoal => 'Wochenziel';

  @override
  String get settingsChildAssist => 'Kinderunterstützung';

  @override
  String get settingsConnectTrainer => 'Trainer verbinden';

  @override
  String get reminderEnabled => 'Erinnerungen aktiviert';

  @override
  String get reminderWindow => 'Erinnerungsfenster';

  @override
  String get quietHours => 'Ruhezeiten';

  @override
  String get reminderFrom => 'Von';

  @override
  String get reminderTo => 'Bis';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String weeklyGoalSessions(int goal) {
    return '$goal Einheiten/Woche';
  }

  @override
  String get settingsFeedback => 'Trainings-Feedback';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get disclaimer => 'Medizinischer Hinweis';

  @override
  String get disclaimerText =>
      'Dieses Training ersetzt keine medizinische Behandlung. Bitte konsultiere einen Arzt, wenn du gesundheitliche Bedenken hast. Achte auf die Signale deines Körpers und mache Pausen, wenn nötig.';

  @override
  String get disclaimerAccept => 'Verstanden, weiter';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorNoNetwork => 'Keine Internetverbindung.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get trainerClients => 'Meine Klienten';

  @override
  String get trainerNoClients => 'Noch keine Klienten verknüpft.';

  @override
  String get trainerNoClientsHint =>
      'Erstelle einen Einladungscode und teile ihn mit deinem Klienten.';

  @override
  String get trainerInviteCode => 'Einladungscode';

  @override
  String get trainerInviteCodeHint =>
      'Teile diesen Code mit deinem Klienten. Er kann einmalig verwendet werden.';

  @override
  String get trainerGenerateCode => 'Einladung erstellen';

  @override
  String get trainerCopyCode => 'Code kopieren';

  @override
  String get trainerCodeCopied => 'Code in die Zwischenablage kopiert.';

  @override
  String get trainerAtRisk => 'Risiko';

  @override
  String trainerLastActive(int days) {
    return 'Vor $days Tag(en)';
  }

  @override
  String get trainerNotes => 'Trainer-Notizen';

  @override
  String get trainerNotesHint => 'Private Notizen zu diesem Klienten...';

  @override
  String get trainerNotesSaved => 'Notizen gespeichert.';

  @override
  String get trainerRecentSessions => 'Letzte Einheiten (30 Tage)';

  @override
  String get trainerNoSessions => 'Keine Einheiten in den letzten 30 Tagen.';

  @override
  String get trainerView => 'Trainer-Ansicht';

  @override
  String get connectToTrainer => 'Mit Trainer verbinden';

  @override
  String get enterInviteCode => 'Einladungscode eingeben';

  @override
  String get connectToTrainerSuccess => 'Mit Trainer verbunden!';

  @override
  String get connectToTrainerError =>
      'Ungültiger oder abgelaufener Einladungscode.';

  @override
  String get loading => 'Lädt...';

  @override
  String get skip => 'Überspringen';

  @override
  String dayNumber(int day) {
    return 'Tag $day';
  }

  @override
  String weeksCount(int count) {
    return '$count Wochen';
  }

  @override
  String daysCount(int count) {
    return '$count Tage';
  }

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get journal => 'Tagebuch';

  @override
  String get journalEmptyTitle => 'Noch keine Einträge.';

  @override
  String get journalEmptySubtitle =>
      'Schreib auf, was du in deinem Alltag beobachtest — nach jedem Training oder wann immer du möchtest.';

  @override
  String get journalEmptyHint =>
      'Halte fest, was sich in deinem Alltag verändert.';

  @override
  String get journalNewEntry => 'Neue Notiz';

  @override
  String get journalPostTrainingTitle => 'Veränderungen im Alltag?';

  @override
  String get journalPostTrainingHint =>
      'Hast du etwas bemerkt — in deinem Schlaf, deinen Reaktionen, deinem Körpergefühl?';

  @override
  String get journalPlaceholder => 'Schreib hier deine Beobachtung...';

  @override
  String get journalLoadFailed => 'Einträge konnten nicht geladen werden.';

  @override
  String get moodHistory => 'Stimmungsverlauf';

  @override
  String get profile => 'Profil';

  @override
  String get completionBannerTitle => 'Block abgeschlossen!';

  @override
  String get completionBannerSubtitle =>
      'Du hast dein Zieldatum erreicht. Jetzt zur Abschlussreflexion.';

  @override
  String get settingsDataSync => 'Daten & Sync';

  @override
  String get syncStatusOk => 'Alles synchronisiert';

  @override
  String syncStatusPending(int count) {
    return '$count Einträge ausstehend';
  }

  @override
  String syncStatusFailed(int count) {
    return '$count Einträge fehlgeschlagen';
  }

  @override
  String get syncInProgress => 'Synchronisiert...';

  @override
  String get syncNow => 'Jetzt sync';

  @override
  String get errorSaveFailed =>
      'Speichern fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get errorLoadFailed => 'Daten konnten nicht geladen werden.';

  @override
  String get errorLoadFailedInline => 'Fehler beim Laden';

  @override
  String get validationRequired => 'Dieses Feld ist erforderlich.';

  @override
  String get validationInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get validationPasswordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileChangePassword => 'Passwort ändern';

  @override
  String get profileChangePasswordSent =>
      'Passwort-Reset-E-Mail wurde gesendet.';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get passwordConfirm => 'Passwort bestätigen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get passwordChanged => 'Passwort erfolgreich geändert.';

  @override
  String get passwordSet => 'Neues Passwort gesetzt. Bitte einloggen.';

  @override
  String get authErrorSamePassword =>
      'Das neue Passwort muss sich vom bisherigen unterscheiden.';

  @override
  String get authErrorInvalidCurrentPassword =>
      'Das aktuelle Passwort ist falsch.';

  @override
  String get validationPasswordMismatch => 'Passwörter stimmen nicht überein.';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String get profileDeleteAccountTitle => 'Konto löschen?';

  @override
  String get profileDeleteAccountBody =>
      'Dein Konto und alle deine Daten werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get profileDeleteAccountConfirm => 'Dauerhaft löschen';

  @override
  String get profileDeleteAccountSuccess => 'Konto gelöscht.';

  @override
  String get profileDeleteAccountError =>
      'Konto konnte nicht gelöscht werden. Bitte kontaktiere den Support.';

  @override
  String get trainerDashboard => 'Trainer-Dashboard';

  @override
  String get trainerTabTrainees => 'Trainees';

  @override
  String get trainerTabCalendar => 'Kalender';

  @override
  String get trainerMyLink => 'Mein Einladungslink';

  @override
  String get trainerCopyLink => 'Link kopieren';

  @override
  String get trainerLinkCopied => 'Link kopiert.';

  @override
  String get trainerScheduleAppointment => 'Planen';

  @override
  String get trainerBookNow => 'Jetzt buchen';

  @override
  String get trainerAppointmentMissing => 'Termin fehlt';

  @override
  String get trainerNoAppointments => 'Keine Termine geplant.';

  @override
  String get appointmentSchedulerTitle => 'Termin buchen';

  @override
  String appointmentWith(String name) {
    return 'Termin mit $name';
  }

  @override
  String get appointmentSessionTitle => 'Isometrische Partnerübung';

  @override
  String get appointmentFreeSlotsTitle => 'Freie Zeiten (nächste 14 Tage):';

  @override
  String get appointmentBook => 'Buchen';

  @override
  String get appointmentOtherTime => 'Andere Zeit wählen';

  @override
  String get appointmentLocationLabel => 'Ort (optional)';

  @override
  String get appointmentNotesLabel => 'Notiz';

  @override
  String get appointmentConfirmButton => 'Termin buchen';

  @override
  String get appointmentLoadingSlots => 'Freie Zeiten werden gesucht...';

  @override
  String get appointmentNoFreeSlots => 'Keine freien Zeitfenster gefunden.';

  @override
  String get appointmentNoCalendars => 'Keine Kalender gefunden.';

  @override
  String get appointmentSelectCalendarTitle => 'Arbeitskalender wählen';

  @override
  String get appointmentSelectCalendarSubtitle =>
      'Wähle den Kalender für CoreJourney-Termine.';

  @override
  String get appointmentStatusPlanned => 'Geplant';

  @override
  String get appointmentStatusConfirmed => 'Bestätigt';

  @override
  String get appointmentStatusCancelled => 'Abgesagt';

  @override
  String get appointmentStatusDone => 'Abgeschlossen';

  @override
  String get appointmentOpenInCalendar => 'Im Kalender öffnen';

  @override
  String get trainerRequestsTitle => 'Anfragen';

  @override
  String get trainerRequestNoRequests => 'Keine offenen Anfragen.';

  @override
  String get trainerRequestAccept => 'Annehmen';

  @override
  String get trainerRequestDecline => 'Ablehnen';

  @override
  String get trainerDiscoveryTitle => 'Trainer finden';

  @override
  String get trainerDiscoveryLocationDenied =>
      'Standortzugriff ist erforderlich, um Trainer in deiner Nähe zu finden.';

  @override
  String trainerDiscoveryRadiusLabel(int radius) {
    return '$radius km';
  }

  @override
  String get trainerDiscoveryEmpty => 'Keine Trainer in der Nähe gefunden.';

  @override
  String trainerDiscoveryDistanceLabel(double distance) {
    return '$distance km entfernt';
  }

  @override
  String get trainerDiscoveryRequestAlreadySent =>
      'Anfrage wurde bereits gesendet.';

  @override
  String get trainerDiscoveryRequestAlreadyConnected =>
      'Du bist bereits mit diesem Trainer verbunden.';

  @override
  String get trainerDiscoveryRequestSent => 'Anfrage gesendet.';

  @override
  String get trainerDiscoverySendRequest => 'Anfrage senden';

  @override
  String get trainerPublicProfileTitle => 'Trainer-Profil';

  @override
  String get trainerPublicProfileVerified => 'Verifizierter Trainer';

  @override
  String get trainerSetupTitle => 'Trainer-Profil';

  @override
  String get trainerSetupDisplayNameLabel => 'Anzeigename';

  @override
  String get trainerSetupBioLabel => 'Bio';

  @override
  String get trainerSetupEmailLabel => 'E-Mail';

  @override
  String get trainerSetupPhoneLabel => 'Telefon';

  @override
  String get trainerSetupLocationTitle => 'Standort';

  @override
  String get trainerSetupLocationHint =>
      'Wähle deinen Trainer-Standort, damit Klienten dich in der Nähe finden.';

  @override
  String get trainerSetupLocationMissing => 'Bitte wähle einen Standort.';

  @override
  String get trainerSetupSubmit => 'Zur Prüfung einreichen';

  @override
  String get trainerSetupPendingTitle => 'Profil wird geprüft';

  @override
  String get trainerSetupPendingBody =>
      'Wir benachrichtigen dich, sobald dein Trainer-Profil freigegeben ist.';

  @override
  String get adminTrainerReviewTab => 'Trainer-Prüfung';

  @override
  String get adminTrainerNoPending => 'Keine Trainer-Profile zur Prüfung.';

  @override
  String get adminTrainerApproveSuccess => 'Trainer freigegeben.';

  @override
  String get adminTrainerSuspendSuccess => 'Trainer gesperrt.';

  @override
  String get adminTrainerApprove => 'Freigeben';

  @override
  String get adminTrainerSuspend => 'Sperren';
}
