import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

class GameHistoryModel {
  List<UserProfile?> players;
  GameSession gameSession;
  final bool isWinner;
  final bool isDraw;

  GameHistoryModel({
    required this.players,
    required this.gameSession,
    required this.isWinner,
    required this.isDraw,
  });
}
