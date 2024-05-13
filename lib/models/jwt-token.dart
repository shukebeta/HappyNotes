class JwtToken {
  final String token;
  JwtToken({required this.token});
  factory JwtToken.fromJson(Map<String, dynamic> json) {
    return JwtToken(token: json['token']);
  }
}