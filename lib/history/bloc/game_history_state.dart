import 'package:webapp/history/model/game_history_model.dart';
import 'package:webapp/model/game_session.dart';

abstract class GameHistoryState {}

class GameHistoryInitialState extends GameHistoryState {}

class GameHistoryLoadingState extends GameHistoryState {
  final bool isLoading;

  GameHistoryLoadingState({
    this.isLoading = true,
  });
}

class GameHistoryDataUpdated extends GameHistoryState {
  final List<GameHistoryModel> gameHistoryList;
  final String currentPlayerId;

  GameHistoryDataUpdated({
    this.gameHistoryList = const [],
    required this.currentPlayerId,
  });
}
