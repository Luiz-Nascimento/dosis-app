import 'dart:async';

import '../../domain/repositories/article_repository.dart';
import '../local/article_cache.dart';
import '../models/catalog.dart';
import '../services/catalog_service.dart';
import 'local_articles.dart';

/// Artigos vindos da API com cópia local: a lista e os textos baixados ficam
/// disponíveis offline, e qualquer falha de rede cai no cache ou no conteúdo
/// embutido no app.
class ApiArticleRepository implements ArticleRepository {
  ApiArticleRepository(this._service, [ArticleCache? cache]) : _cache = cache ?? ArticleCache();

  final ArticleService _service;
  final ArticleCache _cache;

  ArticleCacheData? _stored;
  bool _loaded = false;
  List<ArticleSummary>? _summaries;
  final Map<String, Article> _articles = {};

  Future<ArticleCacheData> _readCache() async {
    if (_loaded) return _stored ?? const ArticleCacheData(summaries: [], articles: {});
    _loaded = true;
    _stored = await _cache.read();
    return _stored ?? const ArticleCacheData(summaries: [], articles: {});
  }

  Future<void> _persist() async {
    final summaries = _summaries ?? _stored?.summaries ?? const <ArticleSummary>[];
    final articles = <String, Article>{...?_stored?.articles, ..._articles};
    _stored = ArticleCacheData(summaries: summaries, articles: articles);
    await _cache.write(_stored!);
  }

  @override
  Future<List<ArticleSummary>> list({String? tag, String? search}) async {
    final cached = await _readCache();
    try {
      final page = await _service.list(pageSize: 50);
      _summaries = page.results;
      await _persist();
      // Baixa os textos em segundo plano para a próxima leitura ser offline.
      unawaited(_downloadMissingBodies(page.results));
      return filterArticles(page.results, tag: tag, search: search);
    } catch (_) {
      _articles.addAll(cached.articles);
      final fallback = _summaries ??
          (cached.summaries.isNotEmpty ? cached.summaries : LocalArticles.articles);
      return filterArticles(fallback, tag: tag, search: search);
    }
  }

  @override
  Future<Article> get(String id) async {
    final cached = await _readCache();
    Article? local;
    for (final article in LocalArticles.articles) {
      if (article.id == id) {
        local = article;
        break;
      }
    }
    final fallback = _articles[id] ?? cached.articles[id] ?? local;
    if (fallback != null) _articles[id] = fallback;

    try {
      final article = await _service.get(id);
      _articles[id] = article;
      await _persist();
      return article;
    } catch (_) {
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  Future<void> _downloadMissingBodies(List<ArticleSummary> summaries) async {
    var changed = false;
    for (final summary in summaries) {
      if (_articles.containsKey(summary.id)) continue;
      try {
        _articles[summary.id] = await _service.get(summary.id);
        changed = true;
      } catch (_) {
        // Sem rede no meio do download: os artigos já baixados continuam valendo.
      }
    }
    if (changed) await _persist();
  }
}
