class WordPhraseResponse {
  WordPhraseResponse({
      this.words,});

  WordPhraseResponse.fromJson(dynamic json) {
    words = json['words'] != null ? json['words'].cast<String>() : [];
  }
  List<String>? words;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['words'] = words;
    return map;
  }

}