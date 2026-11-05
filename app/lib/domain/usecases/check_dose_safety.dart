import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';

/// Resultado da avaliação de segurança da dose a ser registrada.
class DoseSafetyCheck {
  const DoseSafetyCheck({
    required this.isAboveRange,
    this.recommendedMin,
    this.recommendedMax,
    this.unit = DoseUnit.g,
    this.protocol = Protocol.continuous,
    this.message,
    this.caution,
    this.sources = const [],
  });

  /// Indica se a dose ultrapassa a faixa recomendada para o protocolo.
  final bool isAboveRange;

  /// Limite inferior da faixa de dose recomendada.
  final double? recommendedMin;

  /// Limite superior da faixa de dose recomendada.
  final double? recommendedMax;

  /// Unidade de medida da dose (g, mg, etc.).
  final DoseUnit unit;

  /// Protocolo avaliado (ex: contínuo, saturação).
  final Protocol protocol;

  /// Mensagem amigável e não-alarmista explicando a situação.
  final String? message;

  /// Recomendações médicas/fisiológicas de atenção (ex: rins e creatinina).
  final String? caution;

  /// Fontes científicas oficiais que embasam a recomendação (ANVISA, ISSN, etc.).
  final List<Source> sources;

  /// Retorna o nome formatado das fontes (ex: "ISSN / ANVISA").
  String get sourcesFormatted {
    if (sources.isEmpty) return 'Fontes oficiais de saúde';
    return sources.map((s) => s.name).toSet().join(' / ');
  }
}

/// Caso de uso que avalia a segurança de uma dose com base em evidências científicas.
///
/// Diretrizes para Creatina (ISSN 2017 / ANVISA):
/// - Uso contínuo (manutenção): 3 g a 5 g por dia. Doses acima de 5g acionam alerta preventivo.
/// - Saturação: 15 g a 25 g por dia (divididas em tomadas), por 5 a 7 dias. Doses acima de 25g acionam alerta.
class CheckDoseSafety {
  const CheckDoseSafety();

  DoseSafetyCheck call({
    required String productName,
    required double amount,
    required DoseUnit unit,
    required Protocol protocol,
  }) {
    final lowerName = productName.toLowerCase();

    // Verificação específica para creatina
    if (lowerName.contains('creatina')) {
      // Normaliza mg para g se necessário
      final amountInGrams = unit == DoseUnit.mg ? amount / 1000.0 : amount;

      final issnSource = const Source(
        id: 'issn-creatina-2017',
        name: 'ISSN',
        citation:
            'Kreider RB et al. International Society of Sports Nutrition position stand: safety and efficacy of creatine supplementation. 2017.',
        url: 'https://doi.org/10.1186/s12970-017-0173-z',
      );
      final anvisaSource = const Source(
        id: 'anvisa-suplementos',
        name: 'ANVISA',
        citation: 'ANVISA. RDC nº 243/2018 e Instrução Normativa nº 28/2018: suplementos alimentares.',
        url: 'https://www.gov.br/anvisa/pt-br/assuntos/alimentos/suplementos-alimentares',
      );

      const cautionText =
          'Em pessoas saudáveis, doses usuais não mostraram prejuízo aos rins. A creatina pode elevar a creatinina sérica no exame de sangue: avise seu médico que faz uso. Doses excessivas não aumentam a eficácia e geram sobrecarga desnecessária.';

      if (protocol == Protocol.loading) {
        // Protocolo de saturação: 15g a 25g
        const min = 15.0;
        const max = 25.0;
        if (amountInGrams > max) {
          return DoseSafetyCheck(
            isAboveRange: true,
            recommendedMin: min,
            recommendedMax: max,
            unit: DoseUnit.g,
            protocol: protocol,
            message:
                'A dose informada (${amountInGrams.toStringAsFixed(1).replaceAll('.0', '')} g) está acima da faixa usual para protocolo de saturação (15 a 25 g/dia por 5 a 7 dias).',
            caution: cautionText,
            sources: [issnSource, anvisaSource],
          );
        }
      } else {
        // Uso contínuo (padrão) e outros: 3g a 5g
        const min = 3.0;
        const max = 5.0;
        if (amountInGrams > max) {
          return DoseSafetyCheck(
            isAboveRange: true,
            recommendedMin: min,
            recommendedMax: max,
            unit: DoseUnit.g,
            protocol: protocol,
            message:
                'A dose informada (${amountInGrams.toStringAsFixed(1).replaceAll('.0', '')} g) está acima da faixa normalmente utilizada em protocolos de uso contínuo (3 a 5 g/dia).',
            caution: cautionText,
            sources: [issnSource, anvisaSource],
          );
        }
      }
    }

    // Se estiver dentro da faixa segura ou não for produto com regra rígida
    return const DoseSafetyCheck(isAboveRange: false);
  }
}
