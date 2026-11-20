import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/catalog_repository.dart';

/// Protocolos de uso que a tela "Registrar dose" oferece para um item do stack.
///
/// * Produto do catálogo: só os protocolos com faixa de referência
///   ([Product.protocols]), para que o alerta funcione em qualquer um deles.
/// * Item fora do catálogo, ou catálogo sem resposta: ciclo para anabolizantes;
///   uso contínuo ou quando necessário para suplementos. Saturação fica de fora,
///   porque só faz sentido para produtos como a creatina.
class GetDoseProtocols {
  const GetDoseProtocols(this._catalog);

  final CatalogRepository _catalog;

  Future<List<Protocol>> call(RoutineItem item) async {
    Product? product;
    try {
      product = await _catalog.productFor(item);
    } catch (_) {
      // Sem catálogo (ex.: sem internet), a dose ainda pode ser registrada.
      product = null;
    }
    if (product != null) return product.protocols;
    return item.kind == ProductKind.anabolic
        ? const [Protocol.cycle]
        : const [Protocol.continuous, Protocol.asNeeded];
  }
}
