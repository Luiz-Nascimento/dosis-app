/// Valores fixos da API, com o rótulo exibido no app (Figma).
library;

T _fromApi<T extends Enum>(List<T> values, String? value, String Function(T) apiValue, T fallback) {
  for (final item in values) {
    if (apiValue(item) == value) return item;
  }
  return fallback;
}

enum ProductKind {
  supplement('supplement', 'Suplemento'),
  anabolic('anabolic', 'Anabolizante');

  const ProductKind(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ProductKind fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, supplement);
}

enum Protocol {
  continuous('continuous', 'Uso contínuo'),
  loading('loading', 'Protocolo de saturação'),
  cycle('cycle', 'Ciclo'),
  asNeeded('as_needed', 'Quando necessário');

  const Protocol(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static Protocol fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, continuous);
}

enum DoseUnit {
  g('g', 'g'),
  mg('mg', 'mg'),
  mcg('mcg', 'mcg'),
  ml('ml', 'ml'),
  ui('ui', 'UI'),
  caps('caps', 'cápsulas'),
  tabs('tabs', 'comprimidos'),
  drops('drops', 'gotas');

  const DoseUnit(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static DoseUnit fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, g);
}

enum BiologicalSex {
  male('male', 'Masculino'),
  female('female', 'Feminino'),
  undisclosed('undisclosed', 'Prefiro não dizer');

  const BiologicalSex(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static BiologicalSex? fromApi(String? value) =>
      value == null ? null : _fromApi(values, value, (e) => e.apiValue, undisclosed);
}

enum Goal {
  hypertrophy('hypertrophy', 'Hipertrofia'),
  weightLoss('weight_loss', 'Emagrecimento'),
  performance('performance', 'Performance'),
  generalHealth('general_health', 'Saúde geral');

  const Goal(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static Goal? fromApi(String? value) => value == null ? null : _fromApi(values, value, (e) => e.apiValue, generalHealth);
}

enum SymptomStatus {
  normal('normal', 'Não senti nada de diferente'),
  different('different', 'Senti algo diferente');

  const SymptomStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static SymptomStatus fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, normal);
}

enum Symptom {
  pain('pain', 'Dor'),
  dizziness('dizziness', 'Tontura'),
  fatigue('fatigue', 'Cansaço'),
  nausea('nausea', 'Náusea'),
  palpitation('palpitation', 'Palpitação'),
  hairLoss('hair_loss', 'Queda de cabelo'),
  acne('acne', 'Acne'),
  moodChange('mood_change', 'Alteração de humor'),
  other('other', 'Outro');

  const Symptom(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static Symptom fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, other);
}

/// Rede usada no envio do lote de sincronização.
enum NetworkType {
  wifi('wifi'),
  ethernet('ethernet'),
  cellular('cellular'),
  none('none'),
  unknown('unknown');

  const NetworkType(this.apiValue);
  final String apiValue;
}

enum SyncOp {
  upsert('upsert'),
  delete('delete');

  const SyncOp(this.apiValue);
  final String apiValue;
}

/// Entidades aceitas pelo sync, na ordem em que devem ser enviadas.
enum SyncEntity {
  profile('profile'),
  routineItems('routine_items'),
  doseLogs('dose_logs'),
  symptomLogs('symptom_logs'),
  hydrationLogs('hydration_logs');

  const SyncEntity(this.apiValue);
  final String apiValue;
}

enum SyncResultStatus {
  /// Gravado agora: marque como enviado.
  applied('applied'),

  /// Já tinha sido gravado: marque como enviado.
  duplicate('duplicate'),

  /// O servidor tem versão mais nova: marque como enviado e recarregue o registro.
  stale('stale'),

  /// Dados inválidos: não reenvie sem corrigir.
  rejected('rejected');

  const SyncResultStatus(this.apiValue);
  final String apiValue;

  bool get isSent => this != rejected;

  static SyncResultStatus fromApi(String? value) => _fromApi(values, value, (e) => e.apiValue, rejected);
}

enum RestoreMode {
  /// Atualiza os registros do backup e mantém os demais.
  merge('merge'),

  /// Deixa só os registros do backup.
  replace('replace');

  const RestoreMode(this.apiValue);
  final String apiValue;
}
