import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import 'article_page.dart';

/// "Conteúdos educativos": lista os artigos do backend (ou a cópia local,
/// quando não há internet) e abre a leitura com fonte ajustável.
class ArticlesPage extends ConsumerStatefulWidget {
  const ArticlesPage({super.key});

  @override
  ConsumerState<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends ConsumerState<ArticlesPage> {
  String _search = '';

  Future<void> _refresh() async {
    ref.invalidate(articlesProvider);
    try {
      await ref.read(articlesProvider.future);
    } catch (_) {
      // O repositório já cai no conteúdo local; a tela mostra o estado atual.
    }
  }

  void _open(ArticleSummary article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticlePage(articleId: article.id, fallbackTitle: article.title),
      ),
    );
  }

  List<ArticleSummary> _filtered(List<ArticleSummary> articles) {
    final term = _search.trim().toLowerCase();
    if (term.isEmpty) return articles;
    return articles
        .where((a) => a.title.toLowerCase().contains(term) || a.summary.toLowerCase().contains(term))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(articlesProvider);

    return Scaffold(
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
                ),
                const Expanded(
                  child: Text(
                    'Conteúdos educativos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Aprenda mais sobre sua rotina',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SearchBox(
                hint: 'Buscar artigo (ex.: creatina)',
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            Expanded(
              child: articles.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorState(onRetry: _refresh),
                data: (items) {
                  final filtered = _filtered(items);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Nenhum artigo encontrado. Tente outra busca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ArticleCard(
                        article: filtered[index],
                        onTap: () => _open(filtered[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final ArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.menu_book_outlined, color: AppColors.yellow, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  article.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.3),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.yellow, size: 26),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.summary,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: AppColors.yellow),
                    const SizedBox(width: 5),
                    Text(
                      '${article.readingMinutes} min',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    if (article.tags.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          article.tags.map((t) => '#$t').join('  '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.yellow),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.yellow, size: 44),
            const SizedBox(height: 14),
            const Text(
              'Sem conexão com o servidor.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Os artigos já baixados continuam disponíveis. Tente atualizar quando tiver internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
