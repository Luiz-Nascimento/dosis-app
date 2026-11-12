import '../../domain/repositories/catalog_repository.dart';
import '../models/catalog.dart';
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
}
