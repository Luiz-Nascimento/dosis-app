import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recommendation.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import '../widgets/recommendation_card.dart';

/// Lista completa das recomendações do motor, com as fontes de cada uma.
class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(recommendationsProvider);
    try {
      await ref.read(recommendationsProvider.future);
    } catch (_) {
      // A tela mostra o estado de erro com a opção de tentar de novo.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(recommendationsProvider);

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
                    'Recomendações',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Dicas geradas a partir das diretrizes do catálogo e dos seus registros.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            Expanded(
              child: recommendations.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorState(onRetry: () => _refresh(ref)),
                data: (items) => RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: items.isEmpty ? const _EmptyState() : _List(items: items),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<Recommendation> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        for (final item in items) ...[
          RecommendationCard(recommendation: item),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        DosisCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.yellow, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'As recomendações não bloqueiam o uso e não substituem avaliação médica. '
                  'Elas comparam o que você registrou com as faixas usuais do catálogo e citam a fonte.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: const [
        SizedBox(height: 40),
        Icon(Icons.check_circle_outline, color: AppColors.yellow, size: 48),
        SizedBox(height: 16),
        Text(
          'Nada fora do esperado por aqui.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'Continue registrando doses, sintomas e água. As recomendações aparecem quando algo '
          'sai da faixa usual ou quando há uma dica útil para você.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
        ),
      ],
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
            const Icon(Icons.error_outline, color: AppColors.yellow, size: 44),
            const SizedBox(height: 14),
            const Text(
              'Não foi possível gerar as recomendações.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente de novo em instantes.',
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
