/// Endereço da API do Dosis.
///
/// No emulador Android, `10.0.2.2` é o computador onde o Django está rodando.
/// Para apontar para outro servidor:
/// `flutter run --dart-define=API_BASE_URL=https://meu-servidor/api/v1`
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration timeout = Duration(seconds: 20);
}
