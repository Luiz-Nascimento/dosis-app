import 'catalog.dart';

/// Quanto uma recomendação pede atenção.
enum RecommendationLevel {
  /// Dica educativa, sem nada fora do esperado.
  info,

  /// Algo saiu da faixa usual ou merece revisão.
  attention,

  /// Uso que só é seguro com acompanhamento médico.
  medical,
}

/// Recomendação gerada a partir das diretrizes do catálogo e dos registros do
/// usuário (doses, sintomas e hidratação). Serve tanto para a lista no app
/// quanto para o texto das notificações educacionais.
class Recommendation {
  const Recommendation({
    required this.id,
    required this.title,
    required this.body,
    this.level = RecommendationLevel.info,
    this.sources = const [],
  });

  /// Estável por assunto: salvar de novo com o mesmo id substitui a notificação.
  final String id;
  final String title;
  final String body;
  final RecommendationLevel level;
  final List<Source> sources;

  /// Nome das fontes sem repetição (ex.: "ISSN / ANVISA").
  String get sourcesFormatted {
    if (sources.isEmpty) return 'Diretrizes do Dosis';
    return sources.map((s) => s.name).toSet().join(' / ');
  }
}
