class SignUpResponse {
  SignUpResponse({
    this.userId,
    this.jwtToken,
    this.referralCode,
    this.userShare,
    this.backendShare,
  });

  SignUpResponse.fromJson(dynamic json) {
    userId = json['user_id'];
    jwtToken = json['jwt_token'];
    referralCode = json['referral_code'];
    userShare = json['user_share'];
    backendShare = json['backend_share'];
  }

  num? userId;
  String? jwtToken;
  String? referralCode;
  String? userShare;
  String? backendShare;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['jwt_token'] = jwtToken;
    map['referral_code'] = referralCode;
    map['user_share'] = userShare;
    map['backend_share'] = backendShare;
    return map;
  }
}
