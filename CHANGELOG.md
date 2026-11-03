# CHANGELOG — Dosis

## [0.1] — 08/09/2026

# Pesquisa

* Definido o foco do aplicativo em promover um uso mais consciente de suplementos.
* A pesquisa mostrou que diferentes suplementos podem possuir diferentes formas e protocolos de utilização.
* Definido que o aplicativo não deve analisar uma suplementação apenas pela quantidade utilizada, pois o contexto também deve ser considerado.
* Escolhidas como fontes principais: ANVISA e literatura científica sobre suplementação.

# Benchmark

* Analisados os aplicativos Cronometer, MyFitnessPal e Strong.
* Identificado que aplicativos existentes possuem recursos de registro e acompanhamento, mas não têm como foco principal a conscientização e a segurança no uso de suplementos.
* Decidido aproveitar a simplicidade do registro apresentada pelo Strong e aplicá-la ao controle de suplementos.

# Personas

* Criadas duas personas para representar os principais perfis de usuários.
* Definido Rafael, 24 anos, como persona prioritária por utilizar suplementos com frequência e possuir maior relação com as principais funcionalidades do aplicativo.

# Decisões do projeto

* O Dosis não deve impedir o cadastro de um suplemento apenas por ele apresentar possíveis riscos.
* As informações de risco devem ser apresentadas de forma clara, sem alarmismo.
* O aplicativo deve priorizar informações confiáveis e baseadas em fontes científicas e órgãos oficiais.
* O fluxo principal foi definido como: **Registrar → Entender → Acompanhar → Receber alertas**.




## [0.2] — 14/09/2026

### Pasta **requisitos.md** adicionado
Em **requisitos.md** foi adicionado:
* Definição do **Objetivo** do aplicativo Dosis.
* Definição das **Funcionalidades**.
* Definição dos **Requisitos Funcionais**.
* Definição dos **Requisitos Não Funcionais**.
* Organização da documentação com base nas necessidades identificadas no estudo de caso e nas personas do projeto.

## [0.3] — 04/10/2026
### Pasta **justificativa.md, prototipoBaixaFidelidade.pdf e prototipoAltaFidelidade.pdf** adicionado.
* Em justificativa.md é apresentado as justificativas das principais decisões de interface e arquitetura.
* Em prototipoBaixaFidelidade.pdf há um pdf com o protótipo de baixa fidelidade.
* Em prototipoAltaFidelidade.pdf há um pdf com o protótipo de alta fidelidade.


## [0.4] — 02/11/2026
### Base do aplicativo Flutter (Unidade II)

* Arquitetura em camadas **Presentation / Domain / Data** (KAN-4), documentada em `docs/arquitetura.md`:
  interfaces de repositório, casos de uso (`RegisterDose`, `GetTodayStack`, `GetDoseHistory`) e raiz de composição (`AppDependencies`).
* Gerenciamento de estado com **Riverpod** (KAN-8): `ProviderScope`, providers dos casos de uso e da aba selecionada.
* Repositórios falsos em memória: o app roda sem backend por padrão. Com `--dart-define=USE_API=true` usa a API Django.
* Tema escuro de alto contraste, barra do topo e menu de baixo com 4 abas, seguindo o protótipo de alta fidelidade (KAN-5).
* Telas navegáveis: Início, Registrar dose, Rotina, Hidratação, Registros, Como se sente hoje? e Conteúdos educativos.
* Teste unitário dos casos de uso (`app/test/domain/usecases_test.dart`).
* Adicionado `docs/uso-de-ia.md` com o registro do uso de IA.

### Limitações conhecidas
* Sem login: a API real ainda não pode ser usada pelo app.
* Sintomas, catálogo e remoção de item da rotina ainda não gravam dados.
* Aviso de dose alta ainda usa regra provisória (KAN-11 pendente).

## [0.5] — 03/11/2026
### Calculadora de Hidratação com Suporte a Creatina (KAN-10)

* Implementado o caso de uso `CalculateHydration` na camada **Domain** (`app/lib/domain/usecases/calculate_hydration.dart`), substituindo a regra provisória anterior:
  * Meta hídrica basal de **35 ml/kg** para praticantes de atividade física.
  * Ajuste de hidratação preventivo com base científica (ACSM/SBEM) proporcional ao consumo de creatina ativa no stack (**100 ml por grama**, mínimo de **500 ml** adicionais) para suporte à retenção intracelular e segurança renal.
* Refatoração da tela de Hidratação (`app/lib/presentation/pages/hydration_page.dart`):
  * Integração com Riverpod via `calculateHydrationProvider`.
  * Exibição estruturada com meta em destaque (litros e ml/dia), detalhes da recomendação e aviso preventivo visual.
  * Validação de entrada de peso com mensagem informativa em card de alerta.
* Testes unitários do caso de uso em `app/test/domain/calculate_hydration_test.dart` cobrindo cenários com e sem creatina, protocolos de saturação e validação de peso.

