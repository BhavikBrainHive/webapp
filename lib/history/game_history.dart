import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/history/bloc/game_history_bloc.dart';
import 'package:webapp/history/bloc/game_history_state.dart';
import 'package:webapp/history/model/game_history_model.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

class GameHistory extends StatelessWidget {
  const GameHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Game History"),
      ),
      body: PopScope(
        child: Stack(
          children: [
            BlocBuilder<GameHistoryBloc, GameHistoryState>(
              buildWhen: (_, current) => current is GameHistoryDataUpdated,
              builder: (_, state) {
                final List<GameHistoryModel> list =
                    state is GameHistoryDataUpdated
                        ? state.gameHistoryList
                        : [];
                final currentUserId = state is GameHistoryDataUpdated
                    ? state.currentPlayerId
                    : FirebaseAuth.instance.currentUser?.uid;
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "No history found",
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: ListView.builder(
                    itemCount: list.length,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (_, pos) {
                      final currentItem = list[pos];
                      final players = currentItem.players;
                      final gameSession = currentItem.gameSession;
                      final isWinner = currentItem.isWinner;
                      final isDraw = currentItem.isDraw;
                      final amount = (gameSession.totalAmount ?? 0) / 2;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(pos + 1).toString()} - ${gameSession.sessionId.toUpperCase().substring(0, 5)}...',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: players
                                    .where((test) => test != null)
                                    .map((element) {
                                  final score =
                                      gameSession.scores?[element!.uid] ?? 0;
                                  return Expanded(
                                    child: _buildPlayerCard(
                                      element,
                                      currentUserId,
                                      score,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Center(
                              child: Text(
                                isDraw
                                    ? "The match went draw"
                                    : (isWinner
                                        ? "You've won +$amount"
                                        : "You had lost -$amount"),
                                style: TextStyle(
                                  color: isDraw
                                      ? Colors.black
                                      : (isWinner ? Colors.green : Colors.red),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 7,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            BlocBuilder<GameHistoryBloc, GameHistoryState>(
              buildWhen: (_, current) => current is GameHistoryLoadingState,
              builder: (_, state) {
                final isLoading =
                    state is GameHistoryLoadingState && state.isLoading;
                if (isLoading) {
                  return AbsorbPointer(
                    absorbing: isLoading,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    UserProfile? player,
    String? loggedPlayerId,
    int playerScore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: player?.photoUrl != null
              ? NetworkImage(
                  player!.photoUrl!,
                )
              : null,
          child: player?.photoUrl == null
              ? const Icon(
                  Icons.person,
                  size: 30,
                )
              : null,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          player?.name ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Score: $playerScore',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
