import '../../domain/repositories/auth_repository.dart';
import '../models/auth.dart';
import '../services/auth_service.dart';

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._service);

  final AuthService _service;

  @override
  Future<bool> isSignedIn() => _service.isSignedIn;

  @override
  Future<void> login({required String email, required String password}) async {
    await _service.login(email: email, password: password);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    await _service.register(name: name, email: email, password: password, acceptTerms: acceptTerms);
  }

  @override
  Future<void> requestPasswordReset(String email) => _service.requestPasswordReset(email);

  @override
  Future<void> resendEmailVerification() => _service.resendEmailVerification();

  @override
  Future<bool> isEmailVerified() async => (await _service.refresh()).emailVerified;

  @override
  Future<Account> account() => _service.me();

  @override
  Future<void> signOut() => _service.signOut();
}