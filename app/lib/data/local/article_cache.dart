import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/catalog.dart';
import '../models/json.dart';

/// Lista e artigos guardados no aparelho para leitura sem internet.
class ArticleCacheData {
  const ArticleCacheData({required this.summaries, required this.articles});

  final List<ArticleSummary> summaries;
  final Map<String, Article> articles;
}

/// Cache dos artigos no armazenamento do aparelho.
///
/// O conteúdo é pequeno e não é sensível; usamos o mesmo armazenamento das
/// preferências para não acrescentar outra dependência ao app. Qualquer falha
/// de leitura/escrita é ignorada: o app cai no conteúdo local.
class ArticleCache {
  ArticleCache([this._storage = const FlutterSecureStorage()]);

  static const _key = 'dosis.articles.v1';

  final FlutterSecureStorage _storage;

  Future<ArticleCacheData?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Json;
      final summaries = (json['summaries'] as List? ?? const [])
          .map((e) => ArticleSummary.fromJson(e as Json))
          .toList();
      final articles = <String, Article>{
        for (final item in json['articles'] as List? ?? const [])
          (item as Json)['id'] as String: Article.fromJson(item),
      };
      return ArticleCacheData(summaries: summaries, articles: articles);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(ArticleCacheData data) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'summaries': data.summaries.map((s) => s.toJson()).toList(),
          'articles': data.articles.values.map((a) => a.toJson()).toList(),
        }),
      );
    } catch (_) {
      // Sem armazenamento: o conteúdo local continua valendo.
    }
  }
}
