import 'match_result.dart';

class UserProfile {
  final String uid;
  final int? backendUID;
  final String name;
  final String email;
  final String? photoUrl;
  final String? publicKey;
  final int wallet;
  final bool online;
  final bool isSecure;
  final List<MatchResult> matchHistory;

  UserProfile({
    required this.uid,
    required this.backendUID,
    required this.name,
    required this.email,
    this.photoUrl,
    this.publicKey,
    this.online = false,
    this.isSecure = false,
    this.wallet = 0,
    this.matchHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'backendUID': backendUID,
      'name': name,
      'email': email,
      'online': online,
      'isSecure': isSecure,
      'photoUrl': photoUrl,
      'publicKey': publicKey,
      'wallet': wallet,
      'matchHistory': matchHistory.map((e) => e.toMap()).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      backendUID: map['backendUID'],
      name: map['name'],
      email: map['email'],
      online: map['online'] ?? false,
      isSecure: map['isSecure'] ?? false,
      photoUrl: map['photoUrl'],
      publicKey: map['publicKey'],
      wallet: map['wallet'] ?? 0,
      matchHistory: (map['matchHistory'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromMap(e))
              .toList() ??
          [],
    );
  }
}
