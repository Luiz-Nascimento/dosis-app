import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../theme/app_theme.dart';

/// Mensagem em português para mostrar ao usuário.
String errorMessage(Object error) {
  if (error is ApiException) {
    if (error.isValidationError && error.fieldErrors.isNotEmpty) {
      return error.fieldErrors.values.first.first;
    }
    return error.message;
  }
  return 'Algo deu errado. Tente novamente.';
}

/// Logo + título + conteúdo rolável + ações fixas embaixo (padrão das telas de conta).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.progress,
    this.bottom = const [],
  });

  final String title;
  final String? subtitle;

  /// De 1 a 3: barrinhas amarelas do cadastro.
  final int? progress;
  final List<Widget> children;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Center(child: Text('Dosis', style: AppTheme.logo.copyWith(fontSize: 54))),
              const SizedBox(height: 4),
              Center(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (var i = 1; i <= 3; i++)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          color: i <= progress! ? AppColors.yellow : const Color(0xFFD9D9D9),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
              ...bottom,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo com rótulo acima, como no protótipo. Com [obscure] ganha o olhinho.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          decoration: InputDecoration(
            fillColor: const Color(0xFF1D1D1F),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(AppColors.yellow),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Botão amarelo com indicador de carregamento.
class AuthButton extends StatelessWidget {
  const AuthButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
            )
          : Text(label),
    );
  }
}

/// "Não tem conta? **Criar conta**".
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.link, required this.onTap, this.prefix});

  final String? prefix;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefix != null) Text(prefix!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              link,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellow),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mensagem de erro em laranja.
class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(message!, style: const TextStyle(color: AppColors.orange, fontSize: 13)),
    );
  }
}

/// Tela "Confirme seu e-mail" / "Verifique seu e-mail": ícone, texto e ações embaixo.
class EmailNotice extends StatelessWidget {
  const EmailNotice({
    super.key,
    required this.title,
    required this.body,
    required this.onResend,
    required this.onOther,
    this.primaryLabel,
    this.onPrimary,
    this.busy = false,
    this.error,
  });

  final String title;
  final Widget body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onResend;
  final VoidCallback onOther;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellow.withValues(alpha: 0.22),
                  ),
                  child: const Icon(Icons.mail_outline, color: AppColors.yellow, size: 52),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                child: body,
              ),
              const SizedBox(height: 28),
              const Text(
                'Não chegou? Confira a caixa de spam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const Spacer(),
              if (error != null) AuthError(error),
              const SizedBox(height: 14),
              if (primaryLabel != null) ...[
                AuthButton(label: primaryLabel!, onPressed: onPrimary, busy: busy),
                const SizedBox(height: 12),
              ],
              OutlinedButton(onPressed: busy ? null : onResend, child: const Text('Reenviar e-mail')),
              TextButton(
                onPressed: onOther,
                child: const Text('Usar outro e-mail', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}