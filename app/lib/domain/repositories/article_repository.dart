import '../../data/models/catalog.dart';

/// Conteúdos educativos. O app guarda uma cópia local para funcionar sem
/// internet: a lista e o texto completo ficam disponíveis offline.
abstract interface class ArticleRepository {
  Future<List<ArticleSummary>> list({String? tag, String? search});

  Future<Article> get(String id);
}
