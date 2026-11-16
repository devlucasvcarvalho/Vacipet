# Vacipet — Ordem de implementação (de baixo para cima)

Este documento descreve **em que ordem os arquivos foram feitos** e **por que essa ordem**. A regra geral no UIKit é simples: **construímos de dentro para fora** — primeiro os dados, depois a fundação visual, depois as views reutilizáveis, depois as telas, e por último as ferramentas de conveniência (previews). Cada etapa só depende das anteriores, então o projeto **compila e roda em cada passo**.

> Já vindo de SwiftUI? Pense assim: Models = seus `@Model`/`ObservableObject`; DesignSystem = seus `ViewModifier`/cores; SceneDelegate + UINavigationController = a `NavigationStack` e o `App`; `UICollectionView` + compositional layout = o `LazyVStack` com `ScrollView` — só que explícito.

---

## 0. Setup do projeto (fundação)

**Arquivos:** `Info.plist`, `Vacipet.xcodeproj/project.pbxproj`, `Assets.xcassets`

Antes de qualquer código, o projeto precisa:

1. **Remover o `Main.storyboard`** e as chaves `INFOPLIST_KEY_UIMainStoryboardFile` / `UISceneStoryboardFile` — o app é 100% construído por código (decisão registrada no plano).
2. **Declare `NSCameraUsageDescription`** no `Info.plist` — sem isso o app crasha ao abrir a câmera.
3. O template novo do Xcode (objectVersion 77) usa *file system synchronized groups*: **basta criar os arquivos na pasta `Vacipet/`** que eles entram no target automaticamente. Por isso nenhum arquivo precisou ser "registrado" no projeto.

**Por que primeiro:** qualquer erro de configuração aqui contamina tudo depois; além disso o `SceneDelegate` (passo 2) assume que não há storyboard.

## 1. Modelos de dados — `Models/Pet.swift`, `Models/Vacina.swift`

**Dependem de:** nada.

São a base de todo o resto — nenhuma tela existe sem `Pet`. Antes de desenhar um pixel, definimos **o que** o app guarda:

- `Pet` com `foto: Data?`, `observacoes: String` e `@Relationship(deleteRule: .cascade, inverse: \Vacina.pet)` para as vacinas.
- `Vacina` com `nome`, `dataAplicacao`, `local` (texto livre) e o lado-filho do relacionamento.
- `@Attribute(.unique)` no id, cascade delete (excluir o pet apaga as vacinas — decisão do plano).

**Conceito SwiftData:** `@Model` gera o schema a partir das classes; os containers só são criados no passo 4, quando a app precisa de fato de um banco para rodar.

## 2. Apoios — `Support/Formatters.swift`, `DesignSystem/AppColors.swift`, `DesignSystem/AppFonts.swift`

**Dependem de:** Foundation/UIKit. Nada do projeto.

Decisões transversais antes de qualquer tela — mudar depois custa caro:

- `Formatters`: idade ("2 anos e 10 meses") calculada de `dataNascimento` e datas por extenso em pt-BR. `Pet.idadeTexto` já depende dele — por isso ele vem logo após os modelos.
- `AppColors`: a paleta azul saúde + terrosos com variantes Dark Mode por `UIColor` dinâmico; o acento (`AccentColor`) aponta para a mesma cor.
- `AppFonts`: SF Rounded (briefing pedia fonte redonda) sem embutir arquivos.

**Regra:** tudo que duas ou mais telas compartilham nasce aqui, não dentro de uma tela.

## 3. Entrada da cena — `AppDelegate.swift`, `SceneDelegate.swift`

**Dependem de:** modelos (1) e design system (2).

Momento em que o app "ganha vida": o `SceneDelegate` cria a `window`, e é aqui que **o container SwiftData é instanciado pela primeira vez**:

```swift
let container = try ModelContainer(for: Pet.self, Vacina.self)
self.container = container // container PRECISA sobreviver à função
```

**Por que nesta ordem:** a criação do container precisa conhecer os modelos (1) e as telas às quais vai entregar o `ModelContext` só existem no passo 5. No código-fonte tudo compila junto (mesmo módulo), mas na prática escrevemos o esqueleto primeiro e refinamos depois — como neste app, onde o container precisou virar propriedade para não ser liberado no fim da função.

**Conceitos UIKit introduzidos:** `UIWindow`, `UIWindowScene`, `UINavigationController`, `makeKeyAndVisible`, injeção de dependência por init (`PetListViewController(modelContext:)`).

## 4. Views reutilizáveis — `Views/EmptyStateView.swift`, `Views/PetCardCell.swift`, `Views/VaccineRowView.swift`

**Dependem de:** modelos (1), design system (2). `PetCardCell` usa `Pet`; `VaccineRowView` não usa modelo (puro componente de formulário).

