import '../../data/models/catalog.dart';
import '../../data/models/tracking.dart';

/// Catálogo de produtos com as faixas de dose e as fontes usadas nos alertas.
abstract interface class CatalogRepository {
  /// Produto do catálogo ligado ao item da rotina, ou `null` quando o item foi
  /// cadastrado à mão e não corresponde a nenhum produto conhecido.
  Future<Product?> productFor(RoutineItem item);

  /// Produto pelo id do catálogo (as doses registradas guardam esse id), ou `null`.
  Future<Product?> productById(String id);
}
