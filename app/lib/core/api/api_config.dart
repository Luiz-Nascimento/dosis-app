/// Endereço da API do Dosis.
///
/// Por padrão o app usa a API publicada. Para testar com o Django rodando no
/// computador (no emulador Android, `10.0.2.2` é o computador):
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dosis.duckdns.org/api/v1',
  );

  static const Duration timeout = Duration(seconds: 20);
}
