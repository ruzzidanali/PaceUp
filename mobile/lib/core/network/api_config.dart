class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'PACEUP_API_URL',
    defaultValue: 'http://192.168.0.109:5095/api',
  );
}
