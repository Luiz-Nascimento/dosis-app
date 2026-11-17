import 'package:dosis/data/models/catalog.dart';
import 'package:dosis/data/repositories/fake_article_repository.dart';
import 'package:dosis/data/repositories/local_articles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = FakeArticleRepository();

  test('a lista local traz artigos com fontes oficiais', () async {
    final articles = await repository.list();

    expect(articles, isNotEmpty);
    final sources = LocalArticles.articles.expand((a) => a.sources).map((s) => s.name).toSet();
    expect(sources, containsAll(['ANVISA', 'SBEM', 'ISSN', 'CFM', 'ACSM']));
  });

  test('busca filtra por título e por resumo', () async {
    final byTitle = await repository.list(search: 'creatina');
    final bySummary = await repository.list(search: 'rins');

    expect(byTitle.map((a) => a.id), contains('creatina-e-rins'));
    expect(bySummary.map((a) => a.id), contains('creatina-e-rins'));
  });

  test('o texto completo e as fontes sobrevivem ao JSON do cache', () async {
    final article = await repository.get('creatina-e-rins');

    final copy = Article.fromJson(article.toJson());

    expect(copy.title, article.title);
    expect(copy.body, article.body);
    expect(copy.sources.map((s) => s.toJson()), article.sources.map((s) => s.toJson()));
  });

  test('tag filtra artigos relacionados', () async {
    final anabolicos = await repository.list(tag: 'anabolizantes');

    expect(anabolicos.map((a) => a.id), contains('anabolizantes-o-que-saber'));
    expect(anabolicos.every((a) => a.tags.contains('anabolizantes')), isTrue);
  });
}
