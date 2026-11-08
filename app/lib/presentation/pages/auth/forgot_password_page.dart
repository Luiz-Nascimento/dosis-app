import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/auth_rules.dart';
import '../../providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';

/// "Recuperar senha" e, depois do envio, "Verifique seu e-mail".
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _busy = false;
          _sent = true;
        });
      }
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
    if (_sent) {
      return EmailNotice(
        title: 'Verifique seu e-mail',
        body: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Se existir uma conta com '),
              TextSpan(
                text: _email.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const TextSpan(text: ', o link para criar uma nova senha chega em instantes. Ele expira por segurança.'),
            ],
          ),
        ),
        onResend: _send,
        onOther: () => setState(() => _sent = false),
      );
    }
    return AuthScaffold(
      title: 'Recuperar senha',
      subtitle: 'Informe o e-mail da sua conta e enviaremos um link para criar uma nova senha.',
      children: [
        AuthField(
          label: 'E-mail',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        AuthError(_error),
      ],
      bottom: [
        AuthButton(label: 'Enviar link', onPressed: _send, busy: _busy),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Voltar ao ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'login',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellow),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}