import 'package:webapp/model/game_session.dart';

abstract class LobbyEvent {}

class LobbyInitialEvent extends LobbyEvent {
  final GameSession gameSession;

  LobbyInitialEvent({
    required this.gameSession,
  });
}

class LobbyPlayerCancelEvent extends LobbyEvent {}

class OnDestroyEvent extends LobbyEvent {}

class LobbyPlayerReadyEvent extends LobbyEvent {
  final bool isReady;

  LobbyPlayerReadyEvent(this.isReady);
}
