import 'package:dosis/data/models/catalog.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/domain/repositories/catalog_repository.dart';
import 'package:dosis/domain/usecases/get_dose_protocols.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catálogo que não responde (ex.: sem internet).
class _OfflineCatalog implements CatalogRepository {
  @override
  Future<Product?> productFor(RoutineItem item) => throw Exception('sem conexão');

  @override
  Future<Product?> productById(String id) => throw Exception('sem conexão');

  @override
  Future<PageResult<Product>> search({ProductKind? kind, String? query, int page = 1, int pageSize = 4}) =>
      throw Exception('sem conexão');
}

RoutineItem _item(String name, {String? productId, ProductKind kind = ProductKind.supplement}) => RoutineItem(
      id: 'r-$name',
      productId: productId,
      name: name,
      kind: kind,
      protocol: Protocol.continuous,
      doseUnit: DoseUnit.g,
      scheduleTimes: const [],
      active: true,
    );

DoseRange _range(Protocol protocol) => DoseRange(
      protocol: protocol,
      per: 'dose',
      min: 200,
      max: 400,
      unit: DoseUnit.mg,
      note: '',
      sources: const [],
    );

Product _product(String id, ProductKind kind, List<DoseRange> ranges) => Product(
      id: id,
      name: id,
      kind: kind,
      defaultUnit: DoseUnit.mg,
      doseRanges: ranges,
      caution: '',
      requiresMedicalSupervision: kind == ProductKind.anabolic,
      sources: const [],
    );

void main() {
  final protocols = GetDoseProtocols(FakeCatalogRepository());

  group('Produtos do catálogo', () {
    test('creatina oferece uso contínuo e saturação', () async {
      expect(await protocols(_item('Creatina', productId: 'creatina')), [Protocol.continuous, Protocol.loading]);
    });

    test('whey oferece só uso contínuo (saturação é da creatina)', () async {
      expect(await protocols(_item('Whey', productId: 'whey-protein')), [Protocol.continuous]);
    });

    test('anabolizante oferece só ciclo', () async {
      expect(await protocols(_item('Testosterona', productId: 'testosterona', kind: ProductKind.anabolic)),
          [Protocol.cycle]);
    });

    test('suplemento sem faixa de referência oferece só uso contínuo', () async {
      expect(await protocols(_item('BCAA', productId: 'bcaa')), [Protocol.continuous]);
    });
  });

  group('Fora do catálogo', () {
    test('suplemento cadastrado à mão: uso contínuo ou quando necessário, sem saturação nem ciclo', () async {
      expect(await protocols(_item('Pré-treino da academia')), [Protocol.continuous, Protocol.asNeeded]);
    });

    test('anabolizante cadastrado à mão: só ciclo', () async {
      expect(await protocols(_item('Outro anabolizante', kind: ProductKind.anabolic)), [Protocol.cycle]);
    });

    test('catálogo sem resposta usa as mesmas regras, sem impedir o registro', () async {
      final offline = GetDoseProtocols(_OfflineCatalog());

      expect(await offline(_item('Creatina', productId: 'creatina')), [Protocol.continuous, Protocol.asNeeded]);
      expect(await offline(_item('Testosterona', productId: 'testosterona', kind: ProductKind.anabolic)),
          [Protocol.cycle]);
    });
  });

  group('Product', () {
    test('protocols segue a ordem das faixas, sem repetir', () {
      final cafeina = _product('cafeina', ProductKind.supplement, [_range(Protocol.asNeeded)]);
      final repetido = _product('x', ProductKind.supplement, [_range(Protocol.continuous), _range(Protocol.continuous)]);

      expect(cafeina.protocols, [Protocol.asNeeded]);
      expect(repetido.protocols, [Protocol.continuous]);
    });

    test('rangeFor usa a faixa principal quando o produto não usa o protocolo', () {
      final cafeina = _product('cafeina', ProductKind.supplement, [_range(Protocol.asNeeded)]);

      expect(cafeina.rangeFor(Protocol.continuous)?.protocol, Protocol.asNeeded);
    });

    test('rangeFor continua nulo para produto sem faixa (anabolizantes)', () {
      final anabolizante = _product('testosterona', ProductKind.anabolic, const []);

      expect(anabolizante.rangeFor(Protocol.cycle), isNull);
    });
  });
}
