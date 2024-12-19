class FaucetResponse {
  FaucetResponse({
      this.message, 
      this.ethTxHash, 
      this.erc20TxHash,});

  FaucetResponse.fromJson(dynamic json) {
    message = json['message'];
    ethTxHash = json['ethTxHash'];
    erc20TxHash = json['erc20TxHash'];
  }
  String? message;
  String? ethTxHash;
  String? erc20TxHash;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['ethTxHash'] = ethTxHash;
    map['erc20TxHash'] = erc20TxHash;
    return map;
  }

}