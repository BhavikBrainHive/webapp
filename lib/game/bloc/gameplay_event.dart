import 'package:webapp/model/game_session.dart';

abstract class GameplayEvent {}

class GameplayInitialEvent extends GameplayEvent {
  final GameSession gameSession;

  GameplayInitialEvent({
    required this.gameSession,
  });
}

class StopTimerEvent extends GameplayEvent {}

class StartTimerEvent extends GameplayEvent {
  final int duration;

  StartTimerEvent(
    this.duration,
  );
}

class TimerTickEvent extends GameplayEvent {
  final int remainingTime;

  TimerTickEvent(
    this.remainingTime,
  );
}

class OnHitTapEvent extends GameplayEvent {}
