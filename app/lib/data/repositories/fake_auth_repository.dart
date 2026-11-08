import '../../domain/repositories/auth_repository.dart';
import '../models/auth.dart';

/// Conta em memória: aceita qualquer login e considera o e-mail sempre confirmado.
class FakeAuthRepository implements AuthRepository {
  bool _signedIn = false;
  String? _name;
  String? _email;

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<void> login({required String email, required String password}) async {
    await _wait();
    _signedIn = true;
    _email = email;
    _name ??= email.split('@').first;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    await _wait();
    _signedIn = true;
    _name = name;
    _email = email;
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait();

  @override
  Future<void> resendEmailVerification() => _wait();

  @override
  Future<bool> isEmailVerified() async {
    await _wait();
    return true;
  }

  @override
  Future<Account> account() async =>
      Account(uid: 'fake', isAnonymous: false, emailVerified: true, email: _email, name: _name);

  @override
  Future<void> signOut() async => _signedIn = false;
}