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

## [0.6] — 05/11/2026
### Alerta Preventivo de Dose de Creatina e Rins (KAN-11)

* Implementado o caso de uso `CheckDoseSafety` na camada **Domain** (`app/lib/domain/usecases/check_dose_safety.dart`):
  * Avaliação por protocolo com base em evidências científicas oficiais (**ISSN 2017 / ANVISA**):
    * **Uso contínuo:** Faixa usual de 3 a 5 g/dia. Doses superiores ativam o alerta de atenção.
    * **Protocolo de saturação:** Faixa usual de 15 a 25 g/dia por período delimitado (5 a 7 dias). Doses superiores a 25g/dia ativam o alerta.
  * Informações de cuidado fisiológico explicando que doses excessivas geram sobrecarga sem ganho de eficácia e alertando sobre a elevação esperada da creatinina sérica em exames laboratoriais.
* Refatoração do fluxo de registro de dose (`app/lib/presentation/pages/register_dose_page.dart`):
  * Integração com Riverpod via `checkDoseSafetyProvider`.
  * Card de diálogo laranja estilizado de alta fidelidade com citação explícita das fontes oficiais (`Fonte: ISSN / ANVISA`).
  * Autonomia do usuário preservada através dos botões **"Revisar Protocolo"** e **"Manter Configuração"**.
* Testes unitários em `app/test/domain/check_dose_safety_test.dart` cobrindo cenários de dose normal, dose excessiva contínua, saturação e conversão de unidades (mg para g).

* 
## [0.7] — 08/11/2026
### Login, cadastro e recuperação de senha

* Telas de autenticação seguindo o protótipo de alta fidelidade: boas-vindas, **Entrar**, **Criar conta** (3 passos: nome, e-mail e senha com aceite dos termos), **Confirme seu e-mail** e **Recuperar senha** (com a tela "Verifique seu e-mail").
* Interface `AuthRepository` na camada **Domain** e implementações `ApiAuthRepository` (usa os endpoints `/auth/*` do backend Django, com Firebase Auth) e `FakeAuthRepository` (dados em memória).
* Regras de senha e de e-mail em `app/lib/domain/auth_rules.dart`, iguais às do backend (8+ caracteres, uma letra e um número).
* Sessão gerenciada com Riverpod (`sessionProvider`) e `AuthGate`: sem sessão o app abre na introdução; com sessão, abre o app.
* Tela de Perfil com a opção **Sair**, acessada pelo ícone do topo.
* Teste unitário das regras em `app/test/domain/auth_rules_test.dart`.

### Limitações conhecidas
* O e-mail de confirmação só é enviado de verdade com o backend em modo `firebase`. No modo `mock` o link aparece no console do servidor.
* A tela "Nova senha" depende de deep link e ainda não foi implementada.
* Os itens Meus dados, Meu objetivo e Notificações do Perfil ainda não têm tela.


## [0.8] — 12/11/2026
### Correções nos alertas de dose, sintomas e hidratação

* **Alerta de dose usa o catálogo** (`CheckDoseSafety`): as faixas deixam de ser fixas no código e passam a vir do catálogo (`backend/apps/catalog/content.py`), pela nova interface `CatalogRepository` (`ApiCatalogRepository` e `FakeCatalogRepository`).
  * Whey Protein e Ômega 3 passam a ter alerta, não só a creatina.
  * **Faixas por dia somam as doses do dia:** 5 g de creatina de manhã + 5 g à noite agora gera alerta (10 g, acima de 3 a 5 g/dia). Faixas por tomada (whey, 20 a 40 g) comparam só a dose informada.
  * Conversão entre g, mg e mcg; unidades que não se convertem (ex.: cápsulas) não geram alerta.
* **Aviso de anabolizantes:** registrar uma dose de anabolizante sempre mostra o aviso de acompanhamento médico, com as fontes CFM / ANVISA / SBEM. O aviso orienta e não bloqueia o registro.
* **Sintomas agora são gravados** (`RegisterSymptoms`, `SymptomRepository`): antes a tela mostrava "Registro salvo com sucesso" sem salvar nada. Agora a confirmação só aparece depois da gravação, e a tela valida as mesmas regras do backend (marcar "Normal" ou ao menos um sintoma; "Outro" exige descrição).
* **Hidratação:** o texto deixa de atribuir a regra de 35 ml/kg e o acréscimo por creatina à SBEM/ACSM, que não fazem essa recomendação. A estimativa agora é apresentada como regra prática do app, com a orientação do ACSM de repor o suor em treinos intensos ou calor.
* Testes unitários novos para `CheckDoseSafety` e `RegisterSymptoms`, e teste da hidratação atualizado.

### Limitações conhecidas
* Ainda não existe a tela de linha do tempo dos sintomas (F08); os registros já ficam gravados.
* Sem conexão com o catálogo, a dose é registrada sem o alerta.
* O `FakeCatalogRepository` é uma cópia do `content.py`: ao mudar uma faixa no backend, atualize também o app.

## [0.9] — 12/11/2026
### Histórico por suplemento e gráficos de evolução das doses

* Nova tela **Histórico** (aba Registros > "Histórico por suplemento"): escolha do suplemento e do período (7, 30 ou 90 dias), gráfico de barras com a soma de cada dia, resumo (total, média por dia de uso, dias com registro) e a lista paginada de todos os registros.
* Caso de uso `GetSupplementHistory` na camada **Domain**: agrupa as doses por produto, soma por dia e converte g/mg/mcg para uma unidade só.
* Para produtos com faixa diária no catálogo (ex.: creatina), o gráfico mostra a linha do limite usual e pinta de laranja os dias acima dele. Anabolizantes mostram o aviso de acompanhamento médico em vez de uma faixa.
* Gráfico desenhado no próprio app (`DosisBarChart`, com `CustomPainter`), sem biblioteca de gráficos, para não aumentar o APK (RNF09).

### Metas de hidratação diária e lembretes (água e suplementos)

* Aba **Hidratação** ganhou a seção "Meta de hoje": meta diária editável, barra de progresso, botões de registro rápido (+200, +300, +500 ml e "Outro"), registros do dia (com opção de apagar) e gráfico dos últimos 7 dias com a linha da meta.
* A estimativa da calculadora pode virar a meta com o botão "Usar X L como minha meta".
* Nova tela **Lembretes** (pela aba Hidratação ou em Perfil > Notificações): lembretes de água a cada 1 a 4 horas entre dois horários, e lembretes de suplementos nos horários dos itens ativos da rotina. A tela mostra antes de salvar o que será agendado.
* Notificações locais com `flutter_local_notifications` (funcionam sem internet e são recriadas quando o aparelho reinicia). O domínio só conhece a interface `ReminderScheduler`.
* Casos de uso `GetHydrationProgress`, `LogWater`, `RemoveWaterLog` e `UpdateSettings`; interfaces `HydrationRepository` e `SettingsRepository`. A água registrada usa o endpoint `/tracking/hydration/`; a meta e os lembretes ficam guardados no aparelho.
* Android: permissões `POST_NOTIFICATIONS` e `RECEIVE_BOOT_COMPLETED`, receivers do plugin, *desugaring* e `compileSdk = 37` (exigências do plugin).

### Painel de indicadores de risco e relatório semanal de sintomas

* Nova tela **Painel de risco** (Início > "Painel de risco"): analisa os últimos 7 dias e mostra um indicador por suplemento (dentro da faixa, acima da faixa em N dias, sem faixa de referência ou "requer acompanhamento médico" para anabolizantes) e um indicador dos sintomas registrados. Os alertas citam a fonte do catálogo.
* Caso de uso `BuildRiskPanel`: faixas por dia somam as doses do dia; faixas por tomada comparam cada dose. Palpitação, ou sintomas em 3 ou mais dias da semana, pedem atenção; com anabolizante em uso, o painel orienta levar os registros ao médico.
* Nova tela **Relatório semanal** de sintomas: os 7 dias da semana (segunda a domingo), dias com registro e com sintomas, frequência de cada sintoma comparada com a semana anterior, registros com observações e navegação entre semanas. Caso de uso `BuildWeeklySymptomReport`.
* A aba **Registros** agora mostra os sintomas de cada dia (antes exibia sempre "Nenhum sintoma").
* O painel informa que não é diagnóstico e não substitui a orientação de um profissional de saúde.

### Testes
* 35 testes unitários novos (histórico, meta de hidratação, lembretes, painel de risco e relatório semanal). Total: 77.

### Limitações conhecidas
* Os lembretes só são agendados no celular (Android/iOS). No computador a tela funciona, mas nada é agendado.
* O agendamento é "inexato": o Android pode atrasar o lembrete em alguns minutos para economizar bateria.
* Os lembretes de suplementos são montados ao salvar. Se a rotina mudar, é preciso salvar os lembretes de novo.
* A meta e os lembretes ficam no aparelho: não acompanham a conta em outro celular.
* O histórico e os relatórios leem até 500 registros por consulta (limite da API).
