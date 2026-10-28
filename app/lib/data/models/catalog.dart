import 'enums.dart';
import 'json.dart';

/// Fonte citada nos alertas e artigos (ANVISA, SBEM, ISSN...).
class Source {
  const Source({required this.id, required this.name, required this.citation, required this.url});

  factory Source.fromJson(Json json) => Source(
        id: json['id'] as String,
        name: json['name'] as String,
        citation: json['citation'] as String,
        url: json['url'] as String,
      );

  final String id;
  final String name;
  final String citation;
  final String url;
}

List<Source> _sources(Object? value) =>
    (value as List? ?? const []).map((e) => Source.fromJson(e as Json)).toList();

/// Faixa de dose usual de um produto em um protocolo.
class DoseRange {
  const DoseRange({
    required this.protocol,
    required this.per,
    required this.min,
    required this.max,
    required this.unit,
    required this.note,
    required this.sources,
  });

  factory DoseRange.fromJson(Json json) => DoseRange(
        protocol: Protocol.fromApi(json['protocol'] as String?),
        per: json['per'] as String,
        min: toDouble(json['min'])!,
        max: toDouble(json['max'])!,
        unit: DoseUnit.fromApi(json['unit'] as String?),
        note: json['note'] as String,
        sources: _sources(json['sources']),
      );

  final Protocol protocol;

  /// `day` (por dia) ou `dose` (por tomada).
  final String per;
  final double min;
  final double max;
  final DoseUnit unit;
  final String note;
  final List<Source> sources;

  bool isAbove(double amount) => amount > max;
}

/// Suplemento ou anabolizante do catálogo (`/catalog/products/`).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.kind,
    required this.defaultUnit,
    required this.doseRanges,
    required this.caution,
    required this.requiresMedicalSupervision,
    required this.sources,
    this.defaultDose,
  });

  factory Product.fromJson(Json json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: ProductKind.fromApi(json['kind'] as String?),
        defaultUnit: DoseUnit.fromApi(json['default_unit'] as String?),
        defaultDose: toDouble(json['default_dose']),
        doseRanges: (json['dose_ranges'] as List).map((e) => DoseRange.fromJson(e as Json)).toList(),
        caution: json['caution'] as String,
        requiresMedicalSupervision: json['requires_medical_supervision'] as bool,
        sources: _sources(json['sources']),
      );

  final String id;
  final String name;
  final ProductKind kind;
  final DoseUnit defaultUnit;
  final double? defaultDose;
  final List<DoseRange> doseRanges;
  final String caution;
  final bool requiresMedicalSupervision;
  final List<Source> sources;

  /// Faixa de referência do protocolo, se existir (anabolizantes não têm).
  DoseRange? rangeFor(Protocol protocol) {
    for (final range in doseRanges) {
      if (range.protocol == protocol) return range;
    }
    return null;
  }
}

class ArticleSummary {
  const ArticleSummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.readingMinutes,
    required this.publishedAt,
  });

  factory ArticleSummary.fromJson(Json json) => ArticleSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        tags: stringList(json['tags']),
        readingMinutes: json['reading_minutes'] as int,
        publishedAt: json['published_at'] as String,
      );

  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final int readingMinutes;
  final String publishedAt;
}

class Article extends ArticleSummary {
  const Article({
    required super.id,
    required super.title,
    required super.summary,
    required super.tags,
    required super.readingMinutes,
    required super.publishedAt,
    required this.body,
    required this.sources,
  });

  factory Article.fromJson(Json json) {
    final summary = ArticleSummary.fromJson(json);
    return Article(
      id: summary.id,
      title: summary.title,
      summary: summary.summary,
      tags: summary.tags,
      readingMinutes: summary.readingMinutes,
      publishedAt: summary.publishedAt,
      body: json['body'] as String,
      sources: _sources(json['sources']),
    );
  }

  /// Texto em Markdown.
  final String body;
  final List<Source> sources;
}

/// Lista paginada (`count`, `page`, `page_size`, `results`).
class PageResult<T> {
  const PageResult({required this.count, required this.page, required this.pageSize, required this.results});

  factory PageResult.fromJson(Json json, T Function(Json) item) => PageResult(
        count: json['count'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
        results: (json['results'] as List).map((e) => item(e as Json)).toList(),
      );

  final int count;
  final int page;
  final int pageSize;
  final List<T> results;

  bool get hasNextPage => page * pageSize < count;
}
