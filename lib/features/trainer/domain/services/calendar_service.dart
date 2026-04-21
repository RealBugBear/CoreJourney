import 'package:add_2_calendar/add_2_calendar.dart';

import '../../../../core/logging/app_logger.dart';

class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot({required this.start, required this.end});

  String get formattedRange {
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s – $e';
  }
}

/// Opens the native system calendar app with pre-filled event data.
/// No permission prompt needed — the calendar app handles it.
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  Future<void> createCalendarEvent({
    required String title,
    required DateTime start,
    required Duration duration,
    String? location,
    String? description,
  }) async {
    try {
      final event = Event(
        title: title,
        description: description ?? '',
        location: location ?? '',
        startDate: start,
        endDate: start.add(duration),
        allDay: false,
      );
      await Add2Calendar.addEvent2Cal(event);
      appLogger.d('CalendarService: event handed off to system calendar');
    } catch (e, st) {
      appLogger.e('CalendarService: failed to open calendar', error: e, stackTrace: st);
      rethrow;
    }
  }
}
