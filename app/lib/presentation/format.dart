import '../data/models/enums.dart';

String formatAmount(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString().replaceAll('.', ',');

/// "60g" (ou "60 g" com [space]).
String formatDose(double? amount, DoseUnit unit, {bool space = false}) {
  if (amount == null) return '—';
  return '${formatAmount(amount)}${space ? ' ' : ''}${unit.label}';
}

const _monthAbbr = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

String _two(int value) => value.toString().padLeft(2, '0');

/// Uma casa decimal no máximo: "4,3" (evita "4,333333").
String formatRounded(double value) => formatAmount(double.parse(value.toStringAsFixed(1)));

/// "12 de nov".
String formatDay(DateTime date) => '${date.day} de ${_monthAbbr[date.month - 1]}';

/// "12/11".
String formatDayShort(DateTime date) => '${_two(date.day)}/${_two(date.month)}';

/// "08:05", no horário do aparelho.
String formatTime(DateTime date) {
  final local = date.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// "1,2 L" a partir de 1000 ml; abaixo disso, "500 ml".
String formatVolume(int ml) => ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1).replaceAll('.', ',')} L' : '$ml ml';
