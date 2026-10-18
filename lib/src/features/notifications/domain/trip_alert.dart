/// The payload of the local "your trip is paused" notification, so a tap on
/// it can be told apart from a county arrival.
const tripPausedPayload = 'trip_paused';

/// How long a trip stays paused (with the app in the background) before the
/// reminder, and the shortest wait once the app is backgrounded.
const tripPausedReminderDelay = Duration(minutes: 10);
const tripPausedReminderMinLead = Duration(minutes: 2);
