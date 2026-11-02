import '../data/models/enums.dart';

String formatAmount(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString().replaceAll('.', ',');

/// "60g" (ou "60 g" com [space]).
String formatDose(double? amount, DoseUnit unit, {bool space = false}) {
  if (amount == null) return '—';
  return '${formatAmount(amount)}${space ? ' ' : ''}${unit.label}';
}