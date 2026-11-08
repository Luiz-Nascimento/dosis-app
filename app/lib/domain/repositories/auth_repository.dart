import '../../data/models/auth.dart';

/// Conta e sessão do usuário.
abstract interface class AuthRepository {
  Future<bool> isSignedIn();

  Future<void> login({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> resendEmailVerification();

  /// Renova a sessão e diz se o e-mail já foi confirmado.
  Future<bool> isEmailVerified();

  Future<Account> account();

  Future<void> signOut();
}