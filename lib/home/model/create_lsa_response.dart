class CreateLsaResponse {
  CreateLsaResponse({
      this.message, 
      this.transactionHash, 
      this.blockNumber, 
      this.status,});

  CreateLsaResponse.fromJson(dynamic json) {
    message = json['message'];
    transactionHash = json['transactionHash'];
    blockNumber = json['blockNumber'];
    status = json['status'];
  }
  String? message;
  String? transactionHash;
  num? blockNumber;
  num? status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['transactionHash'] = transactionHash;
    map['blockNumber'] = blockNumber;
    map['status'] = status;
    return map;
  }

}