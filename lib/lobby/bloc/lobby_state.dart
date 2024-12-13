import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

abstract class LobbyState {}

class LobbyInitialState extends LobbyState {}

class LobbyPlayerUpdatedState extends LobbyState {
  final UserProfile? player1, player2;
  final bool isHost;
  final String currentPlayerId;
  final bool isPlayer1Ready, isPlayer2Ready;

  LobbyPlayerUpdatedState({
    required this.player1,
    required this.player2,
    required this.isHost,
    required this.currentPlayerId,
    required this.isPlayer1Ready,
    required this.isPlayer2Ready,
  });
}

class LobbyLoadingState extends LobbyState {
  final bool isLoading;

  LobbyLoadingState({
    this.isLoading = true,
  });
}

class LobbyExitedState extends LobbyState {}

class OnPlayerReadyState extends LobbyState {
  final GameSession session;

  OnPlayerReadyState(this.session);
}

class TimerRunningState extends LobbyState {
  final int remainingTime;

  TimerRunningState({
    required this.remainingTime,
  });
}

class RoomExpiredState extends LobbyState {}
