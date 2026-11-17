import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'login_page.dart';
import 'signup_page.dart';

/// Introdução: fundo amarelo, "Cada dose na hora certa."
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF141414);
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Dosis', style: AppTheme.logo.copyWith(color: ink, fontSize: 40)),
              Expanded(
                child: Center(
                  child: Image.asset('assets/images/dosis.png', width: 240, fit: BoxFit.contain),
                ),
              ),
              const Text(
                'Cada dose na',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink, height: 1.1),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'hora certa',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.yellow, height: 1.15),
                    ),
                  ),
                  const Text('.', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink)),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Monte seu stack, registre o que tomou\ne receba lembretes no horário',
                style: TextStyle(fontSize: 13, color: ink),
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: AppColors.yellow),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SignupPage())),
                child: const Text('Começar'),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: ink),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginPage())),
                  child: const Text('Já tenho uma conta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'O Dosis é uma ferramenta de acompanhamento e não substitui orientação médica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: ink),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}