# Plano Mestre de Arquitetura e Desenvolvimento — BOOKY

> **Disciplina:** Programação para Dispositivos Móveis (2026.2 — UFRN)  
> **Professor:** Taniro Chacon Rodrigues  
> **Tema:** 6. App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Equipe:** Natanael (`Natanael`) & Cleiton (`Cleiton`)  
> **Arquitetura Base:** MVVM com Provider (Flutter Official Architecture)  
> **Abordagem de Dados:** 100% Offline-First (SQLite / Storage Local, sem autenticação/nuvem)  
> **Referências Obrigatórias da Disciplina:**
> - [`Aula_24_-_Arqutietura_Recomendada.pdf`](./Aula_24_-_Arqutietura_Recomendada.pdf) (MVVM + UDF + SSOT + Layered Architecture)
> - [`Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf`](./Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf) (Tema 6 — Página 7)
> - Template base da disciplina (`todo_app_arch` — commit inicial `92e5710`)

---

> [!IMPORTANT]
> ### DIRETRIZ OBRIGATÓRIA DE IMPLEMENTAÇÃO
> **Todas as tarefas descritas neste plano de desenvolvimento devem ser implementadas em estrita conformidade com os dois documentos de referência oficiais da disciplina:**
> 1. **`Aula_24_-_Arqutietura_Recomendada.pdf`** (Arquitetura sugerida pelo time Flutter, padrão MVVM, camadas UI/Data, UDF, SSOT e regras de View/ViewModel/Repository/Service);
> 2. **`Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf`** (Tema 6 — Requisitos funcionais, regras de negócio e critérios de avaliação).
>
> Nenhum código deve desviar desses princípios arquiteturais ou omitir os comportamentos especificados nos PDFs.

---

## 1. Documentos do Plano

Este repositório possui documentos de referência que governam todo o desenvolvimento:

