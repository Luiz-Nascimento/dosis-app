# Dosis — App (Flutter)

App Android (8.0+, API 26) em Flutter/Dart. Esta base traz a **camada de
dados**: os services que consomem todos os endpoints do backend
(`../backend`). As telas do Figma entram por cima dela.

## Rodando

```bash
cd backend && python manage.py runserver 0.0.0.0:8000   # em outro terminal
cd app
flutter pub get
flutter run                     # emulador Android: a API fica em http://10.0.2.2:8000
```

Para outro servidor: `flutter run --dart-define=API_BASE_URL=https://.../api/v1`.
A tela inicial só confere se a API responde.

## Como usar

```dart
final api = DosisApi.secure(); // tokens e chave do sync no Android Keystore

await api.auth.signInAnonymously();
final creatina = await api.routine.create(productId: 'creatina');
await api.doses.register(routineItemId: creatina.id); // "Registrar dose" em 3 toques
final hoje = await api.doses.list(from: DateTime.now(), to: DateTime.now());
```

Erros chegam como `ApiException`: decida pelo `code` (ex.: `wifi_required`,
`invalid_credentials`, `validation_error`) e mostre a `message`, que já vem em
português. `fieldErrors` traz os erros por campo dos formulários. Sem internet,
o `code` é `network_error`. O token expirado é renovado sozinho.

| Service | Endpoints (em `/api/v1/`) | Telas |
| --- | --- | --- |
| `api.system` | `system/health/`, `system/diagnostics/firestore/` | — |
| `api.auth` | `auth/*` (anônimo, cadastro, login, vincular, confirmar e-mail, recuperar senha, excluir conta) | Introdução, Login, Cadastro |
| `api.profile` | `profile/` | Perfil, Meus dados, Objetivo, Notificações |
| `api.catalog` | `catalog/products/` | Adicionar à rotina |
| `api.articles` | `catalog/articles/` | Conteúdos educativos |
| `api.routine` | `tracking/routine-items/` | Seus itens, Stack de hoje |
| `api.doses` | `tracking/doses/` | Registrar dose, Registros, Editar stack do dia |
| `api.symptoms` | `tracking/symptoms/` | Como se sente hoje? |
| `api.hydration` | `tracking/hydration/` | Hidratação |
| `api.sync` | `sync/*` (política, aviso, chave, lotes, status, eventos) | Fila offline |
| `api.backups` | `backups/*` (criar, baixar, restaurar) | Perfil |
| `api.monitoring` | `sync/admin/*` | Equipe (admin) |

* **Ids gerados no app:** `newId()` (`lib/core/ids.dart`). Registro criado offline
  mantém o mesmo id ao chegar ao servidor.
* **Alerta de dose:** `Product.rangeFor(protocol)?.isAbove(dose)` e as fontes
  em `DoseRange.sources`.
* **Sincronização:** `sync.consent()` → mostrar `notice.text` →
  `sync.acceptConsent(versão)` → `sync.pairDevice(deviceId)` (uma vez) →
  `sync.sendBatch(network: NetworkType.wifi, records: [...])`. O lote vai
  comprimido e criptografado (X25519 + HKDF + AES-256-GCM).
  `SyncBatchResult.sentMutationIds` diz o que pode sair da fila.

## Estrutura

```
lib/
  core/api/        ApiClient, ApiException, armazenamento seguro dos tokens
  core/ids.dart    UUID para registros criados offline
  data/models/     modelos tipados de cada recurso
  data/services/   um service por grupo de endpoints
  data/dosis_api.dart  agrega todos os services
```

## Testes

```bash
flutter test                                    # unitários (servidor simulado)
DOSIS_API_URL=http://127.0.0.1:8000/api/v1 flutter test test/integration
```

O teste de integração percorre todos os grupos de endpoints contra o Django
rodando, inclusive o sync cifrado. Ele é pulado se `DOSIS_API_URL` não estiver
definido.
