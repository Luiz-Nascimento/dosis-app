import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import '../widgets/simple_markdown.dart';

/// Leitura de um artigo: texto em Markdown, fonte ajustável e fontes citadas.
/// O conteúdo vem do cache local quando o aparelho está sem internet.
class ArticlePage extends ConsumerStatefulWidget {
  const ArticlePage({super.key, required this.articleId, this.fallbackTitle});

  final String articleId;

  /// Título já conhecido pela lista, mostrado enquanto o texto carrega.
  final String? fallbackTitle;

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  static const _minFont = 16.0;
  static const _maxFont = 30.0;
  static const _step = 2.0;

  double _fontSize = 18;

  void _zoom(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(_minFont, _maxFont).toDouble());
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) _toast('Fonte copiada.');
  }

  @override
  Widget build(BuildContext context) {
    final article = ref.watch(articleProvider(widget.articleId));

    return Scaffold(
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: SafeArea(
        child: article.when(
          data: (data) => _content(data),
          loading: () => Column(
            children: [
              _topBar(),
              const SizedBox(height: 12),
              if (widget.fallbackTitle != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.fallbackTitle!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (error, stack) => Column(
            children: [
              _topBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined, color: AppColors.yellow, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Não foi possível abrir o artigo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Verifique a conexão. Os artigos já baixados continuam disponíveis offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(articleProvider(widget.articleId)),
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Article article) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _topBar(),
        const SizedBox(height: 8),
        Text(article.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Chip(icon: Icons.schedule, label: '${article.readingMinutes} min de leitura'),
            const _Chip(icon: Icons.offline_bolt_outlined, label: 'Disponível offline'),
            for (final tag in article.tags) _Chip(label: '#$tag'),
          ],
        ),
        const SizedBox(height: 18),
        _FontToolbar(
          fontSize: _fontSize,
          onSmaller: _fontSize > _minFont ? () => _zoom(-_step) : null,
          onLarger: _fontSize < _maxFont ? () => _zoom(_step) : null,
        ),
        const SizedBox(height: 20),
        SimpleMarkdown(article.body, fontSize: _fontSize),
        if (article.sources.isNotEmpty) ...[
          const SizedBox(height: 32),
          const SectionTitle('Fontes'),
          const SizedBox(height: 12),
          for (final source in article.sources) ...[
            _SourceCard(source: source, onCopy: () => _copy('${source.name}. ${source.citation} ${source.url}')),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 16),
        const Text(
          'Conteúdo educativo baseado nas diretrizes citadas. Não substitui avaliação médica ou '
          'nutricional individual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
        ),
        const Expanded(
          child: Text('Leitura', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _FontToolbar extends StatelessWidget {
  const _FontToolbar({required this.fontSize, this.onSmaller, this.onLarger});

  final double fontSize;
  final VoidCallback? onSmaller;
  final VoidCallback? onLarger;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.text_fields, color: AppColors.yellow, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tamanho do texto', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
          IconButton(
            onPressed: onSmaller,
            tooltip: 'Diminuir fonte',
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              fontSize.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: onLarger,
            tooltip: 'Aumentar fonte',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.yellow),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 14, color: AppColors.yellow),
            const SizedBox(width: 6),
          ],
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.onCopy});

  final Source source;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(source.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: 'Copiar fonte',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 18, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(source.citation, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 6),
          SelectableText(source.url, style: const TextStyle(fontSize: 12, color: AppColors.yellow)),
        ],
      ),
    );
  }
}