1. **[`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md)** *(este arquivo)* — Documento mestre com os requisitos do Tema 6, arquitetura recomendada na `Aula_24`, contratos canônicos de domínio/repositórios (com persistência local abstraída) e roadmap geral.
2. **[`TASKS_NATANAEL.md`](./TASKS_NATANAEL.md)** — Backlog estrito do **Natanael** (Setup Android/`pubspec.yaml`, Modelos/Contratos, Services e Repositories de Persistência, DI `ConfigureProviders`/Rotas, Notificações Locais e Exportação PDF/CSV).
3. **[`TASKS_CLEITON.md`](./TASKS_CLEITON.md)** — Backlog estrito do **Cleiton** (API Google Books/Open Library, Scanner ISBN, Biblioteca/Estantes/Busca Avançada, Rastreador/Cronômetro, Dashboard/Gráficos `fl_chart`, Ficha do Livro/Empréstimos/Diário/OCR).
4. **[`README.md`](./README.md)** — Visão geral do projeto, arquitetura e instruções de execução.

> **REGRA PARA IAs E DESENVOLVEDORES:** Antes de criar ou alterar qualquer arquivo, consulte os contratos da Seção 4 e a Matriz de Propriedade da Seção 3. **Nunca** renomeie campos, rotas ou interfaces sem atualizar este documento primeiro. O aplicativo é **100% local e offline** (sem login, sem perfil e sem Firebase).

---

## 2. Escopo Funcional e Regras de Negócio (Tema 6)

Conforme especificado no documento oficial da disciplina (**Tema 6 — App de Biblioteca Pessoal e Rastreamento de Leitura**):

> **Descrição:** Aplicativo voltado para leitores organizarem seu acervo físico e digital, acompanharem metas e estatísticas de leitura, registrarem citações favoritas e controlarem empréstimos de livros para amigos.

### RF1 — Catalogação por ISBN (Scanner + API)
> *Requisito do Tema 6:* Cadastro manual ou leitura do código de barras ISBN pela câmera, buscando automaticamente capa, título, autor, sinopse, editora e número de páginas via integração com a API do Google Books ou Open Library.

- **Entrada:** Leitura de código de barras EAN-13/ISBN pela câmera (`mobile_scanner`), digitação manual do ISBN ou cadastro 100% manual.
- **Normalização:** Remover hífens/espaços; aceitar ISBN-10 e ISBN-13.
- **Trava do Scanner:** Ao detectar um ISBN válido, pausar o processamento de novos frames até finalizar ou cancelar a consulta HTTP (evita rajadas de requisições).
- **Fallback de APIs (`BookApiService`):**
  1. Consultar **Google Books API** (`GET https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}`).
  2. Se não encontrar ou faltar campos essenciais (título, autores, editora, páginas, capa, sinopse), consultar **Open Library API** (`GET https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&jscmd=data&format=json` e, se necessário, `/isbn/{isbn}.json` / `/works/{id}.json` para sinopse) e mesclar os dados.
- **Revisão obrigatória:** Os dados retornados preenchem o formulário manual (`AddBookScreen`) para o usuário revisar/editar antes de salvar.
- **Campos mínimos:** `title` obrigatório; `totalPages >= 0` (se `0`, desabilita cálculo de porcentagem/estimativa com aviso claro).

### RF2 — Organização por Estantes, Formato e Status
> *Requisito do Tema 6:* Classificação por status (Quero Ler, Lendo, Lido, Abandonado), avaliação pessoal, tags customizadas e estantes temáticas.

- **Status de Leitura (`BookStatus`) — exatamente 4 valores mutuamente exclusivos:**
  - `wantToRead` (*Quero Ler*)
  - `reading` (*Lendo*)
  - `read` (*Lido*)
  - `abandoned` (*Abandonado*)
- **Regra Crítica (`Status` ≠ `Emprestado`):** *Emprestado* **não** é um status de leitura (deve ser corrigido no protótipo `add_book_screen.dart`, onde havia o chip `'Emprestado'` no lugar de `'Abandonado'`). Um livro *Lido* ou *Quero Ler* pode ser emprestado e, ao ser devolvido, mantém seu status original. O indicador *Emprestado* é derivado da existência de um `LoanModel` com `isReturned == false` para aquele `bookId`.
- **Acervo Físico e Digital (`BookFormat`):** `physical` (*Físico*) ou `digital` (*Digital*), atendendo à descrição oficial do Tema 6.
- **Organização adicional:**
  - `rating` (`double?`, `0.0` a `5.0`, avaliação pessoal opcional).
  - `tags` (`List<String>` customizadas em lowercase/normalizadas sem duplicatas).
  - `shelfIds` (estantes temáticas customizadas gerenciadas via `ShelfRepository`, ex.: *Favoritos*, *Clássicos*, *Sci-Fi*; um livro pode pertencer a 0 ou mais estantes temáticas).
- **Ciclo de datas do livro:**
  - Ao entrar em `reading` pela primeira vez: preencher `startedAt ??= DateTime.now()`.
  - Ao mudar para `read`: preencher `finishedAt = DateTime.now()` e, se `totalPages > 0`, definir `currentPage = totalPages`.
  - Se o livro sair de `read` para `reading`, `wantToRead` ou `abandoned`: limpar `finishedAt = null` (garantindo que livros reabertos ou desmarcados não inflem o gráfico de lidos do mês).
  - `finishedAt` é a **fonte oficial** para contabilizar *"livros lidos por mês"* nos gráficos (nunca usar `updatedAt` para estatísticas históricas).
- **Exclusão de Estante Temática:**
  - Ao excluir uma `ShelfModel`, remover seu `shelfId` da lista `book.shelfIds` dos livros associados (sem excluir os livros do acervo).

### RF3 — Rastreador de Progresso e Sessões
> *Requisito do Tema 6:* Cronômetro de leitura e atualização da página atual ou porcentagem concluída, gerando histórico diário de páginas lidas e estimativa de tempo para terminar o livro.

- **Seleção do livro:** A `ReadingTrackerScreen` recebe `bookId` via argumento de rota. Se aberta sem `bookId` definido, deve permitir escolher um livro com status `reading`.
- **Atualização por página OU porcentagem (%):**
  - Usuário pode incrementar/decrementar (`+`/`-`), digitar diretamente o número da página atual **ou** informar a porcentagem concluída (`0` a `100%`), convertendo automaticamente via `page = ((percent / 100) * totalPages).round().clamp(0, totalPages)`.
- **Cronômetro resiliente a segundo plano:**
  - Não depender apenas de contador incremental em `Timer.periodic` (que congela quando o app vai para background).
  - Armazenar `activeStartedAt` (`DateTime`) + `accumulatedSeconds` (`int`); quando em execução, exibir `accumulatedSeconds + DateTime.now().difference(activeStartedAt).inSeconds`.
  - Ao pausar: somar o delta a `accumulatedSeconds` e limpar `activeStartedAt`.
- **Salvamento de Sessão (`SaveReadingSessionUseCase`):**
  - Calcula `pagesRead = max(0, endPage - startPage)`.
  - Persiste `ReadingSessionModel` (com `dateKey` normalizada `YYYY-MM-DD`, `durationSeconds`, `startPage`, `endPage`, `pagesRead`).
  - Atualiza `book.currentPage = endPage`. Se `totalPages > 0 && endPage >= totalPages`, promove `book.status = BookStatus.read` e preenche `book.finishedAt`.
- **Velocidade e Estimativa de Tempo Restante:**
  - `pagesPerHour` calculado a partir do histórico de sessões do livro (`totalPagesReadInSessions / (totalDurationSeconds / 3600)`). Se o livro ainda não tiver sessões com `pagesRead > 0` e `durationSeconds > 0`, usar a média global das sessões do leitor.
  - `remainingSeconds = ((totalPages - currentPage) / pagesPerHour) * 3600`.
  - Caso `totalPages <= 0` ou `pagesPerHour <= 0` ou `currentPage >= totalPages`, exibir mensagem amigável (*"Estimativa indisponível"* ou *"Livro concluído"*), evitando `NaN` / `Infinity`.
- **Histórico diário:** Agrupar `ReadingSessionModel` por dia (`dateKey: YYYY-MM-DD`) exibindo total de páginas e tempo lido por dia.

### RF4 — Diário de Citações, Anotações e Resenhas (com OCR)
> *Requisito do Tema 6:* Registro de anotações, resenhas e trechos favoritos de cada livro (com suporte a OCR via câmera para extrair texto diretamente da página física).

- **Três tipos (`NoteType`) na `BookDetailsScreen`:**
  - `note` (*Anotação*): reflexão livre, `chapter` opcional, `page` opcional.
  - `quote` (*Citação*): trecho favorito, `chapter` opcional, `page` opcional, suporte a **OCR via câmera**.
  - `review` (*Resenha*): resenha pessoal do livro + atualização opcional de `book.rating` (`1` a `5` estrelas).
  - **Avaliação Pessoal e Resenha (`NoteType.review`):**
    - Como a avaliação (`rating`, `0.0..5.0`) vive em `BookModel` e o texto da resenha vive em `NoteModel`, o `BookDetailsViewModel` atualiza `BookRepository.saveBook(book.copyWith(rating: ...))` e `NoteRepository.saveNote(...)` de forma independente (mantendo `BookRepository` e `NoteRepository` 100% desacoplados conforme Slide 23 da `Aula_24`).
- **Fluxo do OCR local (`google_mlkit_text_recognition`):**
  - Captura foto via câmera ou galeria (`image_picker`).
  - Executa reconhecimento com `TextRecognitionScript.latin` **100% no dispositivo**.
  - Preenche o campo de texto do formulário de citação/anotação para o usuário revisar/editar antes de salvar.
  - Descartar arquivo temporário da imagem após extração do texto.

### RF5 — Controle de Empréstimos e Alerta de Atraso
> *Requisito do Tema 6:* Registro de livros emprestados (nome do amigo, contato, data do empréstimo e data prevista de devolução) com alerta de atraso.

- **Campos obrigatórios no registro:** `borrowerName`, `borrowerContact` (telefone/e-mail/WhatsApp), `loanDate`, `expectedReturnDate` (validar `expectedReturnDate >= loanDate`).
- **Integridade:** Um livro pode ter **no máximo 1 empréstimo ativo** (`isReturned == false`).
- **Devolução:** Atualiza o registro existente com `isReturned = true` e `returnedDate = DateTime.now()` (mantendo histórico de empréstimos) e cancela a notificação local agendada para aquele empréstimo.
- **Alerta de atraso (dupla proteção):**
  1. **Lógica de atraso:** `isOverdue = !isReturned && DateTime.now().isAfter(endOfDay(expectedReturnDate))`.
  2. **Visual imediato (independe de permissão):** Badge destacado `ATRASADO` nos cards da `LibraryScreen`, na `BookDetailsScreen` e banner de alerta na `HomeScreen`.
  3. **Notificação local agendada:** Ao registrar empréstimo, agendar notificação via `flutter_local_notifications` para a `expectedReturnDate` (respeitando permissão `POST_NOTIFICATIONS` no Android 13+).

### RF6 — Busca Avançada e Estatísticas
> *Requisito do Tema 6:* Filtros combinados por autor, gênero, ano, status ou avaliação, além de gráficos de livros/páginas lidas por mês e meta anual de leitura.

- **Busca Avançada (`LibraryScreen`):**
  - Busca textual instantânea por `title` ou `author` + chips rápidos (`Todos`, `Quero Ler`, `Lendo`, `Lido`, `Abandonado`, `Emprestados`, `Atrasados`).
  - Modal de **Filtros Combinados (`AND`)**: `author`, `genre`, `publishedYear`, `status`, `minRating` (`1..5`), `shelfId` e `tag`, com contador de filtros ativos e botão *Limpar*.
  - A filtragem combinada ocorre de forma reativa no `LibraryViewModel` sobre os modelos de domínio fornecidos pelo `BookRepository`, `LoanRepository` e `ShelfRepository`.
- **Estatísticas & Meta Anual (`HomeScreen` com `fl_chart`):**
  - **Meta Anual:** `livros concluídos no ano corrente / annualReadingGoal` (ano dinâmico `DateTime.now().year`). A meta anual pode ser editada diretamente no Dashboard / Home através de um diálogo rápido (`EditGoalDialog`).
  - **Gráficos mensais (ano selecionado/atual):**
    1. Barras de **Livros lidos por mês** (agrupados por `finishedAt`).
    2. Barras/linha de **Páginas lidas por mês** (soma de `pagesRead` de `sessions` agrupados por `dateKey`).

### RF7 — Persistência Local, Backup Local e Exportação (PDF e CSV)
> *Requisito do Tema 6:* Sincronização em nuvem entre dispositivos e exportação do catálogo completo ou lista de desejos em PDF e CSV.
> *(Adaptado para escopo 100% offline: persistência e exportação portável local sem nuvem/Firebase)*

- **Abstração Total da Persistência Local (`Aula_24` Slides 4, 8, 20–26):**
  - Nem a UI, nem os ViewModels, nem os UseCases conhecem a implementação física do banco.
  - Os `Repositories` consomem um `StorageService` (armazenamento local/primário SQLite ou arquivo JSON local).
- **Exportação (`PDF` e `CSV`):**
  - Usuário escolhe **Escopo** (*Catálogo Completo* ou *Lista de Desejos (`wantToRead`)*) e **Formato** (*PDF* ou *CSV*).
  - Ação acessível diretamente via botão de exportação na AppBar da `LibraryScreen`.
  - **PDF:** Usar fonte `.ttf` em `assets/fonts/` no pacote `pdf` para garantir acentuação PT-BR (`ç`, `ã`, `é`, `ô`).
  - **CSV:** Incluir BOM UTF-8 (`\uFEFF`) e escapar corretamente aspas/quebras de linha de sinopses e citações.
  - Compartilhamento nativo via `path_provider` + `share_plus`.

### Transversal — Design System & Fidelidade às Telas do Stitch
- Manter estritamente a paleta de 5 tons de `AppColors` e os estilos de `AppTheme` em Modo Claro e Modo Escuro.
- Alternância de tema acessível diretamente no cabeçalho/AppBar da `MainNavigationScreen`.

---

## 3. Arquitetura Estrita (`Aula_24_-_Arqutietura_Recomendada.pdf` + `todo_app_arch`)

O projeto segue rigorosamente a **Arquitetura Sugerida para Aplicações Flutter** apresentada pelo Prof. Taniro na `Aula_24`: **Arquitetura em Camadas (UI, Domain/Logic, Data) + MVVM + Fluxo Unidirecional de Dados (UDF) + Fonte Única de Verdade (SSOT)** com `Provider` e `ConfigureProviders`.

```text
┌───────────────────────────────────────────────────────────────────────────┐
│ UI LAYER (lib/features/<feature>/presentation/)              [Slides 6,14]│
│   View (Screens & Widgets)  ◄── UI State / notifyListeners ──  ViewModel  │
│        │                                                        ▲         │
│        └──── User Action / Command (Slide 18) ──────────────────┘         │
└─────────────────────────────────────────────────────────┬─────────────────┘
                                                          │
