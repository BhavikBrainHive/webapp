import 'package:webapp/model/game_session.dart';

abstract class LobbyEvent {}

class LobbyInitialEvent extends LobbyEvent {
  final GameSession gameSession;

  LobbyInitialEvent({
    required this.gameSession,
  });
}
