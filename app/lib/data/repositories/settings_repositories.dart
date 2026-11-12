import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/settings_repository.dart';
import '../models/json.dart';
import '../models/settings.dart';

/// Preferências no armazenamento seguro do aparelho, o mesmo dos tokens.
///
/// Se o armazenamento não estiver disponível (ex.: Linux sem chaveiro), as
/// preferências valem só enquanto o app estiver aberto, em vez de dar erro.
class SecureSettingsRepository implements SettingsRepository {
  SecureSettingsRepository([this._storage = const FlutterSecureStorage()]);

  static const _key = 'dosis.settings';

  final FlutterSecureStorage _storage;
  UserSettings? _cached;

  @override
  Future<UserSettings> load() async {
    if (_cached != null) return _cached!;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) return _cached = UserSettings.fromJson(jsonDecode(raw) as Json);
    } catch (_) {
      // Dado ilegível ou armazenamento indisponível: usa o padrão.
    }
    return _cached = const UserSettings();
  }

  @override
  Future<void> save(UserSettings settings) async {
    _cached = settings;
    try {
      await _storage.write(key: _key, value: jsonEncode(settings.toJson()));
    } catch (_) {
      // Segue valendo em memória.
    }
  }
}

/// Preferências em memória, para os testes.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this._settings = const UserSettings()]);

  UserSettings _settings;

  @override
  Future<UserSettings> load() async => _settings;

  @override
  Future<void> save(UserSettings settings) async => _settings = settings;
}
