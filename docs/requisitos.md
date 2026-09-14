# 1 Objetivo

O **Dosis** é um aplicativo desenvolvido para auxiliar praticantes de exercícios físicos a realizar um acompanhamento mais consciente, seguro e organizado do uso de suplementos e outras substâncias relacionadas à prática esportiva. A plataforma centraliza informações confiáveis e baseadas em evidências sobre os produtos utilizados, permitindo o registro da rotina de suplementação e o monitoramento de metas diárias. Além disso, o sistema apresenta alertas preventivos sobre possíveis riscos do uso inadequado ou de interações entre substâncias, facilitando o acesso ao conhecimento prático e apoiando decisões mais informadas, sempre de forma complementar e sem substituir a orientação personalizada de profissionais de saúde.


# 2.1 Funcionalidades 

|   | Funcionalidade                             | Necessidade do usuário                                                              | Justificativa                                                                                                                  |
|-----|--------------------------------------------|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| F01 | Cadastro de suplementos e/ou anabolizantes | Registrar e organizar os produtos utilizados.                                       | Centraliza as informações dos produtos utilizados pelo usuário, facilitando seu acompanhamento.                                |
| F02 | Lista de suplementos ativos                | Visualizar rapidamente os produtos atualmente utilizados.                           | Facilita a consulta da rotina de suplementação e reduz o risco de esquecimento.                                                |
| F03 | Registro de stacks e dosagens diárias      | Organizar as substâncias utilizadas em conjunto e suas respectivas dosagens.        | Permite acompanhar a rotina de utilização e manter um histórico das substâncias registradas.                                   |
| F04 | Calculadora de ingestão de água            | Obter uma estimativa da quantidade de água a ser ingerida.                          | Auxilia o usuário no acompanhamento da hidratação relacionada à prática de exercícios.                                         |
| F05 | Alertas de riscos e possíveis interações   | Identificar situações que possam exigir maior atenção durante o uso de substâncias. | Contribui para o uso mais consciente ao informar sobre possíveis riscos e interações.                                          |
| F06 | Notificações educativas                    | Receber informações relevantes de forma rápida e acessível.                         | Mantém o usuário informado sobre suplementos, riscos e cuidados relacionados ao seu uso.                                       |
| F07 | Registro de sintomas e efeitos colaterais  | Registrar sintomas ou efeitos percebidos durante o uso.                             | Permite acompanhar alterações percebidas pelo usuário e manter um histórico de ocorrências.                                    |
| F08 | Linha do tempo de sintomas                 | Visualizar os sintomas registrados em ordem cronológica.                            | Facilita a identificação da evolução e de possíveis padrões ao longo do tempo.                                                 |
| F09 | Artigos educativos                         | Acessar informações confiáveis sobre suplementos, anabolizantes e seus riscos.      | Auxilia o usuário a tomar decisões mais conscientes e a diferenciar informações baseadas em evidências de conteúdos informais. |
| F10 | Funcionamento offline                      | Utilizar as principais funcionalidades mesmo sem conexão com a internet.            | Permite o uso do aplicativo durante ou após atividades físicas, mesmo em locais com conexão limitada.                          |
| F11 | Sincronização com a nuvem                  | Manter os dados registrados mesmo após períodos sem conexão.                        | Evita a perda de informações e mantém os dados sincronizados quando uma conexão estiver disponível.                            |


# 2.2 Requisitos funcionais 

|    | Requisito Funcional            | Descrição                                                                                                                                           |
|------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| RF01 | Cadastro de suplemento/anabolizante         | O sistema deve permitir que o usuário cadastre um suplemento com suas informações básicas.                                                          |
| RF02 | Edição de suplemento/anabolizante           | O sistema deve permitir a alteração dos dados de um suplemento cadastrado.                                                                          |
| RF03 | Exclusão de suplemento/anabolizante         | O sistema deve permitir a exclusão de um suplemento cadastrado.                                                                                     |
| RF04 | Consulta de suplementos/anabolizante        | O sistema deve permitir a visualização dos suplementos cadastrados e ativos.                                                                        |
| RF05 | Registro de utilização         | O sistema deve permitir que o usuário registre a utilização de um suplemento.                                                                       |
| RF06 | Registro de quantidade         | O sistema deve permitir informar a quantidade utilizada de cada suplemento.                                                                         |
| RF07 | Registro de protocolo          | O sistema deve permitir registrar informações relacionadas à forma e ao período de utilização.                                                      |
| RF08 | Geração de alertas             | O sistema deve apresentar alertas sobre possíveis riscos relacionados ao uso inadequado ou à combinação de substâncias cadastradas.                 |
| RF09 | Estimativa de ingestão de água | O sistema deve permitir informar dados do usuário e apresentar uma estimativa de ingestão de água conforme os parâmetros definidos pelo aplicativo. |
| RF10 | Registro de sintomas           | O sistema deve permitir registrar sintomas ou efeitos adversos percebidos pelo usuário.                                                             |
| RF11 | Consulta de sintomas           | O sistema deve permitir consultar os sintomas registrados em ordem cronológica.                                                                     |
| RF12 | Consulta de conteúdo educativo | O sistema deve permitir o acesso aos conteúdos educativos disponibilizados pelo aplicativo.                                                         |
| RF13 | Funcionamento offline          | O sistema deve permitir a utilização das principais funcionalidades sem conexão com a internet.                                                     |
| RF14 | Sincronização de dados         | O sistema deve sincronizar os dados registrados offline quando uma conexão estiver disponível.                                                      |


# 2.3 Requisitos não funcionais

|     | Categoria               | Requisito Não Funcional                                                                                                                                           |
|-------|-------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RNF01 | Usabilidade             | As principais funcionalidades devem ser acessíveis em no máximo três interações, priorizando fluxos simples e objetivos.                                          |
| RNF02 | Acessibilidade          | A interface deve utilizar fontes legíveis, elementos com tamanho adequado e contraste suficiente para facilitar a leitura.                                        |
| RNF03 | Desempenho              | O aplicativo deve apresentar tempo de resposta adequado durante a execução das principais funcionalidades, inclusive em dispositivos básicos.                     |
| RNF04 | Compatibilidade         | O aplicativo deve ser compatível com dispositivos que utilizem Android 8.0 ou superior.                                                                           |
| RNF05 | Funcionamento offline   | As principais funcionalidades devem permanecer disponíveis sem conexão com a internet, permitindo o armazenamento local dos dados.                                |
| RNF06 | Segurança e privacidade | Os dados do usuário devem ser protegidos, utilizando mecanismos adequados de segurança e proteção durante o armazenamento e a transmissão para serviços externos. |
| RNF07 | Armazenamento           | O aplicativo deve possuir armazenamento local suficiente para manter os dados registrados durante períodos sem conexão.                                           |
| RNF08 | Sincronização           | Os dados armazenados localmente devem ser sincronizados quando uma conexão estiver disponível, priorizando a utilização de Wi-Fi quando aplicável.                |
| RNF09 | Tamanho do aplicativo   | O tamanho final do APK deve ser de, no máximo, 20 MB.                                                                                                             |
| RNF10 | Comunicação             | Os alertas e informações apresentadas pelo aplicativo devem utilizar linguagem clara, objetiva e não alarmista.                                                   |
| RNF11 | Interface               | A interface deve ser simples e adequada ao contexto de utilização durante ou após atividades físicas, considerando situações de cansaço e atenção reduzida.       |
| RNF12 | Privacidade             | O tratamento dos dados do usuário deve considerar os princípios de privacidade e proteção de dados estabelecidos pela LGPD. 


# 2.4 CRUD            

C — Criar

O sistema deverá permitir a criação de informações relacionadas à rotina do usuário, como:

* Cadastro de suplementos e/ou anabolizantes;
* Registro das dosagens utilizadas;
* Cadastro de protocolos de utilização;
* Criação de stacks;
* Registro de ingestão de água;
* Registro de sintomas e possíveis efeitos colaterais;
* Cadastro dos dados necessários para a estimativa de ingestão de água;
* Criação de registros no histórico de utilização.

R — Consultar

O usuário deverá conseguir consultar as informações armazenadas no aplicativo, incluindo:

* Lista de suplementos ativos;
* Dosagens e protocolos cadastrados;
* Stacks registrados;
* Histórico de utilização;
* Registros de ingestão de água;
* Sintomas e efeitos colaterais;
* Linha do tempo de sintomas;
* Alertas de possíveis riscos e interações;
* Notificações educativas;
* Artigos e conteúdos educativos.

U — Atualizar

A operação de atualização será necessária principalmente para informações que podem sofrer alterações ao longo do tempo, como:

* Dados dos suplementos/anabolizantes cadastrados;
* Dosagens;
* Protocolos de utilização;
* Stacks;
* Registros de ingestão de água;
* Dados utilizados para o cálculo da hidratação;
* Informações sincronizadas com a nuvem.

O histórico de utilização e os registros de sintomas não devem ser alterados automaticamente, pois representam acontecimentos já registrados. Caso seja necessário corrigir alguma informação, o sistema poderá permitir a edição do registro original.

D — Excluir

O aplicativo deverá permitir a exclusão de informações inseridas pelo próprio usuário, principalmente:

* Suplementos/anabolizantes cadastrados;
* Dosagens e protocolos;
* Stacks;
* Registros de ingestão de água;
* Sintomas registrados;
* Dados pessoais utilizados nos cálculos.

A exclusão deve considerar a privacidade dos dados do usuário, permitindo que informações pessoais ou registros inseridos pelo usuário sejam removidos quando necessário.


# 2.5 Priorização
|  | Funcionalidade | Prioridade |
|---|---|---|
| F01 | Cadastro de suplementos e/ou anabolizantes | Essencial |
| F02 | Lista de suplementos ativos | Essencial |
| F03 | Registro de stacks e dosagens diárias | Essencial |
| F04 | Calculadora de ingestão de água | Importante |
| F05 | Alertas de riscos e possíveis interações | Essencial |
| F06 | Notificações educativas | Importante |
| F07 | Registro de sintomas e efeitos colaterais | Essencial |
| F08 | Linha do tempo de sintomas | Importante |
| F09 | Artigos educativos | Importante |
| F10 | Funcionamento offline | Importante |
| F11 | Sincronização com a nuvem | Secundária |
            

 