┌─────────────────────────────────────────────────────────▼─────────────────┐
│ LOGIC / DOMAIN LAYER (lib/domain/use_cases/)                 [Slides 7,27]│
│   UseCases combinam múltiplos Repositories ou encapsulam lógica complexa  │
└─────────────────────────────────────────────────────────┬─────────────────┘
                                                          │
┌─────────────────────────────────────────────────────────▼─────────────────┐
│ DATA LAYER / MODEL (lib/domain/repositories/ + lib/data/)    [Slides 8,20]│
│   Repositories (lib/data/repositories/)                      [Slides 22,23]│
│     • Fonte Única de Verdade (SSOT) para 1 tipo de dado                   │
│     • Cache, tratamento de erros, transformação em Domain Models          │
│     • Expõem Streams / Futures com Domain Models                          │
│     • PROIBIDO: Repository depender de outro Repository (Slide 23)        │
│                                      │                                    │
│   Services (lib/data/services/)      ▼  (Muitos-para-muitos, Slide 25)    │
│     • Camada mais baixa, Stateless, 1 por fonte de dados externa/nativa   │
│     • StorageService, BookApiService, OcrService, NotificationService,    │
│       ExportService                                                       │
└───────────────────────────────────────────────────────────────────────────┘
```

### Leis Arquiteturais Invioláveis (Baseadas nos Slides da `Aula_24`)

1. **Separação de Responsabilidades & View Limpa (Slides 4, 6, 15, 16):**
   - As `Views` são apenas composições de widgets que descrevem como apresentar dados prontos vindos do `ViewModel` (`context.watch<VM>()`) e repassam eventos do usuário para comandos do `ViewModel` (`context.read<VM>()`).
   - **Lógica permitida dentro da View (Slide 16):** apenas condicionais simples (`if`) para mostrar/ocultar widgets, lógica de animação, lógica de layout e navegação simples.
   - **Proibido na View:** qualquer lógica de dados, cálculos de negócio, chamadas HTTP, acesso a plugins nativos ou Services.
2. **Relação 1:1 View ↔ ViewModel (Slides 6, 15, 18):**
   - Cada View tem seu ViewModel correspondente (`ChangeNotifier`):
     - `HomeScreen` ↔ `HomeViewModel`
     - `LibraryScreen` ↔ `LibraryViewModel`
     - `AddBookScreen` ↔ `AddBookViewModel`
     - `BookDetailsScreen` ↔ `BookDetailsViewModel`
     - `ReadingTrackerScreen` ↔ `TrackerViewModel`
3. **Repositories como Fonte Única de Verdade — SSOT (Slides 4, 8, 22, 23):**
   - Cada tipo de dado no app tem um repositório próprio (`BookRepository`, `ShelfRepository`, `SessionRepository`, `NoteRepository`, `LoanRepository`, `SettingsRepository`).
   - O repositório é o **único lugar** que pode mutar aquele tipo de dado (Slide 8).
   - Relação `Repositories ↔ ViewModels` é **muitos-para-muitos** (Slide 23).
   - **Regra Crítica (Slide 23):** *Repos não devem depender uns dos outros; caso precisem combinar dados, isso deve ser feito no ViewModel ou na Camada de Domínio (UseCases).*
4. **Services Stateless (Slides 8, 25):**
   - Serviços são a camada mais baixa, não armazenam estado (*stateless*), isolam o carregamento de dados (APIs REST, banco local, recursos nativos) e expõem `Future` / `Stream`.
5. **Fluxo Unidirecional de Dados — UDF (Slides 4, 9, 10):**
   - O estado flui da camada de dados (`Repository`) para a `UI`, e os eventos de interação fluem da `UI` de volta ao `Repository`.
6. **Injeção de Dependências no padrão do Template (`ConfigureProviders` — Slide 30 / `todo_app_arch`):**
   - `lib/core/di/configure_providers.dart` instancia `Services` → `Repositories` → `UseCases` → `ViewModels` no `MultiProvider` em `lib/main.dart`.

### Estrutura de Diretórios Alvo e Propriedade de Arquivos

```text
lib/
├── core/                                      [NATANAEL]
│   ├── constants/app_constants.dart           (existente)
│   ├── di/configure_providers.dart            (DI central no padrão todo_app_arch)
│   ├── routes/app_routes.dart                 (onGenerateRoute com Args tipados)
│   ├── theme/                                 (app_colors.dart, app_theme.dart, theme_controller.dart)
│   └── utils/command.dart                     (helper Result / Command para ViewModels - Slide 18)
│
├── domain/
│   ├── models/                                [NATANAEL - Contratos compartilhados]
│   │   ├── enums.dart                         (BookStatus, BookFormat, NoteType)
│   │   ├── book_model.dart
│   │   ├── shelf_model.dart
│   │   ├── reading_session_model.dart
│   │   ├── note_model.dart
│   │   ├── loan_model.dart
│   │   └── app_settings_model.dart            (meta anual e lembretes diários)
│   ├── repositories/                          [NATANAEL - Interfaces abstratas SSOT]
│   │   ├── book_repository.dart
│   │   ├── shelf_repository.dart
│   │   ├── session_repository.dart
│   │   ├── note_repository.dart
│   │   ├── loan_repository.dart
│   │   └── settings_repository.dart
│   └── use_cases/
│       ├── delete_book_use_case.dart          [NATANAEL] (remove livro + notas/empréstimos/sessões)
│       ├── export_library_use_case.dart       [NATANAEL] (filtra escopo + chama ExportService)
│       ├── save_reading_session_use_case.dart [CLEITON]  (salva sessão + atualiza página/status)
│       ├── get_dashboard_stats_use_case.dart  [CLEITON]  (agrega Home: livros/páginas/meta/atrasos)
│       ├── register_loan_use_case.dart        [CLEITON]  (valida 1 ativo + salva Loan + agenda notif)
│       └── return_loan_use_case.dart          [CLEITON]  (marca devolvido + cancela notif)
│
├── data/
│   ├── services/
│   │   ├── storage_service.dart               [NATANAEL] (persistência local)
│   │   ├── notification_service.dart          [NATANAEL] (flutter_local_notifications)
│   │   ├── export_service.dart                [NATANAEL] (PDF + CSV + share_plus)
│   │   ├── book_api_service.dart              [CLEITON]  (Google Books + Open Library HTTP)
│   │   └── ocr_service.dart                   [CLEITON]  (image_picker + ML Kit OCR)
│   └── repositories/                          [NATANAEL - Implementações concretas SSOT]
│       ├── book_repository_impl.dart
│       ├── shelf_repository_impl.dart
│       ├── session_repository_impl.dart
│       ├── note_repository_impl.dart
│       ├── loan_repository_impl.dart
│       └── settings_repository_impl.dart
│
└── features/
    ├── home/presentation/                     [CLEITON]
    │   ├── viewmodels/home_viewmodel.dart
    │   ├── screens/home_screen.dart
    │   ├── screens/main_navigation_screen.dart
    │   └── widgets/
    ├── library/presentation/                  [CLEITON]
    │   ├── viewmodels/library_viewmodel.dart
    │   ├── viewmodels/add_book_viewmodel.dart
    │   ├── screens/library_screen.dart
    │   ├── screens/add_book_screen.dart
    │   └── widgets/
    ├── tracker/presentation/                  [CLEITON]
    │   ├── viewmodels/tracker_viewmodel.dart
    │   ├── screens/reading_tracker_screen.dart
    │   └── widgets/
    └── book_details/presentation/             [CLEITON]
        ├── viewmodels/book_details_viewmodel.dart
        ├── screens/book_details_screen.dart
        └── widgets/
