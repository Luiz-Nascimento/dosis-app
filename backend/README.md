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
   `FIREBASE_WEB_API_KEY` (Configurações > Geral) e `FIREBASE_CREDENTIALS`
   (caminho do JSON).
6. Publique as regras e os índices: na pasta `firebase/`, troque o projeto em
   `.firebaserc` e rode `firebase deploy --only firestore`.

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
               autenticação do DRF, formato de erro, health
  accounts/    endpoints de autenticação
  tests/
firebase/      firebase.json, .firebaserc, firestore.rules, índices
```
