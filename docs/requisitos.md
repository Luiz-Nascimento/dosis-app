# 1 Objetivo

O **Dosis** é um aplicativo desenvolvido para auxiliar praticantes de exercícios físicos a realizar um acompanhamento mais consciente, seguro e organizado do uso de suplementos e outras substâncias relacionadas à prática esportiva. A plataforma centraliza informações confiáveis e baseadas em evidências sobre os produtos utilizados, permitindo o registro da rotina de suplementação e o monitoramento de metas diárias. Além disso, o sistema apresenta alertas preventivos sobre possíveis riscos do uso inadequado ou de interações entre substâncias, facilitando o acesso ao conhecimento prático e apoiando decisões mais informadas, sempre de forma complementar e sem substituir a orientação personalizada de profissionais de saúde.


# 2.1 Funcionalidades 

F01 — Cadastro de suplementos 

Descrição: Permitir que o usuário registre os suplementos que utiliza, informando dados como nome, quantidade e frequência de uso. 

Necessidade atendida: Necessidade de organizar e acompanhar a suplementação. 

Justificativa: O registro é uma das funções centrais do Dosis e permite que o usuário mantenha um histórico organizado dos produtos utilizados. 


F02 — Visualização de suplementos ativos 

Descrição: Exibir uma lista com os suplementos atualmente cadastrados e em utilização. 

Necessidade atendida: Necessidade de visualizar rapidamente sua rotina de suplementação. 

Justificativa: Facilita a consulta dos produtos utilizados e ajuda o usuário a evitar esquecimentos ou duplicações. 


F03 — Registro de doses utilizadas 

Descrição: Permitir que o usuário registre as quantidades utilizadas de cada suplemento ao longo do dia. 

Necessidade atendida: Necessidade de acompanhar a utilização diária dos suplementos. 

Justificativa: Permite ao usuário manter um controle da própria rotina e identificar possíveis esquecimentos ou repetições. 
 

F04 — Organização de protocolos de utilização 

Descrição: Permitir o registro de diferentes formas e períodos de utilização dos suplementos. 

Necessidade atendida: Necessidade de acompanhar diferentes protocolos de suplementação. 

Justificativa: A pesquisa mostrou que a quantidade e a forma de utilização podem variar de acordo com o contexto, tornando importante registrar essas informações de forma organizada. 


F05 — Alertas de possíveis riscos 

Descrição: Apresentar alertas relacionados a possíveis riscos associados ao uso inadequado, combinações ou situações que mereçam atenção. 

Necessidade atendida: Necessidade de identificar possíveis riscos da suplementação. 

Justificativa: Os alertas ajudam o usuário a perceber situações que podem exigir maior atenção e contribuem para uma utilização mais consciente. 
 

F06 — Calculadora de ingestão de água 

Descrição: Permitir uma estimativa da ingestão de água com base nos dados informados pelo usuário e no contexto de sua rotina. 

Necessidade atendida: Necessidade de acompanhar a hidratação durante a rotina de exercícios e suplementação. 

Justificativa: A hidratação foi identificada como uma necessidade relevante para a persona prioritária e complementa o acompanhamento da rotina. 
 

F07 — Registro de sintomas e efeitos adversos 

Descrição: Permitir que o usuário registre sintomas ou efeitos percebidos durante o período de utilização de determinado produto. 

Necessidade atendida: Necessidade de acompanhar possíveis efeitos relacionados ao uso. 

Justificativa: O registro permite que o usuário acompanhe mudanças ao longo do tempo e organize informações que podem ser relevantes para sua observação pessoal. 
 

F08 — Linha do tempo de sintomas 

Descrição: Exibir os sintomas e registros realizados pelo usuário em ordem cronológica. 

Necessidade atendida: Necessidade de acompanhar a evolução dos sintomas ao longo do tempo. 

Justificativa: A visualização histórica facilita a identificação de padrões e torna o acompanhamento mais organizado. 

 
F09 — Conteúdo educativo 

Descrição: Disponibilizar informações educativas sobre suplementos, formas de utilização, benefícios, riscos e cuidados. 

Necessidade atendida: Necessidade de acesso a informações confiáveis. 

Justificativa: A pesquisa identificou a dificuldade dos usuários em diferenciar informações confiáveis de recomendações informais encontradas na internet. 


F10 — Funcionamento offline 

Descrição: Permitir que determinadas informações e registros sejam utilizados sem conexão com a internet, realizando a sincronização posteriormente. 

Necessidade atendida: Necessidade de utilizar o aplicativo em ambientes com conexão limitada ou inexistente. 

Justificativa: O estudo de caso estabelece a necessidade de funcionamento offline, especialmente considerando o contexto de uso em academias e após os treinos. 


# 2.2 Requisitos funcionais 

