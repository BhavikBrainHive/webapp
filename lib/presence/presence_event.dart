abstract class PresenceEvent {}

class InitializePresence extends PresenceEvent {
  final String userId;

  InitializePresence(this.userId);
}

class UpdatePresence extends PresenceEvent {
  final bool isOnline;

  UpdatePresence(this.isOnline);
}

class DisablePresence extends PresenceEvent {}
