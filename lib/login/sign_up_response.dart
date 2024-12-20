class SignUpResponse {
  SignUpResponse({
    this.userId,
    this.jwtToken,
    this.userShare,
    this.deviceValid,
    this.secure,
    this.salt,
  });

  SignUpResponse.fromJson(dynamic json) {
    userId = json['user_id'];
    jwtToken = json['jwt_token'];
    userShare = json['user_share'];
    deviceValid = json['device_valid'];
    secure = json['secure'];
    salt = json['salt'];
  }

  num? userId;
  String? jwtToken;
  String? userShare;
  String? salt;
  bool? deviceValid;
  bool? secure;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['jwt_token'] = jwtToken;
    map['user_share'] = userShare;
    map['device_valid'] = deviceValid;
    map['secure'] = secure;
    map['salt'] = salt;
    return map;
  }
}
