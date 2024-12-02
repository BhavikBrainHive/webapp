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

  Map<String, dynamic> toMap({
    bool isCache = false,
  }) {
    final start =
        isCache ? startTime?.toUtc().toIso8601String() : startTime?.toUtc();
    final expire =
        isCache ? expireTime?.toUtc().toIso8601String() : expireTime?.toUtc();
    return {
      'sessionId': sessionId,
      'playerIds': playerIds,
      'scores': scores,
      'lastReady': lastReady,
      'playerReady': playerReady,
      'isActive': isActive,
      'gameStatus': gameStatus,
      'startTime': start,
      'expireTime': expire,
    };
  }

  factory GameSession.fromMap(
    Map<String, dynamic> map, {
    bool isCache = false,
  }) {
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

    final start = map['startTime'] != null
        ? (isCache
            ? DateTime.parse(map['startTime'])
            : (map['startTime'] as Timestamp?)?.toDate())
        : null;

    final expire = map['expireTime'] != null
        ? (isCache
            ? DateTime.parse(map['expireTime'])
            : (map['expireTime'] as Timestamp?)?.toDate())
        : null;

    final timestamp = map['timestamp'] != null
        ? (isCache
            ? DateTime.parse(map['timestamp'])
            : (map['timestamp'] as Timestamp?)?.toDate())
        : null;

    return GameSession(
      sessionId: map['sessionId'],
      playerIds: List<String>.from(map['playerIds']),
      scores: scores,
      playerReady: playerReady,
      isActive: map['isActive'],
      lastReady: map['lastReady'],
      gameStatus: map['gameStatus'],
      startTime: start,
      expireTime: expire,
      timestamp: timestamp,
    );
  }
}
