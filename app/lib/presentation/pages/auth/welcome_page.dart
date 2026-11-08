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
              const Expanded(child: Center(child: _PillsArt())),
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

class _PillsArt extends StatelessWidget {
  const _PillsArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.5),
            ),
          ),
          const Positioned(
            top: 28,
            left: 14,
            child: _Pill(left: Color(0xFFFF7A00), right: Color(0xFF111111), angle: -0.5, width: 104),
          ),
          const Positioned(
            top: 78,
            right: 6,
            child: _Pill(left: Color(0xFF111111), right: Colors.white, angle: 0.65, width: 100),
          ),
          const Positioned(
            bottom: 34,
            left: 40,
            child: _Pill(left: Colors.white, right: Color(0xFFFF7A00), angle: -0.12, width: 80),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.left, required this.right, required this.angle, required this.width});

  final Color left;
  final Color right;
  final double angle;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: width,
        height: width * 0.42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width),
          child: Row(
            children: [
              Expanded(child: ColoredBox(color: left)),
              Expanded(child: ColoredBox(color: right)),
            ],
          ),
        ),
      ),
    );
  }
}