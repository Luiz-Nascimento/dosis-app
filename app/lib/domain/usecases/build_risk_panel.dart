import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/dose_repository.dart';
import '../repositories/symptom_repository.dart';
import 'check_dose_safety.dart' show anabolicFallbackCaution, convertDose;

/// Nível de um indicador, do mais leve ao que mais pede atenção.
enum RiskLevel {
  /// Nada fora do esperado nos registros.
  ok,

  /// Algo saiu da faixa usual ou se repetiu: vale revisar.
  attention,

  /// Uso que só é seguro com acompanhamento médico (anabolizantes).
  medical,
}

/// Uma linha do painel: o que foi observado nos registros e por quê importa.
class RiskIndicator {
  const RiskIndicator({
    required this.title,
    required this.detail,
    required this.level,
    this.caution,
    this.sources = const [],
  });

  final String title;
  final String detail;
  final RiskLevel level;

  /// Cuidado do catálogo para o produto, quando há algo a observar.
  final String? caution;
  final List<Source> sources;

  String get sourcesFormatted => sources.map((s) => s.name).toSet().join(' / ');
}

/// Painel dos últimos 7 dias.
class RiskPanel {
  const RiskPanel({required this.from, required this.to, required this.doses, required this.symptoms});

  /// Primeiro e último dia analisados (meia-noite, horário do aparelho).
  final DateTime from;
  final DateTime to;

  /// Um indicador por suplemento com dose registrada no período.
  final List<RiskIndicator> doses;

  /// Indicador dos sintomas registrados no período.
  final RiskIndicator symptoms;

  List<RiskIndicator> get all => [...doses, symptoms];

  /// O nível geral é o do indicador que mais pede atenção.
  RiskLevel get level => all.map((i) => i.level).reduce((a, b) => a.index >= b.index ? a : b);
}

/// Painel de indicadores de risco a partir das doses e sintomas registrados.
///
/// Compara os registros dos últimos 7 dias com as faixas do catálogo. Não é
/// diagnóstico: aponta o que vale revisar ou levar a um profissional.
class BuildRiskPanel {
  const BuildRiskPanel(this._doses, this._catalog, this._symptoms);

  final DoseRepository _doses;
  final CatalogRepository _catalog;
  final SymptomRepository _symptoms;

  static const _days = 7;

