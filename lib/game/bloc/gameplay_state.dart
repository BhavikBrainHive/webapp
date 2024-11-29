abstract class GameplayState {}

class GameplayInitialState extends GameplayState {}

class TimerRunningState extends GameplayState {
  final int remainingTime;

  TimerRunningState({
    required this.remainingTime,
  });
}

class GameCompleteState extends GameplayState {
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final bool isWinner;
  final bool isDraw;

  GameCompleteState({
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    required this.isWinner,
    required this.isDraw,
  });
}

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
