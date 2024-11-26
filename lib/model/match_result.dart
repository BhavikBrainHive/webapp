import 'package:cloud_firestore/cloud_firestore.dart';

class MatchResult {
  final String opponentId;
  final String result; // 'Win' or 'Loss'
  final DateTime timestamp;

  MatchResult({
    required this.opponentId,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'opponentId': opponentId,
      'result': result,
      'timestamp': timestamp.toUtc(),
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      opponentId: map['opponentId'],
      result: map['result'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
