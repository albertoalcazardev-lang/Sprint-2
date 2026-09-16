class RespuestaLogin {
  final String token;

  const RespuestaLogin({required this.token});

  factory RespuestaLogin.fromJson(Map<String, dynamic> json) {
    return RespuestaLogin(token: json['token'] as String);
  }
}
