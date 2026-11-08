import 'package:dosis/domain/auth_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('senha: 8+ caracteres, uma letra e um número', () {
    expect(PasswordRules.isValid('abc12345'), isTrue);
    expect(PasswordRules.isValid('abcdefgh'), isFalse);
    expect(PasswordRules.isValid('12345678'), isFalse);
    expect(PasswordRules.isValid('a1'), isFalse);
  });

  test('e-mail', () {
    expect(isValidEmail('rafael@gmail.com'), isTrue);
    expect(isValidEmail('rafael@gmail'), isFalse);
    expect(isValidEmail('rafael'), isFalse);
  });
}