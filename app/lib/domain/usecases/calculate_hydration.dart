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

  /// Explicação textual fundamentada em evidências científicas.
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

/// Caso de uso: Cálculo de ingestão diária de água contextualizado com creatina.
///
/// Diretrizes científicas (ACSM, SBEM, ANVISA):
/// - Base para praticantes de atividade física: 35 ml por kg de peso corporal.
/// - Ajuste por creatina: Creatina atrai água para o interior das células musculares
///   (retenção hídrica intracelular). Recomenda-se acréscimo proporcional de
///   100 ml de água por grama de creatina consumida (mínimo de 500 ml para doses usuais).
class CalculateHydration {
  const CalculateHydration();

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
          'Sua meta diária inclui ${(baseMl / 1000).toStringAsFixed(1).replaceAll('.', ',')} L base '
          '(35 ml/kg) mais $bonusFormatted adicionais devido ao uso de creatina (${creatineGrams.toStringAsFixed(1).replaceAll('.0', '')} g no seu stack), '
          'essenciais para a hidratação celular e suporte renal seguro (SBEM/ACSM).';
    } else {
      explanation =
          'Meta diária estimada com base em 35 ml por kg de peso corporal para manutenção do equilíbrio hídrico em praticantes de exercícios físicos.';
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
