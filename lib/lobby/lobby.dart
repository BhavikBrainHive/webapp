import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
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
              current is OnPlayerReadyState ||
              current is LobbyExitedState ||
              current is RoomExpiredState,
          listener: (_, state) {
            if (state is OnPlayerReadyState) {
              Navigator.pushReplacementNamed(
                context,
                '/gamePlay',
                arguments: state.session,
              );
            } else if (state is LobbyExitedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Room has been cancelled!!")));
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (Route<dynamic> route) => false,
              );
            } else if (state is RoomExpiredState) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Your room has been expired!!")));
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<LobbyBloc, LobbyState>(
                      buildWhen: (_, current) =>
                          current is TimerRunningState ||
                          current is RoomExpiredState,
                      builder: (_, state) {
                        final remainingTime = state is TimerRunningState
                            ? state.remainingTime
                            : 0;
                        if (remainingTime > 0) {
                          return Text(
                            'Room will expire in\n${formatSecondsToMMSS(remainingTime)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    BlocBuilder<LobbyBloc, LobbyState>(
                      buildWhen: (_, current) =>
                          current is LobbyPlayerUpdatedState,
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
                                  color: Colors.green,
                                ),
                              ),
                            if (player2 != null)
                              SizedBox(
                                height: 30.h,
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _buildPlayerCard(
                                    player1,
                                    player1Ready,
                                    currentUserId,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPlayerCard(
                                    player2,
                                    player2Ready,
                                    currentUserId,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            if (!player1Ready || !player2Ready)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(
                                        10.r,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        onTap: () => _lobbyBloc?.add(
                                          LobbyPlayerReadyEvent(
                                            !isReady,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 12.w,
                                          ),
                                          child: Text(
                                            isReady ? 'Cancel Ready' : 'Ready',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(
                                        10.r,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        onTap: () => _lobbyBloc?.add(
                                          LobbyPlayerCancelEvent(),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 12.w,
                                          ),
                                          child: Text(
                                            isAdmin ? 'Cancel Game' : 'Discard',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (!player1Ready || !player2Ready)
                              const SizedBox(
                                height: 25,
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
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
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

  String formatSecondsToMMSS(int totalSeconds) {
    int minutes = totalSeconds ~/ 60; // Calculate minutes
    int seconds = totalSeconds % 60; // Calculate remaining seconds

    if (minutes == 0) {
      return '${seconds.toString().padLeft(2, '0')}s';
    }
    // Format as mm:ss, ensuring two digits for minutes and seconds
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15.sp,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          isReady ? 'Ready' : 'Not Ready',
          style: TextStyle(
            fontWeight: FontWeight.w200,
            fontSize: 13.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
