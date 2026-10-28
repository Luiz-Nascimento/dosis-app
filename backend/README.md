# Dosis — Backend (Django + Firebase)

API REST que o app Flutter consome. A disciplina exige Firebase para
**Autenticação** e **Banco de Dados**, então:

| Parte | Tecnologia |
| --- | --- |
| Contas e login | Firebase Auth (encapsulado pelos endpoints `/api/v1/auth/*`) |
| Dados | Cloud Firestore (todos os dados, inclusive auditoria e backups) |
| Regras de negócio, validação e documentação | Django + DRF + Swagger (drf-spectacular) |

O Django não tem banco relacional: tudo passa por `core.store`, que conversa
com o Firestore real ou com um Firestore simulado em memória (modo mock).

## Rodando localmente

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate            # Linux/macOS: source .venv/bin/activate
pip install -r requirements-dev.txt
copy .env.example .env            # Linux/macOS: cp .env.example .env
python manage.py runserver 0.0.0.0:8000
```

* Swagger: http://localhost:8000/api/docs/ (ReDoc em `/api/redoc/`, OpenAPI em `/api/schema/`)
* No emulador Android, o backend fica em `http://10.0.2.2:8000`.

### Testando no Swagger

1. `POST /api/v1/auth/anonymous` (ou `/register` / `/login`).
2. Copie o `id_token` da resposta, clique em **Authorize** e cole.
3. Chame qualquer endpoint autenticado.

Todo erro tem o formato `{"error": {"code", "message", "details"}}`. O app deve
decidir pelo `code` e pode exibir a `message` direto ao usuário.

## Endpoints

| Recurso | Rotas | Tela do Figma |
| --- | --- | --- |
| Autenticação | `/auth/anonymous`, `/register`, `/login`, `/refresh`, `/link`, `/me` (GET e DELETE), `/verify-email`, `/password-reset` | Introdução, Login, Cadastro, Recuperar senha |
| Perfil | `GET/PATCH /profile` | Perfil, Meus dados, Meu objetivo, Notificações |
| Catálogo | `GET /products`, `GET /products/{id}` | Adicionar à rotina |
| Rotina (stack) | CRUD `/routine-items` | Seus itens, Stack de hoje, Protocolo |
| Doses | CRUD `/doses` | Registrar dose, Registros, Editar stack do dia |
| Sintomas | CRUD `/symptoms` | Como se sente hoje?, Registros |
| Hidratação | CRUD `/hydration` | Hidratação |
| Artigos | `GET /articles`, `GET /articles/{id}` | Conteúdos educativos |

Todas as rotas ficam em `/api/v1/` e, exceto as públicas de autenticação e o
`/health`, exigem `Authorization: Bearer <id_token>`.

* **Ids gerados pelo app:** em todo `POST` de CRUD o `id` é opcional. O app pode
  mandar o UUID criado offline, e reenviar o mesmo id retorna `409`, sem
  duplicar.
* **Registrar dose em 3 toques:** `POST /doses` só com `routine_item_id`. Nome,
  dose, unidade e protocolo vêm do item da rotina.
* **Calendário:** as listas de doses, sintomas e água aceitam `date_from` e
  `date_to` (AAAA-MM-DD, fuso de Brasília) e devolvem `local_date` em cada
  registro.
* **Faixas de dose:** cada produto traz `dose_ranges` por protocolo, com as
  fontes. O app usa isso para o alerta "acima da faixa normalmente utilizada".

## Modelagem do Firestore

```
users/{uid}                      perfil e dados da conta
  diagnostics/{id}               documento de teste da configuração
  routine_items/{id}             itens do stack
  dose_logs/{id}                 doses registradas
  symptom_logs/{id}              "Como você se sentiu"
  hydration_logs/{id}            água ingerida
products/{id}                    catálogo (suplementos e anabolizantes)
articles/{id}                    artigos educativos
```