Telas no UIKit são montadas a partir de peças pequenas; cada peça concluída já é testável (nos previews) antes da tela existir:

1. `EmptyStateView` — pata grande + convite; o estado inicial da lista.
2. `PetCardCell` — o card da lista: `UICollectionViewCell`, shadow otimizado, placeholder de pata, `configure(pet:)` no padrão "a célula não busca dados sozinha".
3. `VaccineRowView` — linha editável (nome + data + local + lixeira), com callback `onRemove` para o dono (o formulário) decidir a remoção.

**Por que nesta ordem:** as telas do passo 5 empilham estas views; construí-las primeiro significa que quando a lista for montada, todos os blocos já existem.

## 5. Telas — na ordem das dependências de navegação

**Dependem de:** tudo anterior. A ordem entre elas segue o fluxo de navegação:

1. **`PetListViewController`** — a tela raiz. Container SwiftData → `FetchDescriptor` → `UICollectionView` com `CompositionalLayout` → registrar `PetCardCell` → `dataSource`/`delegate` nos extensions no fim do arquivo. Aqui entram os conceitos centrais: estados vazio/cheio, `viewWillAppear` recarregando, botão flutuante de pata, e a apresentação do formulário como `pageSheet` com dois detents (`[.medium(), .large()]`).
2. **`PetFormViewController`** — apresentado pela lista como sheet. Precisa de `VaccineRowView` pronta (4). Mesmo arquivo serve para adicionar e editar (enum `Mode`), barra de navegação com Cancelar/Salvar (o Salvar só habilita com nome), foto via `UIImagePickerController` (câmera) ou `PHPickerViewController` (galeria — sem pedir permissão), teclado ajustando `contentInset`, e o callback `onSave` para a tela de origem se atualizar (sheets não disparam `viewWillAppear`).
3. **`PetDetailViewController`** — empilhada (push) pela lista; abre o formulário no modo edição ("Editar") e exclui com cascade (`UIAlertController` destrutivo → `popToRootViewController`). Depende do formulário pronto (2) e dos formatters (2).

**Por que esta ordem de telas:** lista → form → detalhe é a sequência em que um usuário real navega; tecnicamente, cada tela registrada na navegação só é empilhada/apresentada quando a anterior funciona.

## 6. Assets e permissões visíveis — `Assets.xcassets` (AppIcon, AccentColor), ícone pata+seringa

**Dependem de:** nada (mas só faz sentido depois que a identidade visual assentou — fontes/cores, passo 2).

Ícone gerado programaticamente (CoreGraphics) nas variantes light/dark/tinted; acento apontando para o azul primário.

## 7. Previews de desenvolvimento — `Support/PreviewStore.swift` + `#Preview` em cada arquivo

**Dependem de:** tudo.

Por último, com o app pronto, embrulhamos as views/controllers UIKit com `UIViewControllerRepresentable`/`UIViewRepresentable` (`ControllerPreview`/`ViewPreview`) e semeamos um banco **in-memory** (`ModelConfiguration(isStoredInMemoryOnly: true)`) com Thor e Luna. Pré-visualiza-se `EmptyStateView`, células, sheet do formulário, lista e detalhe — sem buildar o app inteiro.

**Regra prática:** previews são ferramentas de desenvolvimento; ficam sob `#if DEBUG` e nunca entram no binário de produção.

## 8. Verificação — rodando no simulador

- Estado vazio → botão de pata → sheet (dois detents) → salvar → pet aparece no card.
- Card → detalhe → editar via sheet → excluir com cascade.
- Um erro histórico deste projeto vale o seu tempo de estudo: o `ModelContainer` era uma variável local do `SceneDelegate` e era liberado ao fim da função, fazendo o primeiro `fetch` crashar. Lição: **o container precisa sobreviver; o `ModelContext` não é dono dele.**

---

## Resumo da receita

| Passo | Arquivos | Depende de |
|-------|----------|------------|
| 0 | Setup (Info.plist, sem storyboard) | — |
| 1 | `Models/*` | — |
| 2 | `Support/Formatters`, `DesignSystem/*` | 1 |
| 3 | `AppDelegate`, `SceneDelegate` (container + navegação) | 1, 2 |
| 4 | `Views/*` (EmptyState, Card, Row) | 1, 2 |
| 5 | `Screens/*` (Lista → Form → Detalhe) | 1–4 |
| 6 | Assets, ícone | 2 |
| 7 | `PreviewStore`, `#Preview` | 1–5 |
| 8 | Simulador (fluxo completo) | tudo |

Ordem mental para seu próximo UIKit do zero: **modelos → design system → cena/navegação → views → telas na ordem em que o usuário navega → previews → simular**. Se travar, pergunte "o que esta etapa precisa para existir?" — as dependências só apontam para trás.
