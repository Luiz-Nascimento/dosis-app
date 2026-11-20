# Dosis

Projeto da disciplina **Programação para Dispositivos Móveis** (UNIT).

O Dosis é um aplicativo educacional e de rastreamento para o uso consciente de suplementos alimentares. Ele é voltado a jovens de 18 a 40 anos que frequentam academia.

## Integrantes

- Luiz Augusto Nascimento Ferreira
- Carlos Audre Santos
- Jimy Kauã dos Santos Silva
- Victor Ferreira
- Antônio Fernandes de Santana Neto

## Problema e solução

**Problema:** muitas pessoas usam suplementos e anabolizantes por conta própria, sem controlar as doses e sem informação confiável. O consumo excessivo, as doses inadequadas e as combinações sem orientação podem afetar o fígado, os rins, o sistema cardiovascular e o equilíbrio hormonal.

**Para quem:** atletas amadores que já têm uma rotina de suplementação e iniciantes curiosos. A persona prioritária é o **Rafael Martins**, de 24 anos. Ele treina cinco vezes por semana, usa creatina e whey todos os dias e organiza as doses de cabeça.

**Solução:** um app para registrar a rotina e as doses do dia em poucos toques. Ele avisa quando uma dose passa da faixa normalmente usada, sempre citando a fonte (ANVISA e literatura científica), e oferece conteúdos educativos. O app não proíbe nem julga o uso e não substitui a orientação de um profissional de saúde.

Fluxo principal: **Registrar → Entender → Acompanhar → Receber alertas**.

## Principais funcionalidades

| Funcionalidade | Onde está no app |
| --- | --- |
| Cadastro de suplementos e anabolizantes na rotina, a partir do catálogo | Rotina |
| Registro de doses e stack do dia | Início, Registrar dose |
| Alertas de dose acima da faixa, com fonte, e aviso de acompanhamento médico para anabolizantes | Registrar dose, Painel de risco |
| Calculadora de hidratação, meta diária de água e lembretes | Hidratação, Lembretes |
| Registro de sintomas e relatório semanal | Como se sente hoje?, Relatório semanal |
| Histórico por suplemento com gráficos | Registros, Histórico |
| Artigos educativos com fontes, disponíveis offline | Conteúdos educativos |
| Recomendações e notificações educativas | Início, Recomendações |
| Login, cadastro e recuperação de senha | Boas-vindas, Entrar, Criar conta |

Os requisitos completos (funcionais, não funcionais e priorização) estão em [`docs/requisitos.md`](docs/requisitos.md).

## Arquitetura

| Parte | Tecnologia | Pasta |
| --- | --- | --- |
| Aplicativo Android | Flutter/Dart, com arquitetura em camadas **Presentation / Domain / Data** e estado com Riverpod | [`app/`](app/) |
| API | Django + Django REST Framework, com documentação Swagger | [`backend/`](backend/) |
| Autenticação e banco de dados | Firebase Auth e Cloud Firestore | [`backend/firebase/`](backend/firebase/) |

A arquitetura do app está explicada em [`docs/arquitetura.md`](docs/arquitetura.md), e a do backend em [`backend/README.md`](backend/README.md).

## Como executar

O app usa por padrão a API publicada em `https://api-dosis.duckdns.org`:

```bash
cd app
flutter pub get
flutter run                               # usa a API publicada
flutter run --dart-define=USE_API=false   # usa dados falsos em memória, sem backend
```

Para testar com o backend rodando no computador:

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env              # Windows: copy .env.example .env
python manage.py runserver 0.0.0.0:8000

# App (em outro terminal; no emulador Android, 10.0.2.2 é o computador)
cd app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Testes: `python -m pytest` em `backend/` e `flutter test` em `app/`.

### Gerar o APK

O APK de entrega é o de release, um por arquitetura (RNF09: no máximo 20 MB):

```bash
cd app
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk     (~9 MB, celulares atuais)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk   (~8,6 MB, celulares 32 bits)
```

O APK de debug (`flutter run`) passa de 140 MB e não serve para medir o tamanho. O APK universal (`flutter build apk --release`, sem `--split-per-abi`) tem cerca de 25 MB porque leva as três arquiteturas.

## Documentação

