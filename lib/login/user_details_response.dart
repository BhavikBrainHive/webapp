class UserDetailsResponse {
  UserDetailsResponse({
    this.userId,
    this.uniqueIdentifier,
    this.username,
    this.orgId,
    this.method,
    this.deviceInfo,
    this.createdAt,
    this.userPublicAddress,
    this.backendShare,
    this.jwtToken,
    this.referralCode,
    this.secure,
  });

  UserDetailsResponse.fromJson(dynamic json) {
    userId = json['user_id'];
    uniqueIdentifier = json['unique_identifier'];
    username = json['username'];
    orgId = json['org_id'];
    method = json['method'];
    deviceInfo = json['device_info'];
    createdAt = json['created_at'];
    userPublicAddress = json['user_public_address'];
    backendShare = json['backend_share'];
    jwtToken = json['jwt_token'];
    referralCode = json['referral_code'];
    secure = json['secure'];
  }

  num? userId;
  String? uniqueIdentifier;
  String? username;
  num? orgId;
  String? method;
  String? deviceInfo;
  String? createdAt;
  String? userPublicAddress;
  String? backendShare;
  String? jwtToken;
  String? referralCode;
  bool? secure;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['unique_identifier'] = uniqueIdentifier;
    map['username'] = username;
    map['org_id'] = orgId;
    map['method'] = method;
    map['device_info'] = deviceInfo;
    map['created_at'] = createdAt;
    map['user_public_address'] = userPublicAddress;
    map['backend_share'] = backendShare;
    map['jwt_token'] = jwtToken;
    map['referral_code'] = referralCode;
    map['secure'] = secure;
    return map;
  }
}