```

---

## 4. Contratos Canônicos de Dados e Repositórios

### 4.1 Enums Canônicos (`lib/domain/models/enums.dart`)
- `enum BookStatus { wantToRead, reading, read, abandoned }`
- `enum BookFormat { physical, digital }`
- `enum NoteType { note, quote, review }`

### 4.2 Modelos de Domínio (`toJson()` / `fromJson()`)

1. **`AppSettingsModel`** (coleção lógica: `settings`)
   - `annualReadingGoal`: `int` (padrão `12`)
   - `dailyReminderEnabled`: `bool` (padrão `false`)
   - `dailyReminderHour`: `int` (padrão `20`)
   - `dailyReminderMinute`: `int` (padrão `0`)
   - `updatedAt`: `DateTime`

2. **`BookModel`** (coleção lógica: `books`)
   - `id`: `String`
   - `isbn`: `String?`
   - `title`: `String`
   - `author`: `String`
   - `publisher`: `String?`
   - `publishedYear`: `int?`
   - `genre`: `String?`
   - `synopsis`: `String?`
   - `coverUrl`: `String?`
   - `totalPages`: `int` (padrão `0`)
   - `currentPage`: `int` (padrão `0`)
   - `status`: `BookStatus` (padrão `BookStatus.wantToRead`)
   - `format`: `BookFormat` (padrão `BookFormat.physical`)
   - `rating`: `double?` (`0.0..5.0`)
   - `tags`: `List<String>` (padrão `[]`)
   - `shelfIds`: `List<String>` (padrão `[]`)
   - `startedAt`: `DateTime?`
   - `finishedAt`: `DateTime?`
   - `createdAt`: `DateTime`
   - `updatedAt`: `DateTime`

3. **`ShelfModel`** (coleção lógica: `shelves`)
   - `id`: `String`
   - `name`: `String`
   - `description`: `String?`
   - `createdAt`: `DateTime`
   - `updatedAt`: `DateTime`

4. **`ReadingSessionModel`** (coleção lógica: `sessions`)
   - `id`: `String`
   - `bookId`: `String`
   - `startTime`: `DateTime`
   - `durationSeconds`: `int`
   - `startPage`: `int`
   - `endPage`: `int`
   - `pagesRead`: `int` (`>= 0`)
   - `dateKey`: `String` (formato `'YYYY-MM-DD'`)
   - `updatedAt`: `DateTime`

5. **`NoteModel`** (coleção lógica: `notes`)
   - `id`: `String`
   - `bookId`: `String`
   - `type`: `NoteType` (`note` | `quote` | `review`)
   - `chapter`: `String?`
   - `page`: `int?`
   - `content`: `String`
   - `createdAt`: `DateTime`
   - `updatedAt`: `DateTime`

6. **`LoanModel`** (coleção lógica: `loans`)
   - `id`: `String`
   - `bookId`: `String`
   - `borrowerName`: `String`
   - `borrowerContact`: `String`
   - `loanDate`: `DateTime`
   - `expectedReturnDate`: `DateTime`
   - `returnedDate`: `DateTime?`
   - `isReturned`: `bool` (padrão `false`)
   - `notificationId`: `int?`
   - `updatedAt`: `DateTime`

### 4.3 Contratos das Interfaces de Repositório (`lib/domain/repositories/`)

- **`SettingsRepository`**:
  - `Stream<AppSettingsModel> watchSettings()`
  - `Future<AppSettingsModel> getSettings()`
  - `Future<void> updateAnnualGoal(int goal)`
  - `Future<void> updateDailyReminder({required bool enabled, required int hour, required int minute})`
- **`BookRepository`**:
  - `Stream<List<BookModel>> watchBooks()`
  - `Stream<BookModel?> watchBookById(String bookId)`
  - `Future<List<BookModel>> getBooks()`
  - `Future<BookModel?> getBookById(String bookId)`
  - `Future<void> saveBook(BookModel book)`
  - `Future<void> deleteBook(String bookId)`
- **`ShelfRepository`**:
  - `Stream<List<ShelfModel>> watchShelves()`
  - `Future<List<ShelfModel>> getShelves()`
  - `Future<void> saveShelf(ShelfModel shelf)`
  - `Future<void> deleteShelf(String shelfId)`
- **`SessionRepository`**:
  - `Stream<List<ReadingSessionModel>> watchSessions()`
  - `Stream<List<ReadingSessionModel>> watchSessionsByBook(String bookId)`
  - `Future<List<ReadingSessionModel>> getSessionsByBook(String bookId)`
  - `Future<void> addSession(ReadingSessionModel session)`
  - `Future<void> deleteSessionsByBook(String bookId)`
- **`NoteRepository`**:
  - `Stream<List<NoteModel>> watchNotesByBook(String bookId)`
  - `Future<void> saveNote(NoteModel note)`
  - `Future<void> deleteNote(String noteId)`
  - `Future<void> deleteNotesByBook(String bookId)`
- **`LoanRepository`**:
  - `Stream<List<LoanModel>> watchLoans()`
  - `Stream<List<LoanModel>> watchLoansByBook(String bookId)`
  - `Future<LoanModel?> getActiveLoanByBook(String bookId)`
  - `Future<void> saveLoan(LoanModel loan)`
  - `Future<void> deleteLoansByBook(String bookId)`

### 4.4 Contratos de Rotas (`lib/core/routes/app_routes.dart`)
- `AppRoutes.initial` = `AppRoutes.main`
- `AppRoutes.main` (`/main`) → `MainNavigationScreen` (abas: Início e Biblioteca)
- `AppRoutes.addBook` (`/add-book`) → `AddBookScreen` (cria `AddBookViewModel`)
- `AppRoutes.bookDetails` (`/book-details`) → `BookDetailsScreen` (cria `BookDetailsViewModel` recebendo `bookId`)
- `AppRoutes.tracker` (`/tracker`) → `ReadingTrackerScreen` (cria `TrackerViewModel` recebendo `bookId` opcional)

### 4.5 Planejamento da Arquitetura do Banco de Dados Relacional (SQLite / Drift)

> [!NOTE]
> **Status deste planejamento:** Concepção arquitetural concluída e documentada. A implementação de código permanece intocada nesta entrega, mantendo o `LocalJsonStorageService` e o `InMemoryStorageService` em pleno funcionamento com 100% de cobertura nos testes.

#### 1. Princípios de Projeto e Isolamento Arquitetural (`Aula_24`)
A transição futura da persistência de arquivos JSON para um banco relacional SQLite segue estritamente o princípio de **Layered Architecture** e **Dependency Inversion** do Prof. Taniro:
- O banco de dados fica 100% encapsulado abaixo da camada de dados (`lib/data/services/` e `lib/data/repositories/`).
- **Nenhuma View, ViewModel ou UseCase será alterada:** toda a comunicação continuará passando pelas interfaces `BookRepository`, `ShelfRepository`, `SessionRepository`, `NoteRepository`, `LoanRepository` e `SettingsRepository`.
- **Estratégia de Injeção:** Bastará implementar `SqliteStorageService implements StorageService` (ou repositórios SQLite dedicados) e alternar o provider em `ConfigureProviders.createDependencyTree()`.

#### 2. DDL do Esquema Relacional Canônico (SQLite)

```sql
-- 1. Configurações Globais do Leitor
CREATE TABLE IF NOT EXISTS app_settings (
    id TEXT PRIMARY KEY NOT NULL,
    annual_goal INTEGER NOT NULL DEFAULT 12,
    reminder_enabled INTEGER NOT NULL DEFAULT 0,
    reminder_hour INTEGER NOT NULL DEFAULT 20,
    reminder_minute INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
);

