import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Conteúdos educativos". A lista é fixa; os textos dos artigos são de outra tarefa.
class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  static const _articles = [
    'Whey Protein: quanto usar por dia?',
    'Sinais que vale parar e pedir ajuda',
    'Como ler o rótulo de um suplemento',
    'Hidratação e treino',
    'Sono e recuperação muscular',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conteúdos educativos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Text('Aprenda mais sobre sua rotina', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 28),
                  const SectionTitle('Todos os artigos'),
                  const SizedBox(height: 14),
                  for (final title in _articles) ...[
                    DosisCard(
                      radius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Artigo em breve.')),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, color: AppColors.yellow),
                          const SizedBox(width: 14),
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                          const Icon(Icons.chevron_right, color: AppColors.yellow, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}