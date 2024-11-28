abstract class GameplayState {}

class GameplayInitialState extends GameplayState {}

class TimerRunningState extends GameplayState {
  final int remainingTime;

  TimerRunningState({
    required this.remainingTime,
  });
}

class TimerCompleteState extends GameplayState {}

class OnScoreChangeState extends GameplayState {
  final int score;

  OnScoreChangeState({
    required this.score,
  });
}

class GameplayLoadingState extends GameplayState {
  final bool isLoading;

  GameplayLoadingState({
    this.isLoading = true,
  });
}