-- 2. Acervo de Livros
CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    authors TEXT NOT NULL,           -- JSON array de strings: ["Autor 1", "Autor 2"]
    isbn TEXT,
    cover_url TEXT,
    publisher TEXT,
    published_year INTEGER,
    genre TEXT,
    synopsis TEXT,
    total_pages INTEGER NOT NULL DEFAULT 0,
    current_page INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('wantToRead', 'reading', 'read', 'abandoned')),
    format TEXT NOT NULL CHECK (format IN ('physical', 'digital')),
    rating REAL,
    tags TEXT NOT NULL DEFAULT '[]', -- JSON array de strings normalizadas
    shelf_ids TEXT NOT NULL DEFAULT '[]', -- JSON array de IDs de estantes
    started_at TEXT,                 -- ISO-8601 UTC
    finished_at TEXT,                -- ISO-8601 UTC (fonte oficial de estatísticas)
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- 3. Estantes Temáticas
CREATE TABLE IF NOT EXISTS shelves (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    book_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- 4. Tabela Relacional N:N (Livro <-> Estante)
CREATE TABLE IF NOT EXISTS book_shelves (
    book_id TEXT NOT NULL,
    shelf_id TEXT NOT NULL,
    PRIMARY KEY (book_id, shelf_id),
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
    FOREIGN KEY (shelf_id) REFERENCES shelves (id) ON DELETE CASCADE
);

-- 5. Sessões de Leitura (Rastreador)
CREATE TABLE IF NOT EXISTS reading_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    date_key TEXT NOT NULL,          -- Formato YYYY-MM-DD para agrupamentos ultra-rápidos
    start_page INTEGER NOT NULL,
    end_page INTEGER NOT NULL,
    pages_read INTEGER NOT NULL,
    duration_seconds INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);

