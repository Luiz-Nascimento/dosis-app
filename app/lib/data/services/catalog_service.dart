import '../../core/api/api_client.dart';
import '../models/catalog.dart';
import '../models/enums.dart';
import '../models/json.dart';

/// Catálogo de suplementos e anabolizantes (`/products`), tela "Adicionar à rotina".
class CatalogService {
  CatalogService(this.api);

  final ApiClient api;

  /// Busca sem acento ("omega" acha "Ômega 3") e paginação.
  Future<PageResult<Product>> listProducts({ProductKind? kind, String? search, int page = 1, int pageSize = 20}) async {
    final json = await api.get('/products', query: {
      'kind': kind?.apiValue,
      'search': search,
      'page': page,
      'page_size': pageSize,
    }) as Json;
    return PageResult.fromJson(json, Product.fromJson);
  }

  /// Produto com as faixas de dose por protocolo e as fontes (para o alerta).
  Future<Product> getProduct(String id) async => Product.fromJson(await api.get('/products/$id') as Json);
}

/// Conteúdos educativos (`/articles`).
class ArticleService {
  ArticleService(this.api);

  final ApiClient api;

  Future<PageResult<ArticleSummary>> list({String? tag, String? search, int page = 1, int pageSize = 20}) async {
    final json = await api.get('/articles', query: {
      'tag': tag,
      'search': search,
      'page': page,
      'page_size': pageSize,
    }) as Json;
    return PageResult.fromJson(json, ArticleSummary.fromJson);
  }

  Future<Article> get(String id) async => Article.fromJson(await api.get('/articles/$id') as Json);
}