  Future<RiskPanel> call({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final to = DateTime(at.year, at.month, at.day);
    final from = DateTime(to.year, to.month, to.day - (_days - 1));
    final end = DateTime(to.year, to.month, to.day + 1).subtract(const Duration(milliseconds: 1));
    bool inPeriod(DateTime date) => !date.toLocal().isBefore(from) && !date.toLocal().isAfter(end);

    final doseLogs = (await _doses.list(from: from, to: end, limit: 500)).where((l) => inPeriod(l.takenAt));
    final symptomLogs = (await _symptoms.list(from: from, to: end, limit: 500)).where((l) => inPeriod(l.loggedAt));

    final byProduct = <String, List<DoseLog>>{};
    for (final log in doseLogs) {
      byProduct.putIfAbsent(log.productId ?? log.name.trim().toLowerCase(), () => []).add(log);
    }

    final doses = <RiskIndicator>[];
    for (final logs in byProduct.values) {
      doses.add(await _doseIndicator(logs));
    }
    // O que mais pede atenção aparece primeiro.
    doses.sort((a, b) => b.level.index.compareTo(a.level.index));

    final anabolicInUse = doses.any((i) => i.level == RiskLevel.medical);
    return RiskPanel(from: from, to: to, doses: doses, symptoms: _symptomIndicator(symptomLogs.toList(), anabolicInUse));
  }

  Future<RiskIndicator> _doseIndicator(List<DoseLog> logs) async {
    logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    final latest = logs.first;
    final daysUsed = logs.map((l) => _day(l.takenAt)).toSet().length;
    final used = 'Registrado em $daysUsed de $_days dias';

    Product? product;
    try {
      product = latest.productId == null ? null : await _catalog.productById(latest.productId!);
    } catch (_) {
      // Sem catálogo (ex.: offline): segue sem a comparação com a faixa.
    }
    final name = product?.name ?? latest.name;

    if (latest.kind == ProductKind.anabolic || (product?.requiresMedicalSupervision ?? false)) {
      return RiskIndicator(
        title: '$name: requer acompanhamento médico',
        detail: '$used. Não existe faixa segura de uso sem prescrição.',
        level: RiskLevel.medical,
        caution: product?.caution ?? anabolicFallbackCaution,
        sources: product?.sources ?? const [],
      );
    }

    final range = product?.rangeFor(latest.protocol);
    if (product == null || range == null) {
      return RiskIndicator(
        title: '$name: sem faixa de referência',
        detail: '$used. O catálogo não tem faixa para comparar; siga a porção do rótulo.',
        level: RiskLevel.ok,
        caution: product?.caution,
      );
    }

    final unit = range.unit.label;
    final perDay = range.per == 'day';
    final limits = '${_fmt(range.min)} a ${_fmt(range.max)} $unit ${perDay ? 'por dia' : 'por tomada'}';

    // Por dia: compara a soma de cada dia. Por tomada: compara cada dose.
    final amounts = <DateTime, List<double>>{};
    for (final log in logs) {
      final amount = convertDose(log.amount, log.unit, range.unit);
      if (amount != null) amounts.putIfAbsent(_day(log.takenAt), () => []).add(amount);
    }
    if (amounts.isEmpty) {
      return RiskIndicator(
        title: '$name: unidade diferente da faixa',
        detail: '$used em ${latest.unit.label}; a faixa do catálogo é em $unit e não dá para comparar.',
        level: RiskLevel.ok,
      );
    }

    var daysAbove = 0;
    var peak = 0.0;
    for (final values in amounts.values) {
      final value = perDay ? values.reduce((a, b) => a + b) : values.reduce((a, b) => a > b ? a : b);
      if (value > peak) peak = value;
      if (value > range.max + 1e-9) daysAbove++;
    }

    if (daysAbove == 0) {
      return RiskIndicator(
        title: '$name: dentro da faixa usual',
        detail: '$used. Faixa usual: $limits.',
        level: RiskLevel.ok,
      );
    }
    return RiskIndicator(
      title: '$name: acima da faixa em $daysAbove de $_days dias',
      detail: '${perDay ? 'Maior soma em um dia' : 'Maior dose'}: ${_fmt(peak)} $unit. Faixa usual: $limits.',
      level: RiskLevel.attention,
      caution: product.caution,
      sources: range.sources.isEmpty ? product.sources : range.sources,
    );
  }

  RiskIndicator _symptomIndicator(List<SymptomLog> logs, bool anabolicInUse) {
    if (logs.isEmpty) {
      return const RiskIndicator(
        title: 'Sintomas: nenhum registro na semana',
        detail: 'Registrar como você se sente ajuda a perceber alterações cedo.',
        level: RiskLevel.ok,
      );
    }

    final different = logs.where((l) => l.status == SymptomStatus.different).toList();
    final daysWithSymptoms = different.map((l) => _day(l.loggedAt)).toSet().length;
    if (daysWithSymptoms == 0) {
      return const RiskIndicator(
        title: 'Sintomas: nada de diferente na semana',
        detail: 'Todos os seus registros foram "Normal".',
        level: RiskLevel.ok,
      );
    }

    final palpitationDays =
        different.where((l) => l.symptoms.contains(Symptom.palpitation)).map((l) => _day(l.loggedAt)).toSet().length;
    final labels = different.expand((l) => l.symptoms).toSet().map((s) => s.label.toLowerCase()).join(', ');
    final doctor = anabolicInUse ? ' Como há anabolizante em uso, leve esses registros ao seu médico.' : '';

    if (palpitationDays > 0) {
      return RiskIndicator(
        title: 'Sintomas: palpitação em $palpitationDays ${palpitationDays == 1 ? 'dia' : 'dias'}',
        detail: 'Registrados na semana: $labels. Palpitação que se repete ou vem com dor no peito ou '
            'falta de ar pede avaliação médica.$doctor',
        level: RiskLevel.attention,
      );
    }
    // Um dia isolado é só informação; a partir de 3 dias na semana vale revisar.
    final frequent = daysWithSymptoms >= 3;
    return RiskIndicator(
      title: 'Sintomas em $daysWithSymptoms de $_days dias',
      detail: 'Registrados na semana: $labels.'
          '${frequent ? ' Se continuarem, converse com um profissional de saúde.' : ''}$doctor',
      level: frequent || anabolicInUse ? RiskLevel.attention : RiskLevel.ok,
    );
  }

  static DateTime _day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');
}
