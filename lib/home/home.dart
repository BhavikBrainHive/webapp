import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/history/bloc/game_history_event.dart';
import 'package:webapp/home/bloc/home_event.dart';
import 'package:webapp/home/bloc/home_state.dart';
import 'package:webapp/model/user.dart';

import '../history/bloc/game_history_bloc.dart';
import '../history/bloc/game_history_state.dart';
import '../history/model/game_history_model.dart';
import '../model/bottom_tab_item.dart';
import '../phrase_dialog/bloc/phrase_dialog_bloc.dart';
import '../phrase_dialog/phrase_dialog.dart';
import '../toast_widget.dart';
import 'bloc/home_bloc.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    FToast toastBuilder = FToast();
    toastBuilder.init(context);
    final controller = PageController();
    final homeBloc = BlocProvider.of<HomeBloc>(context, listen: false);
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (_, state) =>
          state is UserNotFoundState || state is HomeInsufficientFundState,
      listener: (_, state) {
        if (state is UserNotFoundState) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (Route<dynamic> route) => false,
          );
        } else if (state is HomeInsufficientFundState) {
          toastBuilder.showToast(
            gravity: ToastGravity.TOP,
            toastDuration: const Duration(
              seconds: 3,
            ),
            child: const ToastWidget(
              message: 'Insufficient wallet points!!',
              isSuccess: false,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: PopScope(
            canPop: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 100.h,
                    ),
                    child: PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: controller,
                      onPageChanged: (page) {
                        if (page == 1) {
                          context
                              .read<GameHistoryBloc>()
                              .add(GameHistoryInitialEvent());
                        }
                      },
                      children: const [
                        ProfileTabContent(),
                        HistoryTabContent(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  right: 20.w,
                  child: BottomAppBar(
                    onSelect: controller.jumpToPage,
                  ),
                ),
                Center(
                  child: BlocBuilder<HomeBloc, HomeState>(
                    buildWhen: (prev, current) =>
                        current is ProfileUpdatedState ||
                        current is ProfileLoadingState,
                    builder: (_, state) {
                      UserProfile? profile;
                      if (state is ProfileUpdatedState) {
                        profile = state.profile;
                      } else {
                        profile = homeBloc.userProfile;
                      }
                      final isLoading = profile == null ||
                          (state is ProfileLoadingState && state.isLoading);
                      if (isLoading) {
                        return AbsorbPointer(
                          absorbing: isLoading,
                          child: const CircularProgressIndicator(),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                Center(
                  child: BlocBuilder<GameHistoryBloc, GameHistoryState>(
                    buildWhen: (_, current) =>
                        current is GameHistoryLoadingState,
                    builder: (_, state) {
                      final isLoading = controller.page?.round() == 1 &&
                          state is GameHistoryLoadingState &&
                          state.isLoading;
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

/*/// Connect to MetaMask Wallet
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
  }*/
}

class HistoryTabContent extends StatelessWidget {
  const HistoryTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameHistoryBloc, GameHistoryState>(
      buildWhen: (_, current) => current is GameHistoryDataUpdated,
      builder: (_, state) {
        final List<GameHistoryModel> list =
            state is GameHistoryDataUpdated ? state.gameHistoryList : [];
        final currentUserId = state is GameHistoryDataUpdated
            ? state.currentPlayerId
            : FirebaseAuth.instance.currentUser?.uid;
        if (list.isEmpty) {
          return Center(
            child: Text(
              "No history found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.sp,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
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
                  color: const Color(0xff30343a),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(pos + 1).toString()} - ${gameSession.sessionId.toUpperCase().substring(0, 5)}...',
                      style: TextStyle(color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: players
                            .where((test) => test != null)
                            .map((element) {
                          final score = gameSession.scores?[element!.uid] ?? 0;
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
                              ? Colors.white
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
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Score: $playerScore',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final homeBloc = BlocProvider.of<HomeBloc>(context, listen: false);
    return BlocConsumer<HomeBloc, HomeState>(
      buildWhen: (_, state) =>
          state is ProfileUpdatedState || state is ProfileLoadingState,
      listenWhen: (_, state) => state is GameSessionFoundState,
      listener: _listenHomeStates,
      builder: (_, state) {
        UserProfile? profile;
        if (state is ProfileUpdatedState) {
          profile = state.profile;
        } else {
          profile = homeBloc.userProfile;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: 40.h,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
              ),
              child: Row(
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
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.w,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'WALLET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(
                                width: 10.w,
                              ),
                              SizedBox(
                                height: 20.w,
                                width: 20.w,
                                child: SvgPicture.asset(
                                  'assets/svg/coin.svg',
                                ),
                              ),
                              SizedBox(
                                width: 3.w,
                              ),
                              Text(
                                '${profile?.wallet ?? 0}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  if (profile?.isSecure == false)
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
                        onTap: () async {
                          final phrases = await _askForPhrases(context);
                          if (phrases != null && phrases.isNotEmpty) {
                            final wordPhrases = phrases.join(" ");
                            homeBloc.add(SecureWalletEvent(wordPhrases));
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.w,
                          ),
                          child: Image.asset(
                            'assets/images/ic_lock_unsecure.png',
                            color: Colors.white,
                            width: 25,
                            height: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
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
                        onTap: () async {
                          showDialog(
                            context: context,
                            useSafeArea: true,
                            builder: (dialogContext) {
                              return Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.sizeOf(context).width *
                                              0.06),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      0xff292c32,
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xff30343a),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(
                                              10.r,
                                            ),
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 7.h,
                                        ),
                                        child: Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                            fontSize: 25.sp,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 15.h,
                                          horizontal: 10.w,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Are you sure you want to logout?',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xffFFFFFF)
                                                    .withOpacity(0.5),
                                                fontSize: 20.sp,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 50.h,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10.r,
                                                        ),
                                                        onTap: () async {
                                                          (await SharedPreferences
                                                                  .getInstance())
                                                              .clear();
                                                          await FirebaseAuth
                                                              .instance
                                                              .signOut();
                                                          Navigator
                                                              .pushNamedAndRemoveUntil(
                                                            context,
                                                            '/login',
                                                            (Route<dynamic>
                                                                    route) =>
                                                                false,
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 12.w,
                                                          ),
                                                          child: Text(
                                                            'Logout',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 18.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 10.w,
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueAccent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10.r,
                                                        ),
                                                        onTap: () async {
                                                          Navigator.pop(
                                                              dialogContext);
                                                        },
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 12.w,
                                                          ),
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 18.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.w,
                          ),
                          child: Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundImage: NetworkImage(
                profile?.photoUrl ?? '',
              ),
              radius: 50,
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              profile?.name ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              '5702827694',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xffFFFFFF).withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
            const SizedBox(
              height: 35,
            ),
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
                      onTap: () => homeBloc.add(
                        CreateLSAEvent(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.w,
                        ),
                        child: Text(
                          'Create LSA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
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
                      onTap: () => homeBloc.add(
                        HomeStartGameEvent(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.w,
                        ),
                        child: Text(
                          'Play',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 100.h,
            ),
            /*ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        child: const Text(
                          'Game history',
                        ),
                      ),*/
          ],
        );
      },
    );
  }

  Future<List<String>?> _askForPhrases(context) {
    return showModalBottomSheet<List<String>?>(
      context: context,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return BlocProvider<PhraseDialogBloc>(
          create: (_) => PhraseDialogBloc(),
          child: const PhraseDialog(),
        );
      },
    );
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

class BottomAppBar extends StatefulWidget {
  const BottomAppBar({
    super.key,
    required this.onSelect,
  });

  final Function(int id) onSelect;

  @override
  State<BottomAppBar> createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  int selectedId = 0;

  final data = [
    BottomTabItem(
      id: 0,
      icon: 'assets/images/home.png',
      title: 'Home',
    ),
    BottomTabItem(
      id: 1,
      icon: 'assets/images/history.png',
      title: 'History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xff30343a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12.r,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2.5.w,
          vertical: 5.w,
        ),
        child: Row(
          children: data.map((e) {
            return BottomBarItem(
              bottomTabItem: e,
              isSelected: e.id == selectedId,
              onSelect: (id) {
                setState(() {
                  selectedId = id;
                });
                widget.onSelect(id);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BottomBarItem extends StatelessWidget {
  final bool isSelected;
  final BottomTabItem bottomTabItem;
  final Function(int id) onSelect;

  const BottomBarItem({
    super.key,
    required this.bottomTabItem,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w / 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(
                  0xff292c32,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            8.r,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              8.r,
            ),
            onTap: isSelected
                ? null
                : () => onSelect(
                      bottomTabItem.id,
                    ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 9.w,
                horizontal: 15.w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: bottomTabItem.icon.endsWith('.svg')
                        ? SvgPicture.asset(
                            bottomTabItem.icon,
                            color: Colors.red,
                          )
                        : Image.asset(
                            bottomTabItem.icon,
                            color: isSelected ? Colors.blueAccent : Colors.grey,
                          ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  Text(
                    bottomTabItem.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      color: isSelected
                          ? Colors.blueAccent
                          : Color(0xffFFFFFF).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
