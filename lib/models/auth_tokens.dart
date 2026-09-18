class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ??
          json['access_token'] as String? ??
          '',
      refreshToken: json['refreshToken'] as String? ??
          json['refresh_token'] as String? ??
          '',
    );
  }
}
