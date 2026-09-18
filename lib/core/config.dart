const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

class SessionConfig {
  static const Duration inactivityTimeout = Duration(minutes: 3);

  static const Duration inactivityWarningDuration = Duration(seconds: 30);

  static const Duration absoluteSessionTimeout = Duration(minutes: 30);
}
