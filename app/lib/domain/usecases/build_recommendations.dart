import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/recommendation.dart';
import '../../data/models/settings.dart';
import '../../data/models/tracking.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/dose_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/routine_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/symptom_repository.dart';
import 'check_dose_safety.dart' show anabolicFallbackCaution, convertDose;

/// Motor de recomendações: cruza os registros do usuário com as diretrizes
/// cadastradas no catálogo (faixas de dose e fontes ANVISA, SBEM, ISSN...).
///
/// O resultado alimenta a seção "Recomendações para você" e o texto das
/// notificações educacionais. Não é diagnóstico: aponta o que vale revisar.
class BuildRecommendations {
  const BuildRecommendations(
    this._doses,
    this._catalog,
    this._symptoms,
    this._routine,
    this._hydration,
    this._settings,
  );

  final DoseRepository _doses;
  final CatalogRepository _catalog;
  final SymptomRepository _symptoms;
  final RoutineRepository _routine;
  final HydrationRepository _hydration;
  final SettingsRepository _settings;

  static const _days = 7;

  static const _acsm = Source(
    id: 'acsm-hidratacao-2007',
    name: 'ACSM',
    citation: 'Sawka MN et al. American College of Sports Medicine position stand: exercise and fluid '
        'replacement. Med Sci Sports Exerc. 2007;39(2):377-390.',
    url: 'https://doi.org/10.1249/mss.0b013e31802ca597',
  );

