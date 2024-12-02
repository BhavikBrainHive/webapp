abstract class PresenceState {}

class PresenceInitial extends PresenceState {}

class PresenceOnline extends PresenceState {}

class PresenceOffline extends PresenceState {}

class PresenceError extends PresenceState {
  final String error;

  PresenceError(this.error);
}
