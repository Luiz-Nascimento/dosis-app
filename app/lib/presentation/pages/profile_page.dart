import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(accountProvider).value?.name ?? '';

    void soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve.')));

    return Scaffold(
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.yellow)),
                child: const Icon(Icons.person_outline, size: 64, color: AppColors.yellow),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            const SizedBox(height: 32),
            _Item(icon: Icons.edit_outlined, title: 'Meus dados', subtitle: 'Altura, peso, idade...', onTap: soon),
            const SizedBox(height: 18),
            _Item(icon: Icons.edit_outlined, title: 'Meu objetivo', subtitle: 'O que eu quero?', onTap: soon),
            const SizedBox(height: 18),
            _Item(
              icon: Icons.edit_outlined,
              title: 'Notificações',
              subtitle: 'Ative ou desative notificações',
              onTap: soon,
            ),
            const SizedBox(height: 18),
            DosisCard(
              onTap: () async {
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.orangeSoft,
                    child: Icon(Icons.logout, color: AppColors.orange),
                  ),
                  SizedBox(width: 14),
                  Text('Sair', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.yellow.withValues(alpha: 0.2),
            child: Icon(icon, color: AppColors.yellow, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.yellow, size: 28),
        ],
      ),
    );
  }
}