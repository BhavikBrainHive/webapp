import 'match_result.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final int wallet;
  final bool online;
  final List<MatchResult> matchHistory;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.online = false,
    this.wallet = 0,
    this.matchHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'online': online,
      'photoUrl': photoUrl,
      'wallet': wallet,
      'matchHistory': matchHistory.map((e) => e.toMap()).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      online: map['online'] ?? false,
      photoUrl: map['photoUrl'],
      wallet: map['wallet'] ?? 0,
      matchHistory: (map['matchHistory'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromMap(e))
              .toList() ??
          [],
    );
  }
}
