import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/app_theme.dart';

/// Gráfico de barras simples (uma barra por dia), desenhado à mão para não
/// depender de biblioteca de gráficos e manter o APK pequeno (RNF09).
///
/// [reference] desenha uma linha tracejada (ex.: limite usual do catálogo ou a
/// meta de água); barras acima dela ficam laranja quando [warnAbove] é `true`.
class DosisBarChart extends StatelessWidget {
  const DosisBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.semanticLabel,
    this.reference,
    this.warnAbove = true,
    this.height = 180,
  }) : assert(values.length == labels.length);

  final List<double> values;

  /// Rótulo de cada barra no eixo de baixo. Com muitas barras só alguns são mostrados.
  final List<String> labels;

  /// Descrição lida pelo leitor de tela (o desenho em si não é acessível).
  final String semanticLabel;
  final double? reference;
  final bool warnAbove;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        // O desenho usa a mesma fonte do resto do app (a do tema).
        child: CustomPaint(
          painter: _BarChartPainter(values, labels, reference, warnAbove, DefaultTextStyle.of(context).style.fontFamily),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values, this.labels, this.reference, this.warnAbove, this.fontFamily);

  final List<double> values;
  final List<String> labels;
  final double? reference;
  final bool warnAbove;
  final String? fontFamily;

  static const _axisWidth = 38.0;
  static const _labelHeight = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final peak = values.fold<double>(reference ?? 0, math.max);
    final top = _niceTop(peak <= 0 ? 1 : peak);
    final chart = Rect.fromLTRB(_axisWidth, 8, size.width, size.height - _labelHeight);
    double y(double value) => chart.bottom - (value / top) * chart.height;

    // Linhas de grade com o valor no eixo da esquerda.
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final value in [0.0, top / 2, top]) {
      canvas.drawLine(Offset(chart.left, y(value)), Offset(chart.right, y(value)), grid);
      final text = _text(formatAmount(double.parse(value.toStringAsFixed(1))));
      text.paint(canvas, Offset(chart.left - text.width - 6, y(value) - text.height / 2));
    }

    // Barras.
    final slot = chart.width / values.length;
    final barWidth = math.min(slot * 0.7, 22.0);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;
      final above = warnAbove && reference != null && value > reference! + 1e-9;
      final left = chart.left + slot * i + (slot - barWidth) / 2;
      final radius = Radius.circular(math.min(4, barWidth / 2));
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(left, y(value), left + barWidth, chart.bottom, topLeft: radius, topRight: radius),
        Paint()..color = above ? AppColors.orange : AppColors.yellow,
      );
    }

    // Linha de referência tracejada.
    if (reference != null && reference! > 0) {
      final line = Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5;
      for (var x = chart.left; x < chart.right; x += 9) {
        canvas.drawLine(Offset(x, y(reference!)), Offset(math.min(x + 5, chart.right), y(reference!)), line);
      }
    }

    // Rótulos de baixo: no máximo 6, espaçados por igual.
    final step = math.max(1, (labels.length / 6).ceil());
    for (var i = 0; i < labels.length; i += step) {
      final text = _text(labels[i]);
      final center = chart.left + slot * i + slot / 2;
      final dx = (center - text.width / 2).clamp(chart.left, size.width - text.width);
      text.paint(canvas, Offset(dx, chart.bottom + 5));
    }
  }

  TextPainter _text(String value) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Arredonda o topo do eixo para um número "redondo" (1, 2, 2,5, 5 ou 10 vezes uma potência de 10).
  static double _niceTop(double peak) {
    final magnitude = math.pow(10, (math.log(peak) / math.ln10).floor()).toDouble();
    for (final factor in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (peak <= factor * magnitude) return factor * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.values != values || old.labels != labels || old.reference != reference || old.warnAbove != warnAbove;
}
