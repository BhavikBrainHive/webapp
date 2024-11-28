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
          ModalRoute.of(context)?.settings.arguments as GameSession?;
      _gameplayBloc ??= BlocProvider.of<GameplayBloc>(context);
      _gameplayBloc?.add(
        GameplayInitialEvent(
          gameSession: GameSession(
            sessionId: 'mpskrouehuiFof9YjmmD',
          ),
        ),
      );
    }
    super.didChangeDependencies();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (timer > 0) {
        setState(() {
          timer--;
        });
        startTimer();
      } else {
        /*Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(score: score)),
        );*/
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Time Left: $timer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              BlocBuilder<GameplayBloc, GameplayState>(
                buildWhen: (_, current) => current is OnScoreChangeState,
                builder: (_, state) {
                  final score = state is OnScoreChangeState ? state.score : 0;
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
      ),
    );
  }
}
