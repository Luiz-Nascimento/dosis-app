# 2.4 Justificativas

Decisões de interface e arquitetura do **Dosis**, relacionadas ao projeto e aos usuários.

---

## Escolha das cores

O app será usado em **academias e vestiários**, com luz artificial, suor e movimento. Por isso adotamos **alto contraste**: fundo escuro, cards em cinza azulado escuro e amarelo nos botões de ação.

O contraste **amarelo e preto** remete à sinalização de segurança em maquinário pesado. Ele associa o uso de suplementos à operação de uma máquina complexa, o corpo humano, e chama atenção sem recorrer ao vermelho, evitando o alarmismo.

Cada cor tem uma função, o que facilita aprender o app:

| Cor | Código | Função | Significado |
| --- | --- | --- | --- |
| Fundo | `#121212` | Base das telas | Alto contraste sob luz artificial |
| Cards | `#17181D` | Agrupar informações | Separa blocos sem poluir |
| Amarelo | `#FFD60A` | Botões de ação e item ativo | "Fazer" |
| Laranja | `#FF9A22` | Qualquer elemento de seleção | "Escolhido" |
| Pêssego | `#FFE6C9` | Fundo das notificações | "Mensagem do app" |

### Contraste (WCAG 2.1, nível AA exige 4,5:1)

| Combinação | Razão |
| --- | --- |
| Texto branco sobre o fundo | 18,7:1 |
| Amarelo sobre o fundo | 13,3:1 |
| Texto escuro sobre botão amarelo | 13,3:1 |
| Laranja sobre o fundo | 8,8:1 |
| Laranja sobre o fundo de seleção | 6,2:1 |
| Texto escuro sobre o pêssego | 16,4:1 |

Como amarelo e laranja são parecidos entre si, a seleção **nunca depende só da cor**: o item escolhido também recebe um check ou um círculo preenchido.

---

## Tipografia

Usamos duas famílias com papéis distintos:

| Fonte | Onde | Por quê |
| --- | --- | --- |
| **Inter** | Maior parte do app (títulos, textos e campos) | Desenhada para telas, legível em tamanhos pequenos e permite leitura rápida |
| **Oswald** | Logo e notificações | Condensada e forte, ideal para textos curtos que precisam chamar atenção |

Para atender ao requisito de **fonte grande para leitura rápida durante o treino**:

| Nível | Tamanho | Uso |
| --- | --- | --- |
| H1 | 25 px | Título da tela |
| H2 | 20 px | Títulos de seção |
| H3 | 18 px | Subtítulos |
| Texto corrente | 16 px | Conteúdo e campos |
| Texto de apoio | 14 px | Descrições e legendas (nada abaixo disso) |

A diferença entre H2 e H3 é pequena, então é reforçada por **peso e cor**.

---

Organização das informações
As quatro funções principais ficam na barra inferior, sempre à mão: Início, cadastro de suplementos e anabolizantes (Rotina), calculadora de água (Hidratação) e resumo de registros (Registros). A Home reúne os atalhos para registrar dose, registrar como a pessoa se sente e ler artigos.
Todas as telas seguem a mesma estrutura: cabeçalho, título, blocos com títulos de seção e a ação principal no fim, onde o polegar alcança.
A informação aparece por etapas: o formulário de dose só abre depois de escolher o suplemento, e o cadastro pede uma informação por tela. Isso reduz a carga de quem está cansado ou com pressa.

## Navegação

- **Barra inferior fixa** com 4 ícones (Início, Rotina, Hidratação e Registros), com o item ativo em amarelo.
- **Perfil** no canto superior direito e **seta de voltar** em cada tela secundária.
- O **registro de dose**, função principal do app, leva **3 interações**:
  1. Tocar em **Registrar dose**.
  2. Escolher o suplemento (dose e horário já vêm preenchidos).
  3. Confirmar.
- **Fluxo de entrada:** introdução, cadastro ou login, confirmação de e-mail e Home.

> A barra usa só ícones, conforme o wireframe, o que reduz a descoberta para novos usuários. A posição constante e a cor do item ativo compensam isso.

---

## Componentes

Cabeçalho, barra de navegação inferior, cards, campos com unidade (kg, cm, g), campo de horário, seletor de protocolo, chips e círculos de seleção, interruptores, botões primário (amarelo) e secundário (contorno), busca, paginação, barra de progresso por passos, faixa de alerta, modal de confirmação, painel de edição e notificação.

Os ícones são **vetoriais** e o protótipo não usa imagens pesadas, o que ajuda a manter o app leve em smartphones básicos.

---

## Acessibilidade

Seguimos a **WCAG 2.1 nível AA** e as diretrizes de acessibilidade do Android.

**Já aplicado no protótipo**

- [x] Contraste mínimo de 4,5:1 em todos os textos
- [x] Seleção indicada por mais do que a cor
- [x] Campos com rótulo visível e erros em texto
- [x] Botão de mostrar/ocultar senha com nome acessível
- [x] Foco visível por teclado
- [x] Respeito à preferência do sistema por menos movimento
- [x] Botão de pausar na introdução, que avança sozinha

**Na implementação (Flutter)**

- [ ] Alvos de toque de no mínimo 48 dp (padrão do Flutter)
- [ ] Descrição dos elementos para leitores de tela (TalkBack)
- [ ] Texto acompanhando o tamanho de fonte do sistema

---

## Contexto de uso

O app será usado em **academias** (luz artificial) e **vestiários**, muitas vezes sem internet, em momentos curtos entre séries e refeições.

**Alerta sem alarmismo.** O aviso de dose usa linguagem neutra ("acima da faixa normalmente utilizada") e oferece duas saídas: **Revisar protocolo** ou **Manter configuração**. O app nunca impede o cadastro de algo só por ser anabolizante.

**Linguagem direta.** Usamos o termo "anabolizante", sem gírias, porque a gíria faz o aviso ser menos levado a sério.

**Responsabilidade.** O app avisa que não substitui orientação médica e que anabolizantes pedem acompanhamento profissional, sem bloquear o registro.

**Uso rápido.** Poucos toques, alvos grandes e opção de desfazer ao remover algo.

---

## Arquitetura do sistema

O app é desenvolvido em **Flutter e Dart**, com uma base única de código, e exige **Android 8.0 (API 26) ou superior**. Funciona **offline e de forma anônima**.

| Componente | Tecnologia | Função |
| --- | --- | --- |
| Interface | Widgets Flutter | Telas e tema, com as cores e fontes definidas |
| Estado | Riverpod | Controla rotina, doses e formulários |
| Banco local | SQLite com Drift | Guarda stacks, doses e sintomas no aparelho, para registrar sem internet |
| Motor de regras | Dart (no aparelho) | Faixas de dose e calculadora de água. Cada faixa guarda sua fonte (ANVISA, SBEM), exibida no alerta |
| Notificações | flutter_local_notifications | Lembretes de dose e mensagens educativas a partir de um banco de conteúdo local, sem servidor |
| Autenticação | Firebase Authentication (anônima) | Uso anônimo por padrão. A conta com e-mail é opcional, para backup |
| Sincronização | workmanager e Firebase | Fila que envia os dados apenas com Wi-Fi |
| Criptografia | AES-256-GCM, chave no Android Keystore (flutter_secure_storage) | Dados criptografados no aparelho antes do envio à nuvem |

**Tamanho do APK (meta: abaixo de 20 MB).** Build por arquitetura (`--split-per-abi`), apenas os pesos usados de Inter e Oswald, ícones vetoriais e nenhuma imagem pesada.
