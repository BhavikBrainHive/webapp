abstract class GameplayState {}

class GameplayInitialState extends GameplayState {}
class TimerRunningState extends GameplayState {
  final int remainingTime;

  TimerRunningState({
    required this.remainingTime,
  });
}

class TimerCompleteState extends GameplayState {}