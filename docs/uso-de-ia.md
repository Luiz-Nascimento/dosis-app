# Uso de IA no projeto
Este documento registra como ferramentas de IA foram usadas no Dosis, conforme exigido pela disciplina
de Programação para Dispositivos Móveis (UNIT).

"Esta documentação detalha a contribuição da IA no projeto. Ela foi responsável por estruturar a base do sistema em Flutter
e participou ativamente do desenvolvimento de todo o código, embora não tenha realizado commits ou pushes diretamente no repositório."

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


