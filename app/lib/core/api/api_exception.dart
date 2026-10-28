/// Erro devolvido pela API no formato `{"error": {"code", "message", "details"}}`.
///
/// Decida pelo [code] (estável) e mostre a [message] (já em português) ao usuário.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  /// Sem resposta do servidor (sem internet, timeout...).
  factory ApiException.network([Object? cause]) => ApiException(
        statusCode: 0,
        code: 'network_error',
        message: 'Sem conexão com o servidor. Seus registros continuam salvos no aparelho.',
        details: cause?.toString(),
      );

  final int statusCode;
  final String code;
  final String message;
  final Object? details;

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => code == 'validation_error';

  /// Erros por campo em respostas de validação (ex.: `{"password": ["..."]}`).
  Map<String, List<String>> get fieldErrors {
    final details = this.details;
    if (details is! Map) return const {};
    return details.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
      ),
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