| ID   | Requisito Funcional            | Descrição                                                                                                                                           |
|------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| RF01 | Cadastro de suplemento         | O sistema deve permitir que o usuário cadastre um suplemento com suas informações básicas.                                                          |
| RF02 | Edição de suplemento           | O sistema deve permitir a alteração dos dados de um suplemento cadastrado.                                                                          |
| RF03 | Exclusão de suplemento         | O sistema deve permitir a exclusão de um suplemento cadastrado.                                                                                     |
| RF04 | Consulta de suplementos        | O sistema deve permitir a visualização dos suplementos cadastrados e ativos.                                                                        |
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

| ID    | Categoria               | Requisito Não Funcional                                                                                                                                           |
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


| ="ID"  | ="Funcionalidade"                             | ="Descrição"                                                                                                                          | ="Necessidade do usuário atendida"                                                               | ="Justificativa"                                                                                                                     |
|--------|-----------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| ="F01" | ="Cadastro de suplementos e/ou anabolizantes" | ="Permitir que o usuário cadastre e gerencie as substâncias utilizadas, informando seus dados básicos."                               | ="Registrar e organizar os produtos utilizados na rotina."                                       | ="Facilita o acompanhamento das substâncias utilizadas e centraliza essas informações no aplicativo."                                |
| ="F02" | ="Lista de suplementos ativos"                | ="Exibir os suplementos e outras substâncias que estão atualmente cadastrados como ativos."                                           | ="Visualizar rapidamente os produtos utilizados no momento."                                     | ="Permite consultar a rotina atual de forma rápida, reduzindo esquecimentos e facilitando o acompanhamento."                         |
| ="F03" | ="Registro de stacks e dosagens diárias"      | ="Permitir o registro das substâncias utilizadas em conjunto e das respectivas dosagens diárias."                                     | ="Organizar e acompanhar as substâncias e quantidades utilizadas."                               | ="Facilita o controle da rotina de suplementação e permite manter um histórico organizado do uso."                                   |
| ="F04" | ="Calculadora de ingestão de água"            | ="Calcular uma estimativa de ingestão de água com base nos dados informados pelo usuário e nos parâmetros definidos pelo aplicativo." | ="Ter uma referência para acompanhar a ingestão de água durante a rotina."                       | ="Auxilia o usuário no acompanhamento da hidratação relacionada à sua rotina de exercícios."                                         |
| ="F05" | ="Alertas de riscos e possíveis interações"   | ="Apresentar alertas sobre possíveis riscos relacionados ao uso inadequado ou à combinação de determinadas substâncias."              | ="Identificar situações que merecem atenção durante o uso."                                      | ="Contribui para decisões mais conscientes e para a redução de riscos relacionados ao uso inadequado."                               |
| ="F06" | ="Notificações educativas"                    | ="Enviar notificações com informações educativas relacionadas ao uso de suplementos, riscos e cuidados."                              | ="Receber informações relevantes de forma rápida e acessível."                                   | ="Incentiva o acesso contínuo a informações confiáveis e o uso mais consciente das substâncias."                                     |
| ="F07" | ="Registro de sintomas e efeitos colaterais"  | ="Permitir que o usuário registre sintomas ou efeitos percebidos durante o uso das substâncias."                                      | ="Acompanhar alterações percebidas ao longo da rotina."                                          | ="Cria um histórico dos sintomas observados, facilitando o acompanhamento das alterações percebidas."                                |
| ="F08" | ="Linha do tempo de sintomas"                 | ="Apresentar os sintomas registrados de forma cronológica."                                                                           | ="Visualizar a evolução dos sintomas ao longo do tempo."                                         | ="Facilita a identificação de mudanças e padrões nos registros realizados pelo usuário."                                             |
| ="F09" | ="Artigos educativos"                         | ="Disponibilizar conteúdos informativos sobre suplementos, anabolizantes, riscos e redução de danos."                                 | ="Acessar informações confiáveis para tomar decisões mais conscientes."                          | ="Auxilia o usuário a diferenciar informações fundamentadas de conteúdos encontrados informalmente na internet e nas redes sociais." |
| ="F10" | ="Funcionamento offline"                      | ="Permitir o acesso às principais funcionalidades e o registro de informações mesmo sem conexão com a internet."                      | ="Utilizar o aplicativo durante ou após os treinos, mesmo quando não houver conexão disponível." | ="Garante a continuidade do uso do aplicativo em diferentes situações de conectividade."                                             |
| ="F11" | ="Sincronização com a nuvem"                  | ="Permitir que os registros realizados offline sejam enviados para a nuvem quando uma conexão estiver disponível."                    | ="Manter os dados registrados mesmo após períodos sem conexão."                                  | ="Evita a perda de informações e mantém os registros sincronizados entre o dispositivo e o armazenamento em nuvem."                  |

 
