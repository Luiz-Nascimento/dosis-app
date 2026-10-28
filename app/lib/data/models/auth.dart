import 'json.dart';

/// Resposta de login, cadastro, conta anônima, vínculo e refresh.
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.isAnonymous,
    required this.emailVerified,
    this.email,
    this.name,
  });

  factory AuthSession.fromJson(Json json) => AuthSession(
        uid: json['uid'] as String,
        idToken: json['id_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int,
        isAnonymous: json['is_anonymous'] as bool,
        emailVerified: json['email_verified'] as bool,
        email: json['email'] as String?,
        name: json['name'] as String?,
      );

  final String uid;
  final String idToken;
  final String refreshToken;
  final int expiresIn;
  final bool isAnonymous;
  final bool emailVerified;
  final String? email;
  final String? name;
}

/// Dados da conta autenticada (`GET /auth/me`).
class Account {
  const Account({
    required this.uid,
    required this.isAnonymous,
    required this.emailVerified,
    this.email,
    this.name,
  });

  factory Account.fromJson(Json json) => Account(
        uid: json['uid'] as String,
        isAnonymous: json['is_anonymous'] as bool,
        emailVerified: json['email_verified'] as bool,
        email: json['email'] as String?,
        name: json['name'] as String?,
      );

  final String uid;
  final bool isAnonymous;
  final bool emailVerified;
  final String? email;
  final String? name;
}

/// `GET /health`.
class HealthStatus {
  const HealthStatus({required this.status, required this.firebaseMode});

  factory HealthStatus.fromJson(Json json) =>
      HealthStatus(status: json['status'] as String, firebaseMode: json['firebase_mode'] as String);

  final String status;

  /// `mock` (sem credenciais) ou `firebase`.
  final String firebaseMode;
}
