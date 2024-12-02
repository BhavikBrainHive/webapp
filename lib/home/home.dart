import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/home/bloc/home_event.dart';
import 'package:webapp/home/bloc/home_state.dart';
import 'package:webapp/model/user.dart';

import 'bloc/home_bloc.dart';
import 'dart:html' as html;
import 'dart:js_util' as jsUtil;
import 'dart:js' as js;

class Home extends StatelessWidget {
  const Home({super.key});

  void disableBackNavigation() {
    // Push a new state to prevent back navigation
    html.window.history
        .pushState(null, 'Disable Back', html.window.location.href);

    // Listen for popstate and re-push the state
    html.window.onPopState.listen((event) {
      html.window.history
          .pushState(null, 'Disable Back', html.window.location.href);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeBloc = BlocProvider.of<HomeBloc>(context, listen: false);
    return BlocConsumer<HomeBloc, HomeState>(
      buildWhen: (_, state) =>
          state is ProfileUpdatedState || state is ProfileLoadingState,
      listenWhen: (_, state) =>
          state is GameSessionFoundState || state is UserNotFoundState,
      listener: _listenHomeStates,
      builder: (_, state) {
        UserProfile? profile;
        if (state is ProfileUpdatedState) {
          profile = state.profile;
        } else {
          profile = homeBloc.userProfile;
        }
        final isLoading = profile == null ||
            (state is ProfileLoadingState && state.isLoading);
        return Scaffold(
          body: PopScope(
            canPop: false,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(profile?.photoUrl ?? ''),
                        radius: 50,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        profile?.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        "Wallet: ${profile?.wallet ?? 0}",
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      ElevatedButton(
                        onPressed: () => homeBloc.add(
                          HomeStartGameEvent(),
                        ),
                        child: const Text(
                          'Start Game',
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        child: const Text(
                          'Game history',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  AbsorbPointer(
                    absorbing: isLoading,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Connect to MetaMask Wallet
  Future<String> connectWallet(context) async {
    final completer = Completer<String>();
    try {
      js.context.callMethod('connectWallet', [
        (result) {
          completer.complete(result.toString());
          print('Metamask:: Connecting wallet: $result');
        },
      ]);
      // final dynamic result = await jsUtil.promiseToFuture(promise);
      // print('Metamask:: Connecting wallet: $result');
      // return result;
    } catch (e) {
      print('Metamask:: Error connecting wallet: $e');
      completer.complete(e.toString());
    }
    return completer.future;
  }

  void _listenHomeStates(
    BuildContext context,
    HomeState state,
  ) {
    if (state is GameSessionFoundState) {
      final gameSession = state.gameSession;
      if ((gameSession.playerIds
                      ?.where((item) => item != null && item.trim().isNotEmpty)
                      .length ??
                  0) >
              1 &&
          (gameSession.playerReady?.values.length ?? 0) > 1 &&
          gameSession.playerReady!.values.every((test) => test == true)) {
        Navigator.pushNamed(
          context,
          '/gamePlay',
          arguments: gameSession,
        );
      } else if (gameSession.gameStatus == GameStatus.started.name ||
          gameSession.gameStatus == GameStatus.waiting.name) {
        Navigator.pushReplacementNamed(
          context,
          '/lobby',
          arguments: gameSession,
        );
      }
    } else if (state is UserNotFoundState) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }
}
