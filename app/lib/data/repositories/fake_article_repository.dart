import '../../domain/repositories/article_repository.dart';
import '../models/catalog.dart';
import 'local_articles.dart';

/// Conteúdo embutido no app, para o modo fake e para o primeiro uso offline.
class FakeArticleRepository implements ArticleRepository {
  @override
  Future<List<ArticleSummary>> list({String? tag, String? search}) async =>
      filterArticles(LocalArticles.articles, tag: tag, search: search);

  @override
  Future<Article> get(String id) async {
    for (final article in LocalArticles.articles) {
      if (article.id == id) return article;
    }
    throw StateError('Artigo não encontrado: $id');
  }
}
