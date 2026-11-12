import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/dose_repository.dart';

/// Tipo de alerta que a dose gera antes de ser registrada.
enum DoseAlert {
  /// Dentro da faixa, ou o produto não tem faixa de referência.
  none,

  /// Acima da faixa usual do catálogo (por tomada ou somando o dia).
  aboveRange,

  /// Anabolizante: não existe dose segura sem prescrição, o aviso aparece sempre.
  medicalSupervision,
}

/// Resultado da avaliação de segurança da dose a ser registrada.
class DoseSafetyCheck {
  const DoseSafetyCheck({
    this.alert = DoseAlert.none,
    this.range,
    this.totalToday,
    this.message,
    this.caution,
    this.sources = const [],
  });

  final DoseAlert alert;

  /// Faixa do catálogo usada na comparação, se houver.
  final DoseRange? range;

  /// Soma do dia contando a dose nova, na unidade da faixa (só para faixas "por dia").
  final double? totalToday;

  /// Mensagem curta e não alarmista explicando a situação.
  final String? message;

  /// Cuidados do produto, vindos do catálogo.
  final String? caution;

  /// Fontes que embasam o alerta (ISSN, ANVISA, CFM...).
  final List<Source> sources;

  bool get needsConfirmation => alert != DoseAlert.none;
  bool get isAboveRange => alert == DoseAlert.aboveRange;
  bool get requiresMedicalSupervision => alert == DoseAlert.medicalSupervision;

  /// Nome das fontes sem repetição (ex.: "ISSN / ANVISA").
  String get sourcesFormatted {
    if (sources.isEmpty) return 'Fontes oficiais de saúde';
    return sources.map((s) => s.name).toSet().join(' / ');
  }
}

/// Usado quando um anabolizante foi cadastrado à mão e não está no catálogo.
const anabolicFallbackCaution =
    'Uso apenas com prescrição e acompanhamento médico. O CFM veda a prescrição para fins estéticos ou '
    'de desempenho. Pode afetar coração, fígado, fertilidade, pele e humor.';

/// Avalia a dose com as faixas do catálogo (`backend/apps/catalog/content.py`).
///
/// * Faixa "por dia" (ex.: creatina 3 a 5 g/dia): soma as doses do mesmo produto
///   já registradas no dia com a dose nova.
/// * Faixa "por tomada" (ex.: whey 20 a 40 g): compara só a dose nova.
/// * Anabolizantes: sempre avisa, porque não há faixa segura sem prescrição.
///
/// O alerta nunca bloqueia: a tela pergunta e o usuário decide.
class CheckDoseSafety {
  const CheckDoseSafety(this._catalog, this._doses);

  final CatalogRepository _catalog;
  final DoseRepository _doses;

  Future<DoseSafetyCheck> call({
    required RoutineItem item,
    required double amount,
    required Protocol protocol,
    required DateTime takenAt,
  }) async {
    final product = await _catalog.productFor(item);

    if (item.kind == ProductKind.anabolic || (product?.requiresMedicalSupervision ?? false)) {
      return DoseSafetyCheck(
        alert: DoseAlert.medicalSupervision,
        message: '${product?.name ?? item.name} não tem dose segura de uso sem prescrição médica.',
        caution: product?.caution ?? anabolicFallbackCaution,
        sources: product?.sources ?? const [],
      );
    }

    final range = product?.rangeFor(protocol);
    if (product == null || range == null) return const DoseSafetyCheck();

    final dose = convertDose(amount, item.doseUnit, range.unit);
    // Unidades que não se convertem (ex.: cápsulas x gramas): não dá para comparar.
    if (dose == null) return const DoseSafetyCheck();

    final perDay = range.per == 'day';
    final total = perDay ? dose + await _alreadyTakenOn(takenAt, item, product, range.unit) : dose;

    final unit = range.unit.label;
    final limits = '${_fmt(range.min)} a ${_fmt(range.max)} $unit';
    // Margem pequena para não alertar por erro de arredondamento (ex.: 0,1 + 0,2).
    if (total <= range.max + 1e-9) {
      return DoseSafetyCheck(range: range, totalToday: perDay ? total : null);
    }

    return DoseSafetyCheck(
      alert: DoseAlert.aboveRange,
      range: range,
      totalToday: perDay ? total : null,
      message: perDay && total > dose
          ? 'Somando as doses de hoje, você chegaria a ${_fmt(total)} $unit de ${product.name}, '
              'acima da faixa usual de ${protocol.label.toLowerCase()} ($limits por dia).'
          : 'A dose informada (${_fmt(total)} $unit) está acima da faixa usual de '
              '${protocol.label.toLowerCase()} ($limits ${perDay ? 'por dia' : 'por tomada'}).',
      caution: product.caution,
      sources: range.sources.isEmpty ? product.sources : range.sources,
    );
  }

  /// Quanto do mesmo produto já foi registrado no dia de [at], na unidade [unit].
  Future<double> _alreadyTakenOn(DateTime at, RoutineItem item, Product product, DoseUnit unit) async {
    final start = DateTime(at.year, at.month, at.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final logs = await _doses.list(from: start, to: end);

    var total = 0.0;
    for (final log in logs) {
      final local = log.takenAt.toLocal();
      final sameDay = local.year == at.year && local.month == at.month && local.day == at.day;
      // Mesmo produto do catálogo (ex.: duas marcas de creatina) ou o mesmo item da rotina.
      final sameProduct = log.productId != null ? log.productId == product.id : log.routineItemId == item.id;
      if (sameDay && sameProduct) total += convertDose(log.amount, log.unit, unit) ?? 0;
    }
    return total;
  }
}

const _inMg = {DoseUnit.g: 1000.0, DoseUnit.mg: 1.0, DoseUnit.mcg: 0.001};

/// Converte entre g, mg e mcg. Devolve `null` quando as unidades não se convertem.
double? convertDose(double amount, DoseUnit from, DoseUnit to) {
  if (from == to) return amount;
  final fromMg = _inMg[from];
  final toMg = _inMg[to];
  if (fromMg == null || toMg == null) return null;
  return amount * fromMg / toMg;
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');
