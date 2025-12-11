import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder(DateTime lastTrainingTime) async {
    // Schedule for the next day at the same time
    final now = tz.TZDateTime.now(tz.local);
    
    // Convert lastTrainingTime to TZDateTime
    // We want the time component from lastTrainingTime, but the date should be tomorrow relative to now
    // Actually, simpler: just add 24 hours to the lastTrainingTime, but ensure it's in the future relative to now.
    // If lastTrainingTime was just now, then lastTrainingTime + 24h is definitely in the future.
    
    // However, we want to be robust.
    // Let's say we want to schedule it for "Tomorrow at HH:MM" where HH:MM comes from lastTrainingTime.
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      lastTrainingTime.hour,
      lastTrainingTime.minute,
    );

    // If the constructed time is in the past (e.g. training was at 8am, now it's 9am), add 1 day.
    // But wait, the requirement is "after the last training".
    // If I train at 8am today, I want a reminder at 8am tomorrow.
    // So if I train now, I want a reminder in 24 hours.
    
    // Let's just use the time from lastTrainingTime and schedule it for tomorrow.
    scheduledDate = scheduledDate.add(const Duration(days: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Zeit für dein Training!',
      'Halte deinen Streak und trainiere jetzt.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Tägliche Erinnerung',
          channelDescription: 'Erinnerung an das tägliche Training',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // This makes it repeat daily at this time
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