  Future<List<Recommendation>> call({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final to = DateTime(at.year, at.month, at.day);
    final from = DateTime(to.year, to.month, to.day - (_days - 1));
    final end = DateTime(to.year, to.month, to.day + 1).subtract(const Duration(milliseconds: 1));

    final doseLogs = await _safe(() => _doses.list(from: from, to: end, limit: 500), const <DoseLog>[]);
    final symptomLogs =
        await _safe(() => _symptoms.list(from: from, to: end, limit: 500), const <SymptomLog>[]);
    final activeItems = await _safe(() => _routine.list(active: true), const <RoutineItem>[]);
    final settings = await _safe(() => _settings.load(), const UserSettings());

    final recommendations = <Recommendation>[];

    final byProduct = <String, List<DoseLog>>{};
    for (final log in doseLogs) {
      byProduct.putIfAbsent(log.productId ?? log.name.trim().toLowerCase(), () => []).add(log);
    }
    for (final entry in byProduct.entries) {
      final recommendation = await _doseRecommendation(entry.key, entry.value);
      if (recommendation != null) recommendations.add(recommendation);
    }

    final symptomRecommendation = _symptomRecommendation(symptomLogs);
    if (symptomRecommendation != null) recommendations.add(symptomRecommendation);

    final hydrationRecommendation =
        await _hydrationRecommendation(from: to, to: end, settings: settings, hour: at.hour);
    if (hydrationRecommendation != null) recommendations.add(hydrationRecommendation);

    if (activeItems.isNotEmpty && doseLogs.isEmpty) {
      recommendations.add(const Recommendation(
        id: 'sem-registros',
        title: 'Registre suas doses para receber dicas melhores',
        body: 'Você tem itens na rotina, mas nenhuma dose registrada nos últimos 7 dias. '
            'Com poucos toques no Dosis, as recomendações passam a considerar o que você realmente toma.',
        level: RecommendationLevel.info,
      ));
    } else if (activeItems.isEmpty) {
      recommendations.add(const Recommendation(
        id: 'sem-rotina',
        title: 'Monte sua rotina no Dosis',
        body: 'Adicione seus suplementos para o app comparar as doses com as faixas usuais e '
            'avisar quando algo sair do esperado.',
        level: RecommendationLevel.info,
      ));
    }

    if (recommendations.isEmpty) {
      final tip = await _guidelineTip();
      if (tip != null) recommendations.add(tip);
    }

    // O que mais pede atenção aparece primeiro.
    recommendations.sort((a, b) => b.level.index.compareTo(a.level.index));
    return recommendations;
  }

  Future<Recommendation?> _doseRecommendation(String key, List<DoseLog> logs) async {
    logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    final latest = logs.first;

    Product? product;
    if (latest.productId != null) {
      product = await _safe<Product?>(() => _catalog.productById(latest.productId!), null);
    }
    final name = product?.name ?? latest.name;

    if (latest.kind == ProductKind.anabolic || (product?.requiresMedicalSupervision ?? false)) {
      return Recommendation(
        id: 'anabolico-$key',
        title: '$name: acompanhamento médico é essencial',
        body: product?.caution ?? anabolicFallbackCaution,
        level: RecommendationLevel.medical,
        sources: product?.sources ?? const [],
      );
    }

    final range = product?.rangeFor(latest.protocol);
    if (product == null || range == null) return null;

    final unit = range.unit.label;
    final perDay = range.per == 'day';

    // Por dia: soma de cada dia. Por tomada: a maior dose registrada.
    final byDay = <DateTime, double>{};
    var peakSingle = 0.0;
    for (final log in logs) {
      final amount = convertDose(log.amount, log.unit, range.unit);
      if (amount == null) continue;
      final local = log.takenAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay[day] = (byDay[day] ?? 0) + amount;
      if (amount > peakSingle) peakSingle = amount;
    }
    if (byDay.isEmpty) return null;

    final peak = perDay ? byDay.values.reduce((a, b) => a > b ? a : b) : peakSingle;
    if (peak <= range.max + 1e-9) return null;

    final total = _fmt(peak);
    final limits = '${_fmt(range.min)} a ${_fmt(range.max)} $unit';
    final title = 'Seu corpo não precisa de $total $unit de ${product.name}';
    final body = perDay
        ? 'A faixa usual é de $limits por dia. Acima disso não há ganho proporcional: a diretriz '
            'indica que essa quantidade já cobre a necessidade. Ajuste a dose e, se tiver dúvida, '
            'converse com um profissional.'
        : 'A faixa usual é de $limits por tomada. Uma dose maior não traz benefício proporcional. '
            'Ajuste a porção e, se tiver dúvida, converse com um profissional.';

    return Recommendation(
      id: 'dose-$key',
      title: title,
      body: body,
      level: RecommendationLevel.attention,
      sources: range.sources.isEmpty ? product.sources : range.sources,
    );
  }

  Recommendation? _symptomRecommendation(List<SymptomLog> logs) {
    final different = logs.where((l) => l.status == SymptomStatus.different).toList();
    if (different.isEmpty) return null;

    final palpitationDays =
        different.where((l) => l.symptoms.contains(Symptom.palpitation)).map((l) => _day(l.loggedAt)).toSet().length;
    if (palpitationDays > 0) {
      return Recommendation(
        id: 'sintoma-palpitacao',
        title: 'Palpitação registrada: vale avaliar',
        body: 'Você registrou palpitação em $palpitationDays ${palpitationDays == 1 ? 'dia' : 'dias'}. '
            'Se ela se repete ou vem com dor no peito, falta de ar ou desmaio, procure atendimento '
            '(SAMU 192). Caso contrário, leve o registro ao seu médico.',
        level: RecommendationLevel.attention,
      );
    }

    final days = different.map((l) => _day(l.loggedAt)).toSet().length;
    if (days < 3) return null;

    final labels = different.expand((l) => l.symptoms).toSet().map((s) => s.label.toLowerCase()).join(', ');
    return Recommendation(
      id: 'sintoma-frequente',
      title: 'Sintomas em $days de $_days dias',
      body: 'Sinais registrados: $labels. Quando se repetem assim, vale revisar a rotina e conversar '
          'com um profissional de saúde.',
      level: RecommendationLevel.attention,
    );
  }

  Future<Recommendation?> _hydrationRecommendation({
    required DateTime from,
    required DateTime to,
    required UserSettings settings,
    required int hour,
  }) async {
    final logs = await _safe(() => _hydration.list(from: from, to: to, limit: 500), const <HydrationLog>[]);
    if (logs.isEmpty) return null;

    final total = logs.fold<int>(0, (sum, log) => sum + log.amountMl);
    final goal = settings.hydrationGoalMl;
    if (goal <= 0 || total >= goal * 0.5) return null;

    // De manhã ainda dá tempo de recuperar; o aviso só faz sentido à tarde.
    if (hour < 12) return null;

    final goalLiters = (goal / 1000).toStringAsFixed(1).replaceAll('.', ',');
    final totalLiters = (total / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return Recommendation(
      id: 'hidratacao-baixa',
      title: 'Você bebeu $totalLiters L de $goalLiters L hoje',
      body: 'Ainda dá tempo de recuperar. Beba água ao longo do dia e, em treinos longos ou no '
          'calor, reponha o que perdeu no suor.',
      level: RecommendationLevel.info,
      sources: const [_acsm],
    );
  }

  Future<Recommendation?> _guidelineTip() async {
    final creatina = await _safe<Product?>(() => _catalog.productById('creatina'), null);
    final range = creatina?.rangeFor(Protocol.continuous);
    if (creatina == null || range == null) return null;

    final source = range.sources.isEmpty ? creatina.sources : range.sources;
    final note = range.note.trim();
    final noteText = note.isEmpty ? '' : '${note[0].toLowerCase()}${note.substring(1)}';
    return Recommendation(
      id: 'dica-creatina',
      title: 'Creatina: ${_fmt(range.min)} a ${_fmt(range.max)} ${range.unit.label} por dia bastam',
      body: 'A diretriz indica $noteText O corpo satura os músculos com a quantidade usual: '
          'não precisa aumentar a dose.',
      level: RecommendationLevel.info,
      sources: source,
    );
  }

  static DateTime _day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1).replaceAll('.', ',');

  static Future<T> _safe<T>(Future<T> Function() run, T fallback) async {
    try {
      return await run();
    } catch (_) {
      return fallback;
    }
  }
}
