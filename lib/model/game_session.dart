import 'package:cloud_firestore/cloud_firestore.dart';

class GameSession {
  String sessionId;
  List<String?>? playerIds;
  Map<String, int>? scores;
  bool? isActive;
  String? gameStatus;
  DateTime? startTime;

  GameSession({
    required this.sessionId,
    this.playerIds,
    this.scores,
    this.gameStatus,
    this.isActive,
    this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'playerIds': playerIds,
      'scores': scores,
      'isActive': isActive,
      'gameStatus': gameStatus,
      'startTime': startTime?.toUtc(),
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      sessionId: map['sessionId'],
      playerIds: List<String>.from(map['playerIds']),
      scores: Map<String, int>.from(map['scores']),
      isActive: map['isActive'],
      gameStatus: map['gameStatus'],
      startTime: (map['startTime'] as Timestamp).toDate(),
    );
  }
}
