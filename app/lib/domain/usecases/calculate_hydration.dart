import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';

/// Resultado estruturado do cálculo de hidratação diária recomendada.
class HydrationResult {
  const HydrationResult({
    required this.totalMl,
    required this.baseMl,
    required this.creatineBonusMl,
    required this.creatineGrams,
    required this.explanation,
  });

  /// Total diário recomendado em mililitros (ml).
  final int totalMl;

  /// Volume base baseado no peso corporal (ml).
  final int baseMl;

  /// Volume adicional devido ao uso de creatina (ml).
  final int creatineBonusMl;

  /// Quantidade total de creatina identificada no stack diário (em gramas).
  final double creatineGrams;

  /// Explicação do cálculo para o usuário.
  final String explanation;

  /// Formatação do total em litros (ex: "3,2 L").
  String get totalLitersText {
    final l = totalMl / 1000.0;
    return '${l.toStringAsFixed(1).replaceAll('.', ',')} L';
  }

  /// Formatação do volume base em litros.
  String get baseLitersText {
    final l = baseMl / 1000.0;
    return '${l.toStringAsFixed(1).replaceAll('.', ',')} L';
  }
}

/// Caso de uso: estimativa de ingestão diária de água, considerando a creatina do stack.
///
/// Os números são uma regra prática definida pelo app, NÃO uma recomendação de
/// órgão oficial, e o texto mostrado ao usuário diz isso:
/// - Base: 35 ml por kg de peso corporal (regra prática comum, não vem do ACSM).
/// - Creatina: a creatina leva água para dentro das células musculares, então o app
///   acrescenta 100 ml por grama (mínimo de 500 ml) como margem preventiva.
///   Nenhuma diretriz define esse acréscimo.
/// - O que o ACSM (Sawka et al., 2007) recomenda é repor o que se perde no suor,
///   que varia com a pessoa, o treino e o clima: por isso o aviso de beber mais
///   em dias de treino intenso ou calor.
class CalculateHydration {
  const CalculateHydration();

  static const _disclaimer = 'É uma regra prática do app, não uma recomendação oficial. '
      'Em dias de treino intenso ou calor, beba mais para repor o suor (ACSM).';

  static String _grams(double g) =>
      g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1).replaceAll('.', ',');

  HydrationResult call({
    required double weightKg,
    required List<RoutineItem> stackItems,
  }) {
    if (weightKg <= 0) {
      throw ArgumentError('O peso deve ser maior que zero.');
    }

    // 1. Cálculo basal (35 ml / kg)
    final baseMl = (weightKg * 35).round();

    // 2. Detecção de creatina no stack ativo
    double creatineGrams = 0;
    for (final item in stackItems) {
      if (item.name.toLowerCase().contains('creatina')) {
        final dose = item.doseAmount ?? 0.0;
        if (item.doseUnit == DoseUnit.mg) {
          creatineGrams += dose / 1000.0;
        } else {
          // Assume gramas (g) por padrão para creatina
          creatineGrams += dose;
        }
      }
    }

    // 3. Adicional de hidratação por creatina:
    // 100 ml por grama de creatina (mínimo de 500 ml se houver creatina registrada)
    int creatineBonusMl = 0;
    String explanation;

    if (creatineGrams > 0) {
      creatineBonusMl = (creatineGrams * 100).round();
      if (creatineBonusMl < 500) {
        creatineBonusMl = 500;
      }

      final bonusFormatted = creatineBonusMl >= 1000
          ? '${(creatineBonusMl / 1000).toStringAsFixed(1).replaceAll('.', ',')} L'
          : '$creatineBonusMl ml';

      explanation =
          'Estimativa do Dosis: ${(baseMl / 1000).toStringAsFixed(1).replaceAll('.', ',')} L como ponto de partida '
          '(35 ml por kg) mais $bonusFormatted pelo uso de creatina (${_grams(creatineGrams)} g no seu stack). '
          '$_disclaimer';
    } else {
      explanation = 'Estimativa do Dosis: 35 ml por kg de peso como ponto de partida. $_disclaimer';
    }

    final totalMl = baseMl + creatineBonusMl;

    return HydrationResult(
      totalMl: totalMl,
      baseMl: baseMl,
      creatineBonusMl: creatineBonusMl,
      creatineGrams: creatineGrams,
      explanation: explanation,
    );
  }
}
