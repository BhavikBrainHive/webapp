import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/bloc/lobby_event.dart';
import 'package:webapp/lobby/bloc/lobby_state.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

import '../toast_widget.dart';

class Lobby extends StatefulWidget {
  const Lobby({Key? key}) : super(key: key);

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  LobbyBloc? _lobbyBloc;
  late FToast toastBuilder;

  @override
  void initState() {
    super.initState();
    toastBuilder = FToast();
    toastBuilder.init(context);
  }

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
              toastBuilder.showToast(
                gravity: ToastGravity.TOP,
                toastDuration: const Duration(
                  seconds: 3,
                ),
                child: const ToastWidget(
                  message: 'Room has been cancelled!!',
                  isSuccess: false,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (Route<dynamic> route) => false,
              );
            } else if (state is RoomExpiredState) {
              toastBuilder.showToast(
                gravity: ToastGravity.TOP,
                toastDuration: const Duration(
                  seconds: 3,
                ),
                child: const ToastWidget(
                  message: 'Your room has been expired!!',
                  isSuccess: false,
                ),
              );
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
                          isAdmin = state.isHost;
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
                            SizedBox(
                              height: 60.h,
                            ),
                            if (!player1Ready || !player2Ready)
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
                                        horizontal: 15.w,
                                        vertical: 10.w,
                                      ),
                                      child: Text(
                                        isAdmin ? 'Discard Game' : 'Exit Game',
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
    final isCurrentPlayer = player != null && loggedPlayerId == player.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          player?.name ?? (isCurrentPlayer ? 'Loading...' : 'Finding'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15.sp,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(
          height: 2.h,
        ),
        SizedBox(
          width: 145.w,
          height: 145.w,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/lobby_player_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              if (player != null)
                Center(
                  child: CircleAvatar(
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
                ),
            ],
          ),
        ),
        SizedBox(
          height: 10.h,
        ),
        Container(
          decoration: BoxDecoration(
            color: isCurrentPlayer
                ? (isReady ? Colors.redAccent : Colors.blueAccent)
                : player == null
                    ? Colors.blueAccent
                    : (isReady ? Colors.greenAccent : Colors.blueAccent),
            // color: Colors.blueAccent,
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
              onTap: isCurrentPlayer
                  ? () {
                      _lobbyBloc?.add(
                        LobbyPlayerReadyEvent(
                          !isReady,
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15.w,
                  vertical: 10.w,
                ),
                child: Text(
                  isCurrentPlayer
                      ? (isReady ? 'Cancel Ready' : 'Click to Ready')
                      : player == null
                          ? 'Finding Opponent'
                          : (isReady ? 'Ready' : 'Not Ready'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
