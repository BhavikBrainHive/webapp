import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/bloc/lobby_event.dart';
import 'package:webapp/lobby/bloc/lobby_state.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

class Lobby extends StatefulWidget {
  const Lobby({Key? key}) : super(key: key);

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  LobbyBloc? _lobbyBloc;

  @override
  Future<void> didChangeDependencies() async {
    if (_lobbyBloc == null) {
      final gameArgs =
          ModalRoute.of(context)?.settings.arguments as GameSession?;
      _lobbyBloc ??= BlocProvider.of<LobbyBloc>(context);
      if (gameArgs != null) {
        _lobbyBloc?.add(
          LobbyInitialEvent(
            gameSession: gameArgs,
          ),
        );
      } else {
        _lobbyBloc?.add(LobbyReloadEvent());
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: BlocListener<LobbyBloc, LobbyState>(
          listenWhen: (_, current) =>
              current is OnPlayerReadyState || current is LobbyExitedState,
          listener: (_, state) {
            if (state is OnPlayerReadyState) {
              Navigator.pushReplacementNamed(
                context,
                '/gamePlay',
                arguments: state.session,
              );
            } else if (state is LobbyExitedState) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (Route<dynamic> route) => false,
              );
            }
          },
          child: Stack(
            children: [
              Center(
                child: BlocBuilder<LobbyBloc, LobbyState>(
                  buildWhen: (_, current) => current is LobbyPlayerUpdatedState,
                  builder: (_, state) {
                    UserProfile? player1, player2;
                    bool player1Ready = false, player2Ready = false;
                    bool isReady = false;
                    bool isAdmin = false;
                    final currentUserId = state is LobbyPlayerUpdatedState
                        ? state.currentPlayerId
                        : FirebaseAuth.instance.currentUser?.uid;
                    if (state is LobbyPlayerUpdatedState) {
                      player1 = state.player1;
                      player2 = state.player2;
                      player1Ready = state.isPlayer1Ready;
                      player2Ready = state.isPlayer2Ready;
                      isReady = currentUserId == player1?.uid
                          ? player1Ready
                          : currentUserId == player2?.uid
                              ? player2Ready
                              : false;
                      isAdmin = currentUserId == player1?.uid;
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (player2 != null)
                          const Text(
                            'Match Found!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (player2 != null)
                          const SizedBox(
                            height: 20,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPlayerCard(
                              player1,
                              player1Ready,
                              currentUserId,
                            ),
                            _buildPlayerCard(
                              player2,
                              player2Ready,
                              currentUserId,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        if (!player1Ready || !player2Ready)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _lobbyBloc?.add(
                                  LobbyPlayerReadyEvent(
                                    !isReady,
                                  ),
                                ),
                                child: Text(
                                  isReady ? 'Cancel Ready' : 'Start Game',
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () => _lobbyBloc?.add(
                                  LobbyPlayerCancelEvent(),
                                ),
                                child: Text(
                                  isAdmin ? 'Cancel Game' : 'Discard',
                                ),
                              ),
                            ],
                          ),
                        if (!player1Ready || !player2Ready)
                          const SizedBox(
                            height: 20,
                          ),
                        if (player1Ready && player2Ready)
                          const Text(
                            'Game Starting!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          )
                        else
                          const Text(
                            'Waiting for all players to be ready...',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              BlocBuilder<LobbyBloc, LobbyState>(
                buildWhen: (_, current) => current is LobbyLoadingState,
                builder: (_, state) {
                  final isLoading =
                      state is LobbyLoadingState && state.isLoading;
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
      ),
    );
  }

  Widget _buildPlayerCard(
    UserProfile? player,
    bool isReady,
    String? loggedPlayerId,
  ) {
    final isCurrentPlayer = loggedPlayerId == player?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
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
          player?.name ??
              (isCurrentPlayer ? 'Loading...' : 'Waiting for Player'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          isReady ? 'Ready' : 'Not Ready',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _lobbyBloc?.add(
      OnDestroyEvent(),
    );
    super.dispose();
  }
}