| Documento | Arquivo |
| --- | --- |
| Estudo de caso | [`docs/estudo-de-caso.md`](docs/estudo-de-caso.md) |
| Pesquisa | [`docs/pesquisa.md`](docs/pesquisa.md) |
| Benchmark | [`docs/benchmark.md`](docs/benchmark.md) |
| Personas | [`docs/personas.md`](docs/personas.md) |
| Requisitos | [`docs/requisitos.md`](docs/requisitos.md) |
| Justificativas | [`docs/justificativas.md`](docs/justificativas.md) |
| Apresentação — Atividade 02 (pesquisa, benchmark e personas) | [`docs/apresentacao.pdf`](docs/apresentacao.pdf) |
| Apresentação — Atividade 03 (funcionalidades e requisitos) | [`docs/apresentacaorequisitos.pdf`](docs/apresentacaorequisitos.pdf) |
| Protótipo de baixa fidelidade | [`docs/prototipoBaixaFidelidade.pdf`](docs/prototipoBaixaFidelidade.pdf) |
| Protótipo de alta fidelidade | [`docs/prototipoAltaFidelidade (1).pdf`](<docs/prototipoAltaFidelidade (1).pdf>) |
| Apresentação final — Unidade I | [`docs/apresentacaoFinalUnidadeI.pdf`](docs/apresentacaoFinalUnidadeI.pdf) |
| Arquitetura do app | [`docs/arquitetura.md`](docs/arquitetura.md) |
| Diagrama de casos de uso | [`docs/diagrama-casos-de-uso.md`](docs/diagrama-casos-de-uso.md) |
| Diagrama de classes | [`docs/diagrama-de-classes.md`](docs/diagrama-de-classes.md) |
| Modelagem do banco | [`docs/modelagem-banco.md`](docs/modelagem-banco.md) |
| Uso de IA | [`docs/uso-de-ia.md`](docs/uso-de-ia.md) |
| Histórico de versões | [`CHANGELOG.md`](CHANGELOG.md) |

## Responsabilidades

### Estudo de caso
- Luiz Augusto Nascimento Ferreira: estrutura do estudo de caso e descrição dos públicos (atleta amador e curiosos); README e CHANGELOG iniciais
- Jimy Kauã dos Santos Silva: ampliação do estudo de caso com novas funcionalidades
- Victor Ferreira: atualização do estudo de caso

### Atividade 02 — Pesquisa, benchmark e personas
- Carlos Audre Santos: pesquisa (tópico 2)
- Antônio Fernandes de Santana Neto: pesquisa para o benchmark (tópico 3)
- Jimy Kauã dos Santos Silva: pesquisa (tópico 6) e personas
- Luiz Augusto Nascimento Ferreira: detalhamento do benchmark

### Atividade 03 — Funcionalidades e requisitos
- Carlos Audre Santos: objetivo, funcionalidades, requisitos funcionais e requisitos não funcionais
- Jimy Kauã dos Santos Silva: pesquisa e slides (tópico 5)
- Victor Ferreira: atualização dos requisitos

### Justificativas e protótipos
- Carlos Audre Santos: justificativas do protótipo, protótipo de baixa fidelidade e protótipo de alta fidelidade
- Jimy Kauã dos Santos Silva: protótipo de baixa fidelidade

### Apresentação final — Unidade I
- Luiz Augusto Nascimento Ferreira: slides da apresentação final

### Aplicativo e backend — Unidade II
- Antônio Fernandes de Santana Neto: backend Django com Firebase (KAN-6), modelos e CRUDs no Firestore (KAN-7), fila de sincronização offline (KAN-14 a KAN-17), backup criptografado (KAN-23) e projeto Flutter inicial com os services da API
- Carlos Audre Santos: arquitetura em camadas (KAN-4), gerenciamento de estado com Riverpod (KAN-8), tema e navegação (KAN-5), login, cadastro e recuperação de senha, diagramas (casos de uso, classes e modelagem do banco) e documentação do uso de IA
- Jimy Kauã dos Santos Silva: tela de artigos educativos sobre anabolizantes e temas relacionados (KAN-32), motor de recomendações simples e notificações educativas (KAN-32)
- Luiz Augusto Nascimento Ferreira: calculadora de hidratação (KAN-10), alerta preventivo de dose (KAN-11), correções dos alertas de dose e do registro de sintomas, histórico com gráficos, metas e lembretes de hidratação, painel de risco e relatório semanal, "Adicionar à rotina" ligado ao catálogo e novos itens do catálogo

## Uso de IA

O registro de como a IA foi usada no projeto está em [`docs/uso-de-ia.md`](docs/uso-de-ia.md).
