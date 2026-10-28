import '../../core/api/api_client.dart';
import '../models/json.dart';

/// Base dos CRUDs de registros do usuário (rotina, doses, sintomas, água).
///
/// Todo `create` aceita um `id` gerado no app ([newId]): um registro criado
/// offline mantém o mesmo id quando chega ao servidor, e reenviar dá 409
/// (`already_exists`) em vez de duplicar.
abstract class CollectionService<T> {
  CollectionService(this.api, this.path);

  final ApiClient api;
  final String path;

  T fromJson(Json json);

  Future<List<T>> listWhere(Map<String, Object?> query) async {
    final json = await api.get('$path/', query: query) as Json;
    return (json['results'] as List).map((e) => fromJson(e as Json)).toList();
  }

  Future<T> get(String id) async => fromJson(await api.get('$path/$id/') as Json);

  Future<T> createFrom(Map<String, Object?> data) async => fromJson(await api.post('$path/', body: data) as Json);

  /// Edição parcial: envie só o que mudou. Use `null` para apagar um campo opcional.
  Future<T> update(String id, Map<String, Object?> changes) async =>
      fromJson(await api.patch('$path/$id/', body: changes) as Json);

  Future<void> delete(String id) => api.delete('$path/$id/');
}
