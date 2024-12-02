import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:neon_widgets/neon_widgets.dart';
import 'package:webapp/game/bloc/gameplay_bloc.dart';
import 'package:webapp/game/bloc/gameplay_event.dart';
import 'package:webapp/game/bloc/gameplay_state.dart';
import 'package:webapp/model/game_session.dart';
import 'dart:html' as html;

class Gameplay extends StatefulWidget {
  const Gameplay({super.key});

  @override
  _GameplayState createState() => _GameplayState();
}

class _GameplayState extends State<Gameplay> {
  GameplayBloc? _gameplayBloc;

  @override
  void initState() {
    html.window.onBeforeUnload.listen((event) {
      // Prevent the default behavior
      event.preventDefault();
      // Set a custom return value (browsers ignore custom text in modern implementations)
      (event as html.BeforeUnloadEvent).returnValue = '';
    });
    super.initState();
  }

  @override
  Future<void> didChangeDependencies() async {
    if (_gameplayBloc == null) {
      final gameArgs =
          ModalRoute.of(context)?.settings.arguments as GameSession;
      _gameplayBloc ??= BlocProvider.of<GameplayBloc>(context);
      _gameplayBloc?.add(
        GameplayInitialEvent(
          gameSession: gameArgs,
        ),
      );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlocBuilder<GameplayBloc, GameplayState>(
                    buildWhen: (_, current) =>
                        current is TimerRunningState ||
                        current is GameCompleteState,
                    builder: (_, state) {
                      final remainingTime =
                          state is TimerRunningState ? state.remainingTime : 0;
                      if (remainingTime > 0) {
                        return Text(
                          'Time Left: ${formatSecondsToMMSS(remainingTime)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  BlocBuilder<GameplayBloc, GameplayState>(
                    buildWhen: (_, current) => current is OnScoreChangeState,
                    builder: (_, state) {
                      final score =
                          state is OnScoreChangeState ? state.score : 0;
                      return Text(
                        'Your Score: $score',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                    onPressed: () => _gameplayBloc?.add(
                      OnHitTapEvent(),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                    ),
                    child: const Text(
                      'Hit Me',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<GameplayBloc, GameplayState>(
              buildWhen: (_, current) => current is GameplayLoadingState,
              builder: (_, state) {
                final isLoading =
                    state is GameplayLoadingState && state.isLoading;
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
            BlocBuilder<GameplayBloc, GameplayState>(
              buildWhen: (_, current) => current is GameCompleteState,
              builder: (_, state) {
                final shouldShow = state is GameCompleteState;
                String? player1Name = shouldShow ? state.player1Name : '';
                String? player2Name = shouldShow ? state.player2Name : '';
                int player1Score = shouldShow ? state.player1Score : 0;
                int player2Score = shouldShow ? state.player2Score : 0;
                bool isWinner = shouldShow && state.isWinner;
                bool isDraw = shouldShow && state.isDraw;
                return AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  switchInCurve: Curves.elasticIn,
                  switchOutCurve: Curves.elasticIn,
                  child: shouldShow
                      ? Center(
                          child: FlickerNeonContainer(
                            flickerTimeInMilliSeconds: 0,
                            lightSpreadRadius: 10,
                            lightBlurRadius: 20,
                            borderRadius: BorderRadius.circular(10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/animation/gameover.json',
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.contain,
                                ),
                                FlickerNeonText(
                                  text: isDraw
                                      ? r"It's Draw"
                                      : (isWinner
                                          ? r"You've won!!"
                                          : r"You've lost"),
                                  flickerTimeInMilliSeconds: 0,
                                  textColor: Colors.white,
                                  spreadColor: Colors.white,
                                  blurRadius: 10,
                                  textSize: 35,
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '$player1Name',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            '$player1Score',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '$player2Name',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            '$player2Score',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 25,
                                ),
                                Material(
                                  type: MaterialType.transparency,
                                  child: FlickerNeonContainer(
                                    flickerTimeInMilliSeconds: 0,
                                    borderRadius: BorderRadius.circular(7),
                                    lightSpreadRadius: 0,
                                    lightBlurRadius: 0,
                                    borderWidth: 0.7,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(7),
                                        onTap: () {
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            '/home',
                                            (Route<dynamic> route) => false,
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            'Go to home',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                );
              },
            ),
          ],
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
}