-- 6. Diário de Citações, Anotações e Resenhas
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('citation', 'annotation', 'review')),
    page INTEGER,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);

-- 7. Empréstimos de Livros
CREATE TABLE IF NOT EXISTS loans (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    borrower_name TEXT NOT NULL,
    borrower_contact TEXT NOT NULL,
    loan_date TEXT NOT NULL,
    expected_return_date TEXT NOT NULL,
    returned_date TEXT,
    is_returned INTEGER NOT NULL DEFAULT 0, -- 0 = ativo, 1 = devolvido
    notification_id INTEGER,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);
```

#### 3. Índices de Otimização
```sql
-- Busca rápida de livros por status e ISBN
CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);

-- Consultas históricas de sessões por livro e data
CREATE INDEX IF NOT EXISTS idx_sessions_book_id ON reading_sessions(book_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date_key ON reading_sessions(date_key);

-- Anotações vinculadas a livros
CREATE INDEX IF NOT EXISTS idx_notes_book_id ON notes(book_id);

-- Detecção instantânea de empréstimos em aberto e vencidos
CREATE INDEX IF NOT EXISTS idx_loans_book_id ON loans(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_active ON loans(is_returned, expected_return_date);
```

#### 4. Estratégia de Migração de Dados (Zero Data Loss)
Quando a migração para SQLite for ativada:
1. No método `init()` do `SqliteStorageService`, o serviço verifica se existe o arquivo `local_storage.json`.
2. Caso o arquivo exista e a tabela `books` esteja vazia, executa uma transação de `seed`:
   - Desserializa as coleções (`books`, `shelves`, `sessions`, `notes`, `loans`, `settings`);
   - Insere em lote (`batch.insert`) com tratamento de chaves estrangeiras;
   - Renomeia `local_storage.json` para `local_storage.json.bak` como salvaguarda.
3. Como o `BackupSyncService` exporta o snapshot em JSON padrão, o backup/restore continuará 100% interoperável entre versões.

---

## 5. Roadmap Integrado (Sprints 1 a 4)

| Sprint | Foco Principal | Natanael (Arquitetura Base, Persistência Local, Notificações, Export) | Cleiton (APIs Livros, Scanner, Biblioteca, Tracker, Home, Detalhes/OCR) | Checkpoint de Integração |
| :--- | :--- | :--- | :--- | :--- |
| **Sprint 1** | Fundação Arquitetural (`Aula_24`), Contratos & Persistência Local | • Setup Android + `pubspec.yaml` + `Command`<br>• Todos os Models + Interfaces de Repositories<br>• `StorageService` (local) + 6 Repositories SSOT<br>• `ConfigureProviders`, `AppRoutes`, `ThemeController` | • `BookApiService` (Google Books + Open Library + testes HTTP)<br>• `OcrService` (`image_picker` + ML Kit)<br>• Preparar ViewModels contra os contratos da Seção 4 | **Marco 1:** Árvore de dependências `ConfigureProviders` ativa no `main.dart`, app abre direto na `MainNavigationScreen` e `BookRepository` emitindo streams reativos (SSOT). |
| **Sprint 2** | Catalogação, Estante, Empréstimos & Diário | • `NotificationService` (agendamento + cancelamento + permissões)<br>• `DeleteBookUseCase` (exclusão em cascata via Repositories)<br>• Registro das dependências da Sprint 2 no `ConfigureProviders` | • `AddBookViewModel` + `AddBookScreen` (`mobile_scanner` + form completo)<br>• `LibraryViewModel` + `LibraryScreen` (estantes, tags, busca avançada, badges empréstimo/atraso)<br>• `RegisterLoanUseCase` + `ReturnLoanUseCase`<br>• `BookDetailsViewModel` + `BookDetailsScreen` (3 abas, OCR, empréstimos) | **Marco 2:** Fluxo completo cadastrar livro (ISBN/manual) → listar/filtrar → abrir detalhes → registrar notas/citações OCR/resenha → emprestar e devolver. |
| **Sprint 3** | Rastreador, Estatísticas, Meta & Exportação | • `ExportService` (PDF Unicode + CSV UTF-8 + `share_plus`)<br>• `ExportLibraryUseCase`<br>• Suporte à meta anual no `SettingsRepository` | • `SaveReadingSessionUseCase`<br>• `TrackerViewModel` + `ReadingTrackerScreen` (cronômetro background, pág/%, estimativa, histórico diário)<br>• `GetDashboardStatsUseCase`<br>• `HomeViewModel` + `HomeScreen` (leitura atual, atrasos, `fl_chart` livros e páginas/mês, meta anual editável) | **Marco 3:** Sessão salva no Tracker atualiza progresso na Home, gráficos `fl_chart` refletem dados reais e exportação PDF/CSV compartilha arquivos válidos. |
| **Sprint 4** | Testes, Auditoria Visual & Entrega | • Testes unitários (`Models`, `Repositories`, `ExportService`, `ExportLibraryUseCase`, `DeleteBookUseCase`)<br>• Auditoria Light/Dark<br>• Atualização final do `README.md` + `flutter build apk --release` | • Testes unitários (`BookApiService`, `LibraryViewModel`, `SaveReadingSessionUseCase`, `TrackerViewModel`, `RegisterLoanUseCase`, `GetDashboardStatsUseCase`)<br>• Auditoria Light/Dark (`Home`, `Library`, `AddBook`, `BookDetails`, `Tracker`)<br>• Validação ponta a ponta offline | **Marco Final:** `flutter analyze` limpo, `flutter test` passando 100%, APK validado em dispositivo físico. |

---

## 6. Fluxo de Trabalho Git e Anti-Conflitos

1. **Branches por Issue:** Nunca commitar direto na `main`. Padrão: `feat/n01-project-setup`, `feat/c01-book-api-service`, etc.
2. **Isolamento de pastas:** Respeitar rigorosamente os donos `[NATANAEL]` e `[CLEITON]` da Seção 3.
3. **Ordem na Sprint 1:** Natanael abre e faz merge primeiro da **ISSUE-N01 + ISSUE-N02** (dependências + modelos + interfaces) para que Cleiton já puxe as classes de domínio reais na `main`.
4. **Conventional Commits:** `feat:`, `fix:`, `refactor:`, `test:`, `docs:`.
5. **Code Review Cruzado:** Todo PR é revisado pelo outro integrante antes do merge na `main`.
