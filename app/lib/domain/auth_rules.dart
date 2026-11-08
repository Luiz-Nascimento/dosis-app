/// Mesmas regras do backend (`validate_password_policy`) e da tela de cadastro.
class PasswordRules {
  const PasswordRules._();

  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasLetter(String v) => RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(v);
  static bool hasNumber(String v) => RegExp(r'\d').hasMatch(v);

  static bool isValid(String v) => hasMinLength(v) && hasLetter(v) && hasNumber(v);
}

bool isValidEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());