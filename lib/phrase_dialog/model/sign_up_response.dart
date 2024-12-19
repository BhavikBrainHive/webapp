class SignUpResponse {
  SignUpResponse({
    this.userId,
    this.jwtToken,
    this.referralCode,
    this.message,
  });

  SignUpResponse.fromJson(dynamic json) {
    userId = json['user_id'];
    jwtToken = json['jwt_token'];
    referralCode = json['referral_code'];
    message = json['message'];
  }

  num? userId;
  String? jwtToken;
  String? referralCode;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['jwt_token'] = jwtToken;
    map['referral_code'] = referralCode;
    map['message'] = message;
    return map;
  }
}
