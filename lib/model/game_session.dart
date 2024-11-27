import 'package:cloud_firestore/cloud_firestore.dart';

class GameSession {
  String sessionId;
  List<String?>? playerIds;
  Map<String, int>? scores;
  Map<String, bool>? playerReady;
  bool? isActive;
  String? gameStatus;
  String? lastReady;
  DateTime? startTime;
  DateTime? expireTime;
  DateTime? timestamp;

  GameSession({
    required this.sessionId,
    this.playerIds,
    this.scores,
    this.gameStatus,
    this.lastReady,
    this.playerReady,
    this.isActive,
    this.startTime,
    this.expireTime,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'playerIds': playerIds,
      'scores': scores,
      'lastReady': lastReady,
      'playerReady': playerReady,
      'isActive': isActive,
      'gameStatus': gameStatus,
      'startTime': startTime?.toUtc(),
      'expireTime': expireTime?.toUtc(),
      'timestamp': timestamp,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    Map<String, bool>? playerReady;
    if (map['playerReady'] != null &&
        map['playerReady'] is Map<String, dynamic>) {
      playerReady =
          (map['playerReady'] as Map<String, dynamic>).map((key, value) {
        if (value is bool) {
          return MapEntry(key, value);
        }
        return MapEntry(key, false);
      });
    }

    Map<String, int>? scores;
    if (map['scores'] != null && map['scores'] is Map<String, dynamic>) {
      scores = (map['scores'] as Map<String, dynamic>).map((key, value) {
        if (value is int) {
          return MapEntry(key, value);
        }
        return MapEntry(key, 0);
      });
    }

    return GameSession(
      sessionId: map['sessionId'],
      playerIds: List<String>.from(map['playerIds']),
      scores: scores,
      playerReady: playerReady,
      isActive: map['isActive'],
      lastReady: map['lastReady'],
      gameStatus: map['gameStatus'],
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      expireTime: (map['expireTime'] as Timestamp?)?.toDate(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
