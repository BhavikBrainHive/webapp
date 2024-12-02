import 'package:webapp/model/game_session.dart';

abstract class LobbyEvent {}

class LobbyInitialEvent extends LobbyEvent {
  final GameSession gameSession;

  LobbyInitialEvent({
    required this.gameSession,
  });
}

class LobbyPlayerCancelEvent extends LobbyEvent {}

class LobbyPlayerReadyEvent extends LobbyEvent {
  final bool isReady;

  LobbyPlayerReadyEvent(this.isReady);
}

class StopTimerEvent extends LobbyEvent {
  final bool isExpired;

  StopTimerEvent({
    this.isExpired = true,
  });
}

class StartTimerEvent extends LobbyEvent {
  final int duration;

  StartTimerEvent(
    this.duration,
  );
}

class TimerTickEvent extends LobbyEvent {
  final int remainingTime;

  TimerTickEvent(
    this.remainingTime,
  );
}
