# Uso de IA no projeto
Este documento registra como ferramentas de IA foram usadas no Dosis, conforme exigido pela disciplina
de Programação para Dispositivos Móveis (UNIT).

## Ferramenta

* **Claude** (Anthropic), em conversa de chat com acesso de leitura ao repositório e ao Jira do projeto.
*"Esta documentação detalha a contribuição da IA no projeto. Ela foi responsável por estruturar a base do sistema em Flutter
 e participou ativamente do desenvolvimento de todo o código, embora não tenha realizado commits ou pushes diretamente no repositório."

## Histórico de Contribuições (01/11 e 02/11)

### Arquitetura em Camadas
* **Design e Estrutura:** Propôs e desenhou a arquitetura dividida em *Presentation*, *Domain* e *Data*.
* **Componentes Core:** Implementou as interfaces de repositório, os casos de uso principais (`RegisterDose`, `GetTodayStack`) e estabeleceu a raiz de composição (`AppDependencies`).
* **Documentação:** Ajudou com o código estrutural e gerou o arquivo explicativo em `docs/arquitetura.md`.
* **Validação:** Corrigiu erros de importação (especificamente no `DoseRepository`), executou o aplicativo e validou a integridade da arquitetura.

### Gerenciamento de Estado
* **Integração com Riverpod:** Sugeriu e escreveu a estrutura de estados utilizando a biblioteca **Riverpod** (configuração do `ProviderScope`, centralização no `providers.dart` e adaptação de telas com `ConsumerWidget`).
* **Mocking:** Desenvolveu repositórios falsos (*mock repositories*) para permitir a execução e teste das telas sem dependência de um backend ativo.
* **Validação:** Executou o aplicativo localmente, inspecionou o fluxo de dados entre as telas e validou a eficiência da solução de estado escolhida.
