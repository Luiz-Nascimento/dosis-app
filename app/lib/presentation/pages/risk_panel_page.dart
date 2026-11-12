import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/build_risk_panel.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import 'symptom_report_page.dart';

/// "Painel de risco": indicadores dos últimos 7 dias a partir das
/// doses e dos sintomas registrados, com atalho para o relatório semanal.
class RiskPanelPage extends ConsumerWidget {
  const RiskPanelPage({super.key});

  static Color _color(RiskLevel level) => switch (level) {
        RiskLevel.ok => AppColors.yellow,
        RiskLevel.attention => AppColors.orange,
        RiskLevel.medical => AppColors.orange,
      };

  static IconData _icon(RiskLevel level) => switch (level) {
        RiskLevel.ok => Icons.check_circle_outline,
        RiskLevel.attention => Icons.warning_amber_rounded,
        RiskLevel.medical => Icons.medical_services_outlined,
      };

  static (String, String) _summary(RiskLevel level) => switch (level) {
        RiskLevel.ok => ('Sem alertas na semana', 'Seus registros estão dentro do esperado.'),
        RiskLevel.attention => ('Vale revisar', 'Algum registro saiu da faixa usual. Veja os detalhes abaixo.'),
        RiskLevel.medical => (
            'Acompanhamento médico',
            'Há uso registrado que só é seguro com acompanhamento de um médico.',
          ),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(riskPanelProvider);

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader('Painel de risco'),
          const SizedBox(height: 12),
          ...async.when(
            loading: () => const [
              Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'Não foi possível montar o painel: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ],
            data: (panel) => _content(context, panel),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, RiskPanel panel) {
    final (title, subtitle) = _summary(panel.level);
    final color = _color(panel.level);

    return [
      DosisCard(
        borderColor: color,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(_icon(panel.level), color: color, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(
                    'Últimos 7 dias: ${formatDay(panel.from)} a ${formatDay(panel.to)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle('Doses registradas', subtitle: 'Comparadas com as faixas do catálogo'),
      const SizedBox(height: 12),
      if (panel.doses.isEmpty)
        const DosisCard(
          child: Text('Nenhuma dose registrada nos últimos 7 dias.', style: TextStyle(color: AppColors.muted)),
        ),
      for (final indicator in panel.doses) ...[
        _IndicatorCard(indicator: indicator, color: _color(indicator.level), icon: _icon(indicator.level)),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      const SectionTitle('Sintomas', subtitle: 'O que você registrou em "Como se sente hoje?"'),
      const SizedBox(height: 12),
      _IndicatorCard(
        indicator: panel.symptoms,
        color: _color(panel.symptoms.level),
        icon: _icon(panel.symptoms.level),
      ),
      const SizedBox(height: 12),
      NavCard(
        icon: Icons.insert_chart_outlined,
        title: 'Relatório semanal de sintomas',
        subtitle: 'Frequência, dias e observações da semana',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SymptomReportPage()),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'O painel compara seus registros com faixas de referência de fontes oficiais. '
        'Ele não é um diagnóstico e não substitui a orientação de um profissional de saúde.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
      ),
    ];
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.indicator, required this.color, required this.icon});

  final RiskIndicator indicator;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final flagged = indicator.level != RiskLevel.ok;
    return DosisCard(
      borderColor: flagged ? color : AppColors.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(indicator.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(indicator.detail, style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFFE2E2E2))),
                if (flagged && indicator.caution != null) ...[
                  const SizedBox(height: 8),
                  Text(indicator.caution!, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.muted)),
                ],
                if (flagged && indicator.sources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fonte: ${indicator.sourcesFormatted}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
