// lib/models/event_with_stats_status.dart

import '../screens/schedule_screen.dart' as app_event;

class EventWithStatsStatus {
  final app_event.ScheduleEvent event;
  final bool hasStats;

  EventWithStatsStatus({required this.event, required this.hasStats});
}
