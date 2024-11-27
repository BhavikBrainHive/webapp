import 'package:flutter/material.dart';

class Gameplay extends StatefulWidget {
  @override
  _GameplayState createState() => _GameplayState();
}

class _GameplayState extends State<Gameplay> {
  int score = 0;
  int timer = 30;

  @override
  void initState() {
    super.initState();
    startTimer();
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

  void incrementScore() {
    setState(() {
      score++;
    });
    // Here, you can also update the Firestore score in real-time.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Time Left: $timer',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Text(
              'Your Score: $score',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: incrementScore,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('Hit Me', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}
