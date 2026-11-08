import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/auth_rules.dart';
import '../../providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!isValidEmail(email) || _password.text.isEmpty) {
      setState(() => _error = 'Informe um e-mail válido e a sua senha.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).login(email: email, password: _password.text);
      ref.read(sessionProvider.notifier).signedIn();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Entrar',
      subtitle: 'Bom te ver de novo. Entre para continuar sua rotina.',
      children: [
        AuthField(
          label: 'E-mail',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 12),
        AuthField(
          label: 'Senha',
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          autofillHints: const [AutofillHints.password],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage())),
            child: const Text(
              'Esqueci minha senha',
              style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
        AuthError(_error),
      ],
      bottom: [
        AuthButton(label: 'Entrar', onPressed: _submit, busy: _busy),
        const SizedBox(height: 10),
        AuthLink(
          prefix: 'Não tem conta? ',
          link: 'Criar conta',
          onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const SignupPage())),
        ),
      ],
    );
  }
}