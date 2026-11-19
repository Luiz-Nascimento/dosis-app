import '../../core/api/api_exception.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/catalog.dart';
import '../models/enums.dart';
import '../models/tracking.dart';
import '../services/catalog_service.dart';

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._service);

  final CatalogService _service;

  /// O catálogo muda pouco: guarda cada produto já buscado para não repetir a chamada.
  final Map<String, Product?> _cache = {};

  @override
  Future<Product?> productFor(RoutineItem item) async {
    final key = item.productId ?? 'name:${item.name.toLowerCase()}';
    if (_cache.containsKey(key)) return _cache[key];

    Product? product;
    if (item.productId != null) {
      product = await _service.getProduct(item.productId!);
    } else {
      // Item cadastrado à mão: tenta achar pelo nome (a busca ignora acentos).
      final page = await _service.listProducts(search: item.name, pageSize: 1);
      product = page.results.firstOrNull;
    }
    return _cache[key] = product;
  }

  @override
  Future<PageResult<Product>> search({ProductKind? kind, String? query, int page = 1, int pageSize = 4}) async {
    final trimmed = query?.trim();
    final result = await _service.listProducts(
      kind: kind,
      search: trimmed == null || trimmed.isEmpty ? null : trimmed,
      page: page,
      pageSize: pageSize,
    );
    // Aproveita a busca para já guardar os produtos: o alerta de dose não precisa buscá-los de novo.
    for (final product in result.results) {
      _cache[product.id] = product;
    }
    return result;
  }

  @override
  Future<Product?> productById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    try {
      return _cache[id] = await _service.getProduct(id);
    } on ApiException catch (error) {
      // Produto removido do catálogo: segue sem a faixa de referência.
      if (error.statusCode == 404) return _cache[id] = null;
      rethrow;
    }
  }
}
