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
