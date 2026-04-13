// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CoreJourney';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSent => 'We\'ve sent you a password reset email.';

  @override
  String get authErrorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'This email address is already registered.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 8 characters.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Start Training';

  @override
  String currentDay(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get dailyStreak => 'Daily Streak';

  @override
  String weeklyProgress(int count, int goal) {
    return '$count of $goal this week';
  }

  @override
  String get goldenDay => 'Golden Day';

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get trainingMode => 'Training Mode';

  @override
  String get tutorialMode => 'Tutorial';

  @override
  String get routineMode => 'Routine';

  @override
  String get silentMode => 'Silent';

  @override
  String get hapticMode => 'Haptic';

  @override
  String get voiceCuesMode => 'Voice & Cues';

  @override
  String get exercisePosition => 'Starting Position';

  @override
  String get exerciseMovement => 'Movement';

  @override
  String get exerciseHints => 'Tips';

  @override
  String exerciseReps(int count) {
    return '$count repetitions';
  }

  @override
  String get sessionComplete => 'Session Complete';

  @override
  String get sessionCompleteSubtitle =>
      'Well done! You\'ve completed your training for today.';

  @override
  String get moodCheckIn => 'How are you feeling?';

  @override
  String get moodLabel => 'Mood';

  @override
  String get energyLabel => 'Energy';

  @override
  String get stressLabel => 'Stress';

  @override
  String get moodSkip => 'Skip';

  @override
  String get moodSubmit => 'Save';

  @override
  String get moodChartEmpty =>
      'Complete a training session to start tracking your mood.';

  @override
  String get intakeAssessmentTitle => 'Getting Started';

  @override
  String get intakeWelcomeTitle => 'Welcome to your Reflex Integration Program';

  @override
  String get intakeWelcomeBody =>
      'CoreJourney guides you through the integration of prenatal reflexes — a process that can help transform deeply rooted physical and emotional patterns.';

  @override
  String get intakeTrainerTitle => 'Recommendation: Start with a Trainer';

  @override
  String get intakeTrainerBody =>
      'We recommend beginning and accompanying this program with a certified trainer. A trainer carries out isometric activation training to specifically target the relevant reflexes. This targeted activation accelerates the integration process. Without it, the body typically takes longer to engage the reflexes sufficiently.';

  @override
  String get intakeQuestionLabel => 'One question about your start';

  @override
  String get questionIsometricWithTrainer =>
      'Have you already completed isometric activation training with a trainer?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String durationRecommendation(int weeks) {
    return 'Recommended duration: $weeks weeks';
  }

  @override
  String get adjustDuration => 'Adjust Duration';

  @override
  String get confirm => 'Confirm';

  @override
  String get completionQuestionnaireTitle => 'Final Reflection';

  @override
  String get completionCelebrationTitle => 'Block Complete! ⭐';

  @override
  String get completionCelebrationSubtitle =>
      'You\'ve completed an important step in your development. Well done.';

  @override
  String get completionNextPackage => 'Continue to next package';

  @override
  String get completionBackToDashboard => 'Back to Dashboard';

  @override
  String get completionExtendedTitle => 'One more week';

  @override
  String get completionExtendedSubtitle =>
      'No problem — you have 7 more days. Keep going.';

  @override
  String get completionQuestion =>
      'Did you go through an intensified emotional or stressful time through the training, and were you able to confront these themes — learning that your emotional reaction does not always match reality — and begin to regulate yourself?';

  @override
  String get completionYes => 'Yes, I\'m ready';

  @override
  String get completionNotYet => 'Not yet';

  @override
  String get packages => 'Program';

  @override
  String get packageLocked => 'Locked';

  @override
  String get packageCurrent => 'Current';

  @override
  String get packageCompleted => 'Completed';

  @override
  String get packageAvailable => 'Available';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTraining => 'Training';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsWeeklyGoal => 'Weekly Goal';

  @override
  String get settingsChildAssist => 'Child-Assist Mode';

  @override
  String get settingsConnectTrainer => 'Connect to Trainer';

  @override
  String get reminderEnabled => 'Reminders enabled';

  @override
  String get reminderWindow => 'Reminder window';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get reminderFrom => 'From';

  @override
  String get reminderTo => 'To';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String weeklyGoalSessions(int goal) {
    return '$goal sessions/week';
  }

  @override
  String get settingsFeedback => 'Training Feedback';

  @override
  String get settingsAccount => 'Account';

  @override
  String get disclaimer => 'Health Notice';

  @override
  String get disclaimerText =>
      'This training does not replace medical treatment. Please consult a doctor if you have health concerns. Listen to your body and take breaks when needed.';

  @override
  String get disclaimerAccept => 'Understood, continue';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoNetwork => 'No internet connection.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get trainerClients => 'My Clients';

  @override
  String get trainerNoClients => 'No clients linked yet.';

  @override
  String get trainerNoClientsHint =>
      'Generate an invite code and share it with your client.';

  @override
  String get trainerInviteCode => 'Invite Code';

  @override
  String get trainerInviteCodeHint =>
      'Share this code with your client. It can be used once.';

  @override
  String get trainerGenerateCode => 'New Invite';

  @override
  String get trainerCopyCode => 'Copy Code';

  @override
  String get trainerCodeCopied => 'Code copied to clipboard.';

  @override
  String get trainerAtRisk => 'at risk';

  @override
  String trainerLastActive(int days) {
    return '${days}d ago';
  }

  @override
  String get trainerNotes => 'Trainer Notes';

  @override
  String get trainerNotesHint => 'Private notes about this client...';

  @override
  String get trainerNotesSaved => 'Notes saved.';

  @override
  String get trainerRecentSessions => 'Recent Sessions (30 days)';

  @override
  String get trainerNoSessions => 'No sessions in the last 30 days.';

  @override
  String get trainerView => 'Trainer View';

  @override
  String get connectToTrainer => 'Connect to Trainer';

  @override
  String get enterInviteCode => 'Enter invite code';

  @override
  String get connectToTrainerSuccess => 'Connected to trainer!';

  @override
  String get connectToTrainerError => 'Invalid or expired invite code.';

  @override
  String get loading => 'Loading...';

  @override
  String get skip => 'Skip';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String weeksCount(int count) {
    return '$count weeks';
  }

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get thisWeek => 'This Week';

  @override
  String get journal => 'Journal';

  @override
  String get journalEmptyTitle => 'No entries yet.';

  @override
  String get journalEmptySubtitle =>
      'Write down what you observe in your daily life — after each training or whenever you like.';

  @override
  String get journalEmptyHint =>
      'Keep track of what changes in your daily life.';

  @override
  String get journalNewEntry => 'New Note';

  @override
  String get journalPostTrainingTitle => 'Changes in everyday life?';

  @override
  String get journalPostTrainingHint =>
      'Have you noticed anything — in your sleep, your reactions, your body awareness?';

  @override
  String get journalPlaceholder => 'Write your observation here...';

  @override
  String get journalLoadFailed => 'Could not load entries.';

  @override
  String get moodHistory => 'Mood History';

  @override
  String get profile => 'Profile';

  @override
  String get completionBannerTitle => 'Block complete!';

  @override
  String get completionBannerSubtitle =>
      'You\'ve reached your target date. Time for your final reflection.';

  @override
  String get settingsDataSync => 'Data & Sync';

  @override
  String get syncStatusOk => 'All synced';

  @override
  String syncStatusPending(int count) {
    return '$count entries pending';
  }

  @override
  String syncStatusFailed(int count) {
    return '$count entries failed';
  }

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncNow => 'Sync now';

  @override
  String get errorSaveFailed => 'Save failed. Please try again.';

  @override
  String get errorLoadFailed => 'Failed to load data.';

  @override
  String get errorLoadFailedInline => 'Failed to load';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationInvalidEmail => 'Please enter a valid email address.';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileChangePasswordSent => 'Password reset email sent.';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteAccountTitle => 'Delete Account?';

  @override
  String get profileDeleteAccountBody =>
      'This permanently deletes your account and all your data. This cannot be undone.';

  @override
  String get profileDeleteAccountConfirm => 'Delete permanently';

  @override
  String get profileDeleteAccountSuccess => 'Account deleted.';

  @override
  String get profileDeleteAccountError =>
      'Could not delete account. Please contact support.';

  @override
  String get trainerDashboard => 'Trainer Dashboard';

  @override
  String get trainerTabTrainees => 'Trainees';

  @override
  String get trainerTabCalendar => 'Calendar';

  @override
  String get trainerMyLink => 'My Invite Link';

  @override
  String get trainerCopyLink => 'Copy Link';

  @override
  String get trainerLinkCopied => 'Link copied.';

  @override
  String get trainerScheduleAppointment => 'Schedule';

  @override
  String get trainerBookNow => 'Book Now';

  @override
  String get trainerAppointmentMissing => 'Appointment Missing';

  @override
  String get trainerNoAppointments => 'No appointments scheduled.';

  @override
  String get appointmentSchedulerTitle => 'Book Appointment';

  @override
  String appointmentWith(String name) {
    return 'Appointment with $name';
  }

  @override
  String get appointmentSessionTitle => 'Isometric Partner Exercise';

  @override
  String get appointmentFreeSlotsTitle => 'Free slots (next 14 days):';

  @override
  String get appointmentBook => 'Book';

  @override
  String get appointmentOtherTime => 'Choose different time';

  @override
  String get appointmentLocationLabel => 'Location (optional)';

  @override
  String get appointmentNotesLabel => 'Note';

  @override
  String get appointmentConfirmButton => 'Book Appointment';

  @override
  String get appointmentLoadingSlots => 'Searching for free slots...';

  @override
  String get appointmentNoFreeSlots => 'No free slots found.';

  @override
  String get appointmentNoCalendars => 'No calendars found.';

  @override
  String get appointmentSelectCalendarTitle => 'Select Work Calendar';

  @override
  String get appointmentSelectCalendarSubtitle =>
      'Select the calendar for CoreJourney appointments.';

  @override
  String get appointmentStatusPlanned => 'Planned';

  @override
  String get appointmentStatusConfirmed => 'Confirmed';

  @override
  String get appointmentStatusCancelled => 'Cancelled';

  @override
  String get appointmentStatusDone => 'Completed';

  @override
  String get appointmentOpenInCalendar => 'Open in Calendar';
}
