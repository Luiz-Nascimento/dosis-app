# Arquitetura do app

O app Flutter segue arquitetura em camadas: **Presentation**, **Domain** e **Data**.

```
app/lib/
  main.dart               só liga tudo e chama runApp
  app_dependencies.dart   raiz de composição: escolhe a implementação de cada repositório
  core/                   código compartilhado sem regra de negócio (cliente HTTP, ids, armazenamento seguro)
  presentation/           o que o usuário vê
    pages/                uma pasta/arquivo por tela
    widgets/              componentes reutilizáveis
    theme/                cores, tipografia e tema de alto contraste
  domain/                 regras do app, sem Flutter e sem HTTP
    repositories/         interfaces (contratos) que o app precisa
    usecases/             uma ação do usuário por classe (ex.: RegisterDose)
  data/                   de onde os dados vêm
    models/               modelos tipados dos recursos
    services/             chamadas aos endpoints
    repositories/         implementam as interfaces de domain/ usando os services
```

## Regra de dependência

```
presentation  ->  domain  <-  data
```

* **Presentation** conhece Domain (use cases e interfaces) e nunca importa `data/services` nem `http`.
* **Domain** não importa Flutter, `http` nem `data/services`. Por simplicidade, ele usa os modelos de `data/models` (`RoutineItem`, `DoseLog`...) como entidades.
* **Data** implementa as interfaces de Domain.
* Só `app_dependencies.dart` conhece as classes concretas de Data.

## Por que isso importa para o projeto

Trocar a fonte dos dados (API Django, Firestore direto, banco local criptografado) só exige
uma nova implementação em `data/repositories/` e uma linha em `app_dependencies.dart`.
Telas e use cases continuam iguais.

## Como adicionar uma funcionalidade

1. Se precisar de dados novos, declare a interface em `domain/repositories/`.
2. Crie o use case em `domain/usecases/` (validações e regras ficam aqui).
3. Implemente a interface em `data/repositories/` usando o service que já existe.
4. Registre a implementação em `app_dependencies.dart`.
5. Crie a tela em `presentation/pages/` recebendo o use case.
6. Teste o use case com um repositório falso (exemplo em `app/test/domain/usecases_test.dart`).

## Exemplo pronto: Registrar dose

`RegisterDose` (domain) valida a dose e chama `DoseRepository`; `ApiDoseRepository` (data)
gera o id no aparelho e chama `DoseService`. A tela só precisa receber o `RegisterDose`.

## Pendências

* Gerenciamento de estado (KAN-8): como as telas recebem os use cases e reagem às mudanças.
* Repositórios com banco local e fila de sincronização para o funcionamento offline.