import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/tracking.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';
import 'articles_page.dart';
import 'register_dose_page.dart';
import 'risk_panel_page.dart';
import 'symptoms_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    void openRegister() => _push(context, const RegisterDosePage());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Center(child: Text('Olá!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        const Center(
          child: Text('Como você está hoje?', style: TextStyle(fontSize: 15, color: AppColors.muted)),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Sua rotina'),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: Row(
            children: [
              Expanded(
                child: _ActiveCard(
                  count: items.length,
                  onTap: () => ref.read(tabIndexProvider.notifier).select(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _RegisterCard(onTap: openRegister)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Stack de hoje'),
        const SizedBox(height: 12),
        DosisCard(
          onTap: openRegister,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.storage_outlined, color: AppColors.yellow, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (items.isEmpty)
                          const Text('Nenhum item no stack', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                        for (final item in items)
                          Text(
                            '${item.name} (${formatDose(item.doseAmount, item.doseUnit)})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.yellow, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: openRegister,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(130, 28),
                  foregroundColor: AppColors.yellow,
                  side: const BorderSide(color: AppColors.yellow),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                child: const Text('Ver Stack'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Como você está hoje?'),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.psychology_outlined,
          title: 'Registrar como me senti',
          subtitle: 'Humor, acne, sono e mais',
          onTap: () => _push(context, const SymptomsPage()),
        ),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.shield_outlined,
          title: 'Painel de risco',
          subtitle: 'Indicadores da semana e relatório de sintomas',
          onTap: () => _push(context, const RiskPanelPage()),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Conteúdos educativos'),
        const SizedBox(height: 12),
        NavCard(
          icon: Icons.menu_book_outlined,
          title: 'Artigos e informações 📚',
          subtitle: 'Aprenda mais sobre sua rotina',
          boxedIcon: true,
          onTap: () => _push(context, const ArticlesPage()),
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE600), Color(0xFFFFC800)],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('Suplementos\nativos', style: TextStyle(color: Colors.black, fontSize: 14)),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      onTap: onTap,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Registrar dose', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Icon(Icons.chevron_right, color: AppColors.yellow),
            ],
          ),
          SizedBox(height: 8),
          Text('Adicione seu suplemento e dosagem', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          Spacer(),
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.yellow, size: 16),
              SizedBox(width: 6),
              Text('Nova dose', style: TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}