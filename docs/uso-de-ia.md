# Uso de IA no projeto
Este documento registra como ferramentas de IA foram usadas no Dosis, conforme exigido pela disciplina
de Programação para Dispositivos Móveis (UNIT).

Esta documentação detalha a contribuição da IA no projeto. Ela foi responsável por estruturar a base do sistema em Flutter
e participou ativamente do desenvolvimento de todo o código, embora não tenha realizado commits ou pushes diretamente no repositório.

## 📅 Histórico de Contribuições (01/11 e 02/11)
### Arquitetura em Camadas

* **Design e Estrutura:** Suporte no desenho técnico e estruturação da arquitetura dividida em Presentation, Domain e Data, ajudando a mapear as responsabilidades de cada camada.
* **Componentes Core:** Auxílio na escrita e refinamento de interfaces de repositório, casos de uso principais (RegisterDose, GetTodayStack) e na organização da raiz de composição (AppDependencies).
* **Validação e Resolução de Erros:** Assistência no mapeamento físico de diretórios e na correção ágil de erros de importação (como no DoseRepository) durante o processo de execução e validação da integridade.

### Gerenciamento de Estado

* **Integração com Riverpod:** Suporte na estruturação e configuração da biblioteca Riverpod, auxiliando na sintaxe do ProviderScope, centralização no providers.dart e na conversão de telas para ConsumerWidget.
* **Mocking de Dados:** Geração assistida de repositórios mockados com base nos contratos definidos, otimizando o tempo de criação de dados falsos para testes de interface e comportamento.
* **Validação de Fluxo:** Auxílio na análise de logs e depuração do fluxo de dados em tempo de execução para garantir a estabilidade do estado.

### Resumo do Papel da IA no Processo
A inteligência artificial foi utilizada ativamente como uma ferramenta de **Pair Programming** e aceleração de desenvolvimento. O processo envolveu a tomada de decisão humana na governança do projeto,
validação de regras de negócio e testes em runtime, enquanto a IA otimizou o tempo de escrita de código estrutural (*boilerplate*), sugeriu correções rápidas de compilação e auxiliou na formatação da documentação técnica.

## 📅 Histórico de Contribuições (08/11)
### Login, Cadastro e Recuperação de Senha

* **Análise do backend e do protótipo:** Leitura do `AuthService`, dos endpoints `/auth/*` e das regras de senha do backend, e dos frames de login, cadastro, confirmação de e-mail e recuperação de senha do protótipo de alta fidelidade.
* **Arquitetura:** Sugestão da interface `AuthRepository`, das implementações `ApiAuthRepository` e `FakeAuthRepository` e da integração com o `AppDependencies`, mantendo a regra de dependência entre as camadas.
* **Interface e estado:** Escrita assistida das telas (Boas-vindas, Entrar, Criar conta em 3 passos, Confirme seu e-mail, Recuperar senha e Perfil), dos widgets compartilhados e do `AuthGate` com Riverpod.
* **Regras e testes:** Escrita das regras de senha e e-mail e do teste unitário correspondente.
* **Orientação sobre o backend:** Explicação dos modos `mock` e `firebase`, do passo a passo para ativar o Firebase real e de como confirmar o e-mail manualmente no modo `mock`.
* **Limitações da IA:** O código gerado foi validado pelo aluno (compilação e execução). A IA não rodou o backend em modo `firebase`, e a tela "Nova senha" (deep link) ficou fora do escopo.



## 📅 Histórico de Contribuições (12/11)
### Revisão do código e correção de bugs

* **Análise do repositório:** Leitura do app, do backend e da documentação para levantar os bugs e as funcionalidades incompletas em relação aos requisitos.
* **Alertas de dose:** Escrita assistida da nova versão do `CheckDoseSafety` (faixas vindas do catálogo, soma das doses do dia e aviso de anabolizantes), do `CatalogRepository` e das suas implementações, com testes unitários.
* **Sintomas:** Escrita assistida do `SymptomRepository`, do caso de uso `RegisterSymptoms` e da gravação na tela "Como se sente hoje?", com testes unitários.
* **Hidratação:** Identificação de que a regra de hidratação era atribuída à SBEM/ACSM sem que essas fontes a recomendem, e correção do texto exibido.
* **Validação humana:** As mudanças foram revisadas e testadas no app pelo aluno antes de cada commit. Os valores do cálculo de hidratação foram mantidos como decisão da equipe.

### Novas funcionalidades (12/11)

* **Histórico por suplemento e gráficos:** Escrita assistida do caso de uso `GetSupplementHistory`, da tela de histórico e do componente de gráfico `DosisBarChart`, com testes unitários.
* **Metas de hidratação e lembretes:** Escrita assistida dos casos de uso de meta e registro de água, da tela de lembretes, da integração com `flutter_local_notifications` e da configuração do Android (permissões, receivers e Gradle), com testes unitários.
* **Painel de risco e relatório semanal de sintomas:** Escrita assistida dos casos de uso `BuildRiskPanel` e `BuildWeeklySymptomReport` e das duas telas, com testes unitários.
* **Verificação feita pela IA:** execução dos testes e do analisador, compilação do APK de depuração e conferência visual das telas renderizadas em imagem.
* **Limitações da IA:** a IA não executou o app em um celular. O disparo real das notificações no aparelho precisa ser validado pelo aluno.


## 📅 Histórico de Contribuições (19/11)
### Catálogo: novos suplementos e anabolizantes

* **Conteúdo do catálogo:** Os novos suplementos, anabolizantes e fontes, e a mudança no teste, foram escritos pelo aluno. A IA não escreveu nem revisou as doses, os textos de cuidado ou as fontes citadas.
* **Versionamento:** A IA conferiu se havia outras alterações locais, levou as alterações para uma branch nova criada a partir da `main`, fez os commits só dos arquivos combinados, enviou a branch e abriu o pull request.
* **Verificação feita pela IA:** Execução dos testes do catálogo no backend (`python -m pytest tests/unit/apps/catalog`, 7 testes passando).
* **Documentação:** Escrita assistida da versão 0.11 do CHANGELOG e deste registro.
* **Limitações da IA:** A IA não conferiu se as doses e os limites batem com as fontes, nem se os links ainda funcionam. Isso precisa ser validado pelo aluno.

## 📅 Histórico de Contribuições (19/11 — README)
### Reorganização do README para a entrega final

* **Leitura dos requisitos:** A IA leu o enunciado da Atividade 05 e os documentos do repositório para montar o README com as seções pedidas.
* **Responsabilidades:** As responsabilidades vieram do README anterior e do histórico de commits do GitHub. A IA não inventou nenhuma contribuição. A lista precisa ser revisada pela equipe antes do merge.
* **Descrição do repositório:** Sugestão e atualização da descrição e dos tópicos do repositório no GitHub.
* **Limitações da IA:** A IA não sabe o que cada integrante fez fora do GitHub (pesquisa, reuniões, slides). Isso precisa ser completado pela equipe.

## 📅 Histórico de Contribuições (19/11 — revisão e dose duplicada)
### Revisão completa do projeto e correção do registro de dose duplicado

* **Revisão do código:** A IA leu o app e o backend da `main`, rodou o analisador e os testes (app e backend em modo `mock`) e conferiu a API publicada na VPS apenas com leituras (status e documentação), sem criar contas nem dados em produção. O resultado foi uma lista de bugs e de código sem uso, priorizada para corrigir um item por vez.
* **Correção do registro duplicado:** Escrita assistida do bloqueio do botão "Registrar", do id de tentativa mantido entre reenvios, do tratamento do 409 no `ApiDoseRepository` e do mesmo comportamento no repositório fake, com testes unitários.
* **Versionamento:** A IA criou a branch a partir da `main` atualizada, fez o commit só dos arquivos da correção (deixando de fora as alterações locais do aluno em `app/.metadata`, `app/analysis_options.yaml` e `app/linux/`), enviou a branch e abriu o pull request.
* **Validação humana:** O aluno testou a correção no emulador antes do commit.
* **Limitações da IA:** O caso em que a dose chega ao servidor e a resposta se perde não foi reproduzido manualmente, só nos testes unitários. Os outros bugs apontados na revisão ficaram para os próximos pull requests.

## 📅 Histórico de Contribuições (19/11 — dados entre contas)
### Correção dos dados de uma conta aparecendo na próxima

* **Análise:** A IA identificou, na revisão do projeto, que os providers de dados do usuário não dependiam da sessão e que os lembretes e as preferências ficavam no aparelho depois do logout.
* **Correção:** Escrita assistida do caso de uso `SignOut`, do `clear()` no `SettingsRepository` e da ligação dos providers de dados do usuário com a sessão, com testes unitários.
* **Verificação feita pela IA:** Execução do analisador e dos testes, e confirmação de que os testes novos falham com o código anterior e passam com a correção.
* **Decisão humana:** O aluno aprovou que sair da conta volte as preferências ao padrão e testou a correção no emulador antes do commit.
* **Versionamento:** A IA criou a branch a partir da `main` atualizada, fez o commit só dos arquivos da correção (deixando de fora as alterações locais do aluno), enviou a branch e abriu o pull request.
* **Limitações da IA:** A IA não conferiu no aparelho se um lembrete agendado deixa de disparar depois do logout; isso foi coberto só pelo teste unitário do `SignOut`.

## 📅 Histórico de Contribuições (19/11 — APK de entrega)
### API publicada por padrão e redução do tamanho do APK

* **Análise:** A pedido do aluno, a IA gerou os APKs de debug e de release e comparou o tamanho de cada um com o limite de 20 MB do RNF09. Ela explicou que o APK de debug não serve para essa medição e, listando os arquivos de dentro do APK de release, identificou que as bibliotecas nativas do Flutter, sem compressão e repetidas para três arquiteturas, ocupavam quase todo o espaço.
* **Alterações:** Escrita assistida da troca da URL e do `USE_API` padrão, da opção `useLegacyPackaging` no `build.gradle.kts` e das instruções nos READMEs.
* **Verificação feita pela IA:** Conferência de que a API publicada responde em HTTPS (`/api/v1/system/health/`), execução do analisador e dos testes, conferência de que a URL compilada no APK de release é a da API publicada, medição dos APKs antes e depois da compressão e instalação do APK de release no emulador para confirmar que o app abre. A IA não criou contas nem dados em produção.
* **Decisão humana:** O aluno decidiu que o app deve usar a API publicada por padrão, deixando o `--dart-define` só para quem testa com o Django local, e aprovou a compressão das bibliotecas nativas.
* **Versionamento:** A IA criou a branch a partir da `main` atualizada, fez os commits só dos arquivos desta alteração (deixando de fora um arquivo local do aluno), enviou a branch e abriu o pull request.
* **Limitações da IA:** O APK foi testado só no emulador x86_64, não em um celular arm64 de verdade. Login, cadastro e registro de dados no APK de release não foram testados.

## 📅 Histórico de Contribuições (19/11 — protocolos por produto)
### Protocolos de uso de acordo com o suplemento

* **Análise:** A partir do relato do aluno (saturação aparecendo para whey, ciclo para creatina e nenhum alerta fora do uso contínuo), a IA leu a tela "Registrar dose", o caso de uso do alerta e o catálogo do backend. Ela identificou que a tela listava todos os protocolos, que o alerta só funciona nos protocolos com faixa no catálogo e que o protocolo escolhido não era gravado com a dose.
* **Correção:** Escrita assistida de `Product.protocols`, do caso de uso `GetDoseProtocols`, da nova lista de protocolos na tela, do envio do protocolo no registro da dose e do ajuste em `Product.rangeFor`, com testes unitários.
* **Verificação feita pela IA:** Execução do analisador e dos testes, confirmação de que o teste do whey em saturação falha com o código anterior e teste da tela no celular do aluno, em modo de dados falsos (creatina, whey e testosterona), sem gravar nada na API publicada.
* **Decisão humana:** O aluno definiu a regra (cada produto mostra só os protocolos que fazem sentido, como saturação para creatina e ciclo para anabolizantes) e autorizou o teste no próprio celular.
* **Proposta da IA, a revisar pela equipe:** Usar as faixas do catálogo como fonte dos protocolos de cada produto, para que todo protocolo oferecido tenha alerta, e oferecer uso contínuo ou quando necessário para itens cadastrados à mão.
* **Versionamento:** A IA atualizou a branch com a `main` depois do merge do pull request anterior, fez os commits só dos arquivos desta correção, enviou a branch e abriu o pull request.
* **Limitações da IA:** O teste no celular usou o catálogo em memória, que não tem a cafeína. O caso da cafeína e o dos itens cadastrados à mão foram cobertos só pelos testes unitários. As doses já gravadas na API continuam com o protocolo antigo; a correção muda só a forma como elas são comparadas.



## 📅 Histórico de Contribuições (21/11 — perfil e detalhe do dia)
### Telas Meus dados e Meu objetivo, e detalhe do dia em Registros

* **Análise:** A pedido do aluno, a IA leu o endpoint `/profile/` do backend (serializer, view e repositório) e confirmou que ele já aceitava nome, idade, peso, altura, sexo biológico e objetivo, com os limites de cada campo. No app, identificou que já existiam o `ProfileService`, o modelo `Profile` e os enums, e que faltavam o repositório, o provider e as telas. Para o detalhe do dia, a IA comparou a tela atual de Registros com o protótipo de alta fidelidade do repositório.
* **Alterações:** Escrita assistida de `ProfileRepository` (interface, implementação da API e versão fake), do caso de uso `UpdateProfile` (que repete os limites do backend), do `profileProvider`, das telas `MyDataPage` e `MyGoalPage`, da ligação delas na tela de Perfil e da tela `DayDetailPage`, aberta ao tocar em um dia da aba Registros. Também foi escrito um teste unitário do `UpdateProfile`.
* **Decisão humana:** O aluno definiu o escopo (inserir dados e objetivo no perfil, e o resumo do dia clicável como no protótipo), decidiu que as telas usam a API real, e colou, adaptou e integrou o código no projeto.
* **Verificação feita pela IA:** Leitura do código do backend e do app e comparação visual com o protótipo. A IA não compilou o app nem executou o analisador ou os testes.
* **Versionamento:** A IA não fez commit nem push. O aluno criou a branch e fez os commits.
* **Limitações da IA:** O código não foi compilado nem testado pela IA; a verificação dependeu do aluno. A tela de detalhe do dia é só de leitura, e o "Editar sintomas" do protótipo não foi feito. Em Meus dados, o usuário não consegue apagar um valor já salvo, apenas trocá-lo.
