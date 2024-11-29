import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/game/bloc/gameplay_bloc.dart';
import 'package:webapp/game/bloc/gameplay_event.dart';
import 'package:webapp/game/bloc/gameplay_state.dart';
import 'package:webapp/model/game_session.dart';

class Gameplay extends StatefulWidget {
  const Gameplay({super.key});

  @override
  _GameplayState createState() => _GameplayState();
}

class _GameplayState extends State<Gameplay> {
  GameplayBloc? _gameplayBloc;

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
                        current is TimerCompleteState,
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
