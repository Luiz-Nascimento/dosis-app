/// Conversões usadas pelos modelos ao ler o JSON da API.
library;

typedef Json = Map<String, dynamic>;

DateTime? parseDateTime(Object? value) => value == null ? null : DateTime.parse(value as String);

double? toDouble(Object? value) => value == null ? null : (value as num).toDouble();

int? toInt(Object? value) => value == null ? null : (value as num).toInt();

List<String> stringList(Object? value) => value == null ? const [] : List<String>.from(value as List);

/// Datas e horários vão para a API sempre em UTC (ISO 8601).
String? isoDateTime(DateTime? value) => value?.toUtc().toIso8601String();

/// Datas puras (`AAAA-MM-DD`), como `date_from` e `local_date`.
String isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// Remove as chaves nulas (para não apagar campos sem querer num PATCH).
Json compact(Map<String, Object?> values) => {
      for (final entry in values.entries)
        if (entry.value != null) entry.key: entry.value,
    };
