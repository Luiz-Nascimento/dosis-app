import '../../domain/repositories/catalog_repository.dart';
import '../models/catalog.dart';
import '../models/enums.dart';
import '../models/tracking.dart';

/// Cópia em memória de parte de `backend/apps/catalog/content.py`, para o app
/// mostrar os mesmos alertas sem backend. Se mudar uma faixa lá, mude aqui também.
class FakeCatalogRepository implements CatalogRepository {
  static const _issnCreatina = Source(
    id: 'issn-creatina-2017',
    name: 'ISSN',
    citation: 'Kreider RB et al. International Society of Sports Nutrition position stand: safety and '
        'efficacy of creatine supplementation in exercise, sport, and medicine. J Int Soc Sports Nutr. 2017;14:18.',
    url: 'https://doi.org/10.1186/s12970-017-0173-z',
  );
  static const _issnProteina = Source(
    id: 'issn-proteina-2017',
    name: 'ISSN',
    citation: 'Jäger R et al. International Society of Sports Nutrition Position Stand: protein and exercise. '
        'J Int Soc Sports Nutr. 2017;14:20.',
    url: 'https://doi.org/10.1186/s12970-017-0177-8',
  );
  static const _efsaOmega3 = Source(
    id: 'efsa-omega3-2012',
    name: 'EFSA',
    citation: 'EFSA NDA Panel. Scientific Opinion related to the Tolerable Upper Intake Level of EPA, DHA and DPA. '
        'EFSA Journal 2012;10(7):2815.',
    url: 'https://doi.org/10.2903/j.efsa.2012.2815',
  );
  static const _anvisa = Source(
    id: 'anvisa-suplementos',
    name: 'ANVISA',
    citation: 'ANVISA. RDC nº 243/2018 e Instrução Normativa nº 28/2018: requisitos sanitários, constituintes, '
        'limites de uso e alegações de suplementos alimentares.',
    url: 'https://www.gov.br/anvisa/pt-br/assuntos/alimentos/suplementos-alimentares',
  );
  static const _cfm = Source(
    id: 'cfm-2333-2023',
    name: 'CFM',
    citation: 'Conselho Federal de Medicina. Resolução nº 2.333/2023: veda a prescrição de esteroides anabolizantes '
        'com finalidade estética, de ganho de massa muscular ou de desempenho esportivo.',
    url: 'https://portal.cfm.org.br',
  );
  static const _anvisaControlados = Source(
    id: 'anvisa-controlados',
    name: 'ANVISA',
    citation: 'Portaria SVS/MS nº 344/1998 (anabolizantes na lista C5 de controle especial) e Lei nº 9.965/2000 '
        '(venda de anabolizantes só com receita retida).',
    url: 'https://www.gov.br/anvisa/pt-br',
  );
  static const _sbem = Source(
    id: 'sbem',
    name: 'SBEM',
    citation: 'Sociedade Brasileira de Endocrinologia e Metabologia: orientações sobre esteroides anabolizantes.',
    url: 'https://www.endocrino.org.br',
  );

  static const _anabolicCaution =
      'Uso apenas com prescrição e acompanhamento médico. O CFM veda a prescrição para fins estéticos ou '
      'de desempenho. Pode afetar coração, fígado, fertilidade, pele e humor; exames periódicos ajudam a '
      'perceber alterações cedo.';

  static Product _anabolic(String id, String name, {String extraCaution = ''}) => Product(
        id: id,
        name: name,
        kind: ProductKind.anabolic,
        defaultUnit: DoseUnit.mg,
        doseRanges: const [],
        caution: _anabolicCaution + extraCaution,
        requiresMedicalSupervision: true,
        sources: const [_cfm, _anvisaControlados, _sbem],
      );

  static final List<Product> products = [
    const Product(
      id: 'creatina',
      name: 'Creatina monohidratada',
      kind: ProductKind.supplement,
      defaultUnit: DoseUnit.g,
      defaultDose: 3,
      doseRanges: [
        DoseRange(
          protocol: Protocol.continuous,
          per: 'day',
          min: 3,
          max: 5,
          unit: DoseUnit.g,
          note: 'Manutenção: 3 a 5 g por dia.',
          sources: [_issnCreatina],
        ),
        DoseRange(
          protocol: Protocol.loading,
          per: 'day',
          min: 15,
          max: 25,
          unit: DoseUnit.g,
          note: 'Saturação: cerca de 0,3 g/kg por dia, em 4 tomadas, por 5 a 7 dias.',
          sources: [_issnCreatina],
        ),
      ],
      caution: 'Em pessoas saudáveis, as doses usuais não mostraram prejuízo aos rins. Quem tem doença renal '
          'deve conversar com um médico antes. A creatina pode elevar a creatinina no exame de sangue: '
          'avise o médico que você usa.',
      requiresMedicalSupervision: false,
      sources: [_issnCreatina, _anvisa],
    ),
    const Product(
      id: 'whey-protein',
      name: 'Whey Protein',
      kind: ProductKind.supplement,
      defaultUnit: DoseUnit.g,
      defaultDose: 30,
      doseRanges: [
        DoseRange(
          protocol: Protocol.continuous,
          per: 'dose',
          min: 20,
          max: 40,
          unit: DoseUnit.g,
          note: 'Por tomada. O total de proteína do dia (comida + suplemento) costuma ficar entre 1,4 e 2,0 g/kg.',
          sources: [_issnProteina],
        ),
      ],
      caution: 'É alimento: conta no total de proteína do dia junto com as refeições.',
      requiresMedicalSupervision: false,
      sources: [_issnProteina, _anvisa],
    ),
    const Product(
      id: 'omega-3',
      name: 'Ômega 3',
      kind: ProductKind.supplement,
      defaultUnit: DoseUnit.mg,
      defaultDose: 1000,
      doseRanges: [
        DoseRange(
          protocol: Protocol.continuous,
          per: 'day',
          min: 250,
          max: 5000,
          unit: DoseUnit.mg,
          note: 'Quantidade de EPA + DHA (veja no rótulo), não do óleo total.',
          sources: [_efsaOmega3],
        ),
      ],
      caution: 'Quem usa anticoagulante deve conversar com o médico antes de doses altas.',
      requiresMedicalSupervision: false,
      sources: [_efsaOmega3, _anvisa],
    ),
    _anabolic('testosterona', 'Testosterona'),
    _anabolic('nandrolona', 'Nandrolona'),
    _anabolic('oxandrolona', 'Oxandrolona', extraCaution: ' Por ser oral, exige atenção especial ao fígado.'),
    _anabolic('trembolona', 'Trembolona'),
  ];

  @override
  Future<Product?> productById(String id) async => products.where((p) => p.id == id).firstOrNull;

  @override
  Future<Product?> productFor(RoutineItem item) async {
    if (item.productId != null) {
      return products.where((p) => p.id == item.productId).firstOrNull;
    }
    final name = item.name.toLowerCase();
    return products.where((p) => p.name.toLowerCase().contains(name) || name.contains(p.id)).firstOrNull;
  }
}