| Coleção | Campos | Cifrados (AES-256-GCM) |
| --- | --- | --- |
| `users/{uid}` | email, is_anonymous, name, age, weight_kg, height_cm, biological_sex, goal, notifications{dose_reminders, symptom_reminder}, terms_accepted_at, created_at, updated_at | age, weight_kg, height_cm, biological_sex |
| `routine_items` | product_id, name, brand, kind, protocol, dose_amount, dose_unit, schedule_times[], start_date, end_date, active, notes, created_at, updated_at | notes |
| `dose_logs` | routine_item_id, product_id, name, kind, protocol, amount, unit, taken_at, local_date, notes, created_at, updated_at | amount, notes |
| `symptom_logs` | status, symptoms[], other_description, notes, logged_at, local_date, created_at, updated_at | symptoms, other_description, notes |
| `hydration_logs` | amount_ml, logged_at, local_date, created_at, updated_at | (nenhum) |
| `products` | name, kind, default_unit, default_dose, dose_ranges[{protocol, per, min, max, unit, note, sources[]}], caution, requires_medical_supervision, sources[] | (público) |
| `articles` | title, summary, body (Markdown), tags[], reading_minutes, published_at, sources[] | (público) |

Os campos cifrados guardam `enc:v1:<base64>`. A chave vem de
`FIELD_ENCRYPTION_KEY`, e o caminho do documento + o nome do campo entram como
dado associado, então um valor cifrado copiado para outro lugar não decifra.
Datas puras ficam como texto `AAAA-MM-DD` e horários como `HH:MM`.

O catálogo e os artigos vêm de `catalog/content.py`. No modo mock eles são
carregados sozinhos; no Firestore real, rode `python manage.py seed_content`
(use `--overwrite` para atualizar o que já existe).

## Modos do Firebase (`FIREBASE_MODE`)

**`mock` (padrão):** não precisa de credenciais. Contas e documentos ficam em
memória (ou em `MOCK_STORE_PATH`, para sobreviver a reinícios). Os "e-mails"
de confirmação e de recuperação de senha não são enviados: o `oob_code` aparece
no console do `runserver`, e você o usa em `/auth/verify-email/confirm` ou em
`/auth/password-reset/confirm`.

**`firebase`:** usa o projeto real. Passo a passo para ativar:

1. Crie o projeto no [console do Firebase](https://console.firebase.google.com/).
2. Em **Authentication > Método de login**, ative **Anônimo** e **E-mail/senha**.
3. Crie o **Cloud Firestore** (modo produção, região `southamerica-east1`).
4. Em **Configurações do projeto > Contas de serviço**, gere uma chave privada
   (JSON) e salve em `backend/secrets/` (pasta ignorada pelo git).
5. No `.env`: `FIREBASE_MODE=firebase`, `FIREBASE_PROJECT_ID`,
   `FIREBASE_WEB_API_KEY` (Configurações > Geral), `FIREBASE_CREDENTIALS`
   (caminho do JSON) e uma `FIELD_ENCRYPTION_KEY` nova (guarde-a bem: sem ela
   os dados cifrados não abrem).
6. Publique as regras e os índices: na pasta `firebase/`, troque o projeto em
   `.firebaserc` e rode `firebase deploy --only firestore`.
7. Carregue o catálogo e os artigos: `python manage.py seed_content`.

Para usar os **emuladores** do Firebase em vez do projeto real, rode
`firebase emulators:start` na pasta `firebase/` e defina
`FIRESTORE_EMULATOR_HOST=localhost:8080` e
`FIREBASE_AUTH_EMULATOR_HOST=localhost:9099` no `.env`.

## Regras de segurança (`firebase/firestore.rules`)

O backend usa o Admin SDK, que ignora as regras. Elas protegem contra acesso
direto ao Firestore: cada usuário só lê a própria árvore `users/{uid}`, nenhum
cliente escreve direto e qualquer caminho não listado é negado.

## Testes

```bash
cd backend
pytest
```

Os testes rodam sempre no modo mock, sem rede.

## Estrutura

```
backend/
  config/      settings e rotas
  core/        infraestrutura: store (Firestore/mock), auth (Firebase/mock),
               criptografia de campos, base dos CRUDs, formato de erro, health
  accounts/    endpoints de autenticação e exclusão de conta
  profiles/    perfil do usuário
  catalog/     catálogo de produtos e artigos (conteúdo em content.py)
  tracking/    rotina, doses, sintomas e hidratação
  tests/
firebase/      firebase.json, .firebaserc, firestore.rules, índices
```
