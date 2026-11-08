import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/auth_widgets.dart';

/// "Confirme seu e-mail": depois do cadastro.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _busy = false;
  String? _error;

  Future<void> _confirmed() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final verified = await ref.read(authRepositoryProvider).isEmailVerified();
      if (!mounted) return;
      if (verified) {
        ref.read(sessionProvider.notifier).signedIn();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _busy = false;
          _error = 'Ainda não identificamos a confirmação. Toque no link do e-mail e tente de novo.';
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

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail reenviado.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmailNotice(
      title: 'Confirme seu e-mail',
      body: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Enviamos um link para\n'),
            TextSpan(
              text: widget.email,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const TextSpan(text: '\nToque nele para ativar sua conta e volte aqui.'),
          ],
        ),
      ),
      primaryLabel: 'Já confirmei meu e-mail',
      onPrimary: _confirmed,
      busy: _busy,
      error: _error,
      onResend: _resend,
      onOther: () => Navigator.of(context).pop(),
    );
  }
}