import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';

/// Catálogo de produtos com as faixas de dose e as fontes usadas nos alertas.
abstract interface class CatalogRepository {
  /// Produto do catálogo ligado ao item da rotina, ou `null` quando o item foi
  /// cadastrado à mão e não corresponde a nenhum produto conhecido.
  Future<Product?> productFor(RoutineItem item);

  /// Produto pelo id do catálogo (as doses registradas guardam esse id), ou `null`.
  Future<Product?> productById(String id);

  /// Lista paginada do catálogo para a tela "Adicionar à rotina".
  /// [query] busca pelo nome, ignorando acentos ("omega" acha "Ômega 3").
  /// [page] começa em 1.
  Future<PageResult<Product>> search({ProductKind? kind, String? query, int page = 1, int pageSize = 4});
}
