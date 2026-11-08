import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/auth_rules.dart';
import '../../providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'login_page.dart';
import 'verify_email_page.dart';

/// Criar conta em 3 passos: nome, e-mail e senha (com aceite dos termos).
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _terms = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) return 'Diga como você quer ser chamado.';
        if (_name.text.trim().length > 60) return 'Use no máximo 60 caracteres.';
      case 1:
        if (!isValidEmail(_email.text)) return 'Informe um e-mail válido.';
      default:
        if (!PasswordRules.isValid(_password.text)) return 'A senha não cumpre as regras abaixo.';
        if (_password.text != _confirm.text) return 'As senhas não são iguais.';
        if (!_terms) return 'É preciso aceitar os termos de uso.';
    }
    return null;
  }

  Future<void> _next() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_step < 2) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            acceptTerms: _terms,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => VerifyEmailPage(email: _email.text.trim())),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(error);
        });
      }
    }
  }

  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Termos de uso'),
        content: const Text(
          'Texto provisório. O Dosis é uma ferramenta de acompanhamento e de informação e não substitui '
          'orientação médica. Seus registros ficam associados à sua conta.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return AuthField(
          label: 'Como você quer ser chamado?',
          controller: _name,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthField(
              label: 'Qual é o seu e-mail?',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vamos enviar um link para você confirmar a conta.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthField(
              label: 'Senha',
              controller: _password,
              obscure: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _Rule('8 ou mais caracteres', PasswordRules.hasMinLength(_password.text)),
            _Rule('Pelo menos uma letra', PasswordRules.hasLetter(_password.text)),
            _Rule('Pelo menos um número', PasswordRules.hasNumber(_password.text)),
            const SizedBox(height: 22),
            AuthField(label: 'Confirmar senha', controller: _confirm, obscure: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _terms,
                  activeColor: AppColors.yellow,
                  checkColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                ),
                const Text('Aceito os ', style: TextStyle(fontSize: 13)),
                InkWell(
                  onTap: _showTerms,
                  child: const Text('termos de uso', style: TextStyle(fontSize: 13, color: AppColors.yellow)),
                ),
              ],
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _step--;
            _error = null;
          });
        }
      },
      child: AuthScaffold(
        title: 'Criar conta',
        progress: _step + 1,
        children: [_stepBody(), AuthError(_error)],
        bottom: [
          AuthButton(label: 'Continuar', onPressed: _next, busy: _busy),
          const SizedBox(height: 10),
          AuthLink(
            link: 'Já tenho uma conta',
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginPage())),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text, this.ok);

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? AppColors.yellow : AppColors.orange),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}