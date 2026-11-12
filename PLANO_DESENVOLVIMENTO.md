# Plano Mestre de Arquitetura e Desenvolvimento — BOOKY

> **Disciplina:** Programação para Dispositivos Móveis (2026.2 — UFRN)  
> **Tema:** 6. App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Equipe:** Natanael (`Natanael`) & Cleiton (`Cleiton`)  
> **Referências Obrigatórias da Disciplina:**
> - `Aula_24_-_Arqutietura_Recomendada.pdf` (MVVM + UDF + SSOT + Layered Architecture)
> - Template base da disciplina (`todo_app_arch` — commit inicial `92e5710`)
> - Repositório de referência Firebase (`https://github.com/taniro/auth_app_firebase`)

---

## 1. Documentos do Plano

Este repositório possui **3 documentos normativos** que governam todo o desenvolvimento (humano ou assistido por IA):

1. **[`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md)** *(este arquivo)* — Documento mestre com regras de negócio, arquitetura, contratos canônicos de dados, estrutura do Firebase/Firestore e roadmap geral.
2. **[`TASKS_NATANAEL.md`](./TASKS_NATANAEL.md)** — Backlog estrito do **Natanael** (Setup Android/Firebase, `pubspec.yaml`, Modelos/Contratos, Banco Cloud Firestore, Autenticação, DI/Rotas, Notificações, Exportação PDF/CSV e Perfil).
3. **[`TASKS_CLEITON.md`](./TASKS_CLEITON.md)** — Backlog estrito do **Cleiton** (API Google Books/Open Library, Scanner ISBN, Biblioteca/Estantes/Busca Avançada, Rastreador/Cronômetro, Dashboard/Gráficos `fl_chart`, Ficha do Livro/Empréstimos/Diário/OCR).

> **REGRA PARA IAs E DESENVOLVEDORES:** Antes de criar ou alterar qualquer arquivo, consulte os contratos da Seção 4 e a Matriz de Propriedade da Seção 3. **Nunca** renomeie campos, rotas, coleções ou interfaces sem atualizar este documento primeiro.

---

## 2. Escopo Funcional e Regras de Negócio (Tema 6)

O **BOOKY** organiza acervos físicos e digitais, acompanha metas e sessões de leitura, registra citações/resenhas (com OCR) e controla empréstimos com sincronização em nuvem e exportação.

### RF1 — Catalogação por ISBN (Scanner + API)
- **Entrada:** Leitura de código de barras EAN-13/ISBN pela câmera (`mobile_scanner`) ou digitação manual do ISBN ou cadastro 100% manual.
- **Normalização:** Remover hífens/espaços; aceitar ISBN-10 e ISBN-13.
- **Trava do Scanner:** Ao detectar um ISBN válido, pausar o processamento de novos frames até finalizar ou cancelar a consulta HTTP (evita rajadas de requisições).
- **Fallback de APIs:**
  1. Consultar **Google Books API** (`GET https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}`).
  2. Se não encontrar ou faltar campos essenciais (título, autores, editora, páginas, capa, sinopse), consultar **Open Library API** (`GET https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&jscmd=data&format=json` e, se necessário, `/isbn/{isbn}.json` / `/works/{id}.json` para sinopse) e mesclar os dados.
- **Revisão obrigatória:** Os dados retornados preenchem o formulário manual (`AddBookScreen`) para o usuário revisar/editar antes de salvar.
- **Campos mínimos:** `title` obrigatório; `totalPages >= 0` (se `0`, desabilita cálculo de porcentagem/estimativa com aviso claro).

### RF2 — Organização por Estantes, Formato e Status
- **Status de Leitura (`BookStatus`) — exatamente 4 valores mutuamente exclusivos:**
  - `wantToRead` (*Quero Ler*)
  - `reading` (*Lendo*)
  - `read` (*Lido*)
  - `abandoned` (*Abandonado*)
- **Regra Crítica (`Status` ≠ `Emprestado`):** *Emprestado* **não** é um status de leitura. Um livro *Lido* ou *Quero Ler* pode ser emprestado e, ao ser devolvido, mantém seu status original. O indicador *Emprestado* é derivado da existência de um `LoanModel` com `isReturned == false` para aquele `bookId`.
- **Formato (`BookFormat`):** `physical` (*Físico*) ou `digital` (*Digital*).
- **Organização adicional:**
  - `rating` (`double?`, `0.0` a `5.0`, opcional; normalmente preenchido quando lido/em andamento).
  - `tags` (`List<String>` customizadas em lowercase/normalizadas sem duplicatas).
  - `shelfIds` / `shelves` (estantes temáticas customizadas, ex.: *Favoritos*, *Clássicos*, *Sci-Fi*; um livro pode pertencer a 0 ou mais estantes ou à estante padrão *Geral*).
- **Ciclo de datas do livro:**
  - Ao entrar em `reading` pela primeira vez: preencher `startedAt = DateTime.now()`.
  - Ao mudar para `read`: preencher `finishedAt = DateTime.now()` e, se `totalPages > 0`, definir `currentPage = totalPages`.
  - `finishedAt` é a **fonte oficial** para contabilizar *"livros lidos por mês"* nos gráficos (nunca usar `updatedAt` para estatísticas históricas, pois edições posteriores distorceriam o mês de conclusão).

### RF3 — Rastreador de Progresso e Sessões
- **Seleção do livro:** A `ReadingTrackerScreen` recebe `bookId` via argumento de rota. Se aberta sem `bookId` definido, deve permitir escolher um livro com status `reading`.
- **Atualização por página OU porcentagem (%):**
  - Usuário pode incrementar/decrementar (`+`/`-`), digitar diretamente o número da página atual **ou** informar a porcentagem concluída (`0` a `100%`), convertendo automaticamente via `page = ((percent / 100) * totalPages).round().clamp(0, totalPages)`.
- **Cronômetro resiliente a segundo plano:**
  - Não depender apenas de contador incremental em `Timer.periodic` (que congela em background).
  - Armazenar `activeStartedAt` (`DateTime`) + `accumulatedSeconds` (`int`); quando em execução, exibir `accumulatedSeconds + DateTime.now().difference(activeStartedAt).inSeconds`.
  - Ao pausar: somar o delta a `accumulatedSeconds` e limpar `activeStartedAt`.
- **Salvamento de Sessão (`SaveReadingSessionUseCase`):**
  - Calcula `pagesRead = max(0, endPage - startPage)`.
  - Persiste `ReadingSessionModel` (com `date` normalizada `YYYY-MM-DD`, `durationSeconds`, `startPage`, `endPage`, `pagesRead`).
  - Atualiza `book.currentPage = endPage`. Se `totalPages > 0 && endPage >= totalPages`, promove `book.status = BookStatus.read` e preenche `book.finishedAt`.
- **Velocidade e Estimativa de Tempo Restante:**
  - `pagesPerHour` calculado a partir do histórico de sessões do livro (`totalPagesReadInSessions / (totalDurationSeconds / 3600)`). Se o livro ainda não tiver sessões com `pagesRead > 0` e `durationSeconds > 0`, usar a média global das sessões do usuário.
  - `remainingSeconds = ((totalPages - currentPage) / pagesPerHour) * 3600`.
  - Caso `totalPages <= 0` ou `pagesPerHour <= 0` ou `currentPage >= totalPages`, exibir mensagem amigável (*"Estimativa indisponível"* ou *"Livro concluído"*), evitando `NaN` / `Infinity`.
- **Histórico diário:** Agrupar `ReadingSessionModel` por dia (`dateKey: YYYY-MM-DD`) exibindo total de páginas e tempo lido por dia.

### RF4 — Diário de Citações, Anotações e Resenhas (com OCR)
- **Três tipos (`NoteType`) na `BookDetailsScreen`:**
  - `note` (*Anotação*): reflexão livre, `chapter` opcional, `page` opcional.
  - `quote` (*Citação*): trecho favorito, `chapter` opcional, `page` opcional, suporte a **OCR via câmera**.
  - `review` (*Resenha*): resenha pessoal do livro + atualização opcional de `book.rating` (`1` a `5` estrelas).
- **Fluxo do OCR local (`google_mlkit_text_recognition`):**
  - Captura foto via câmera ou galeria (`image_picker`).
  - Executa reconhecimento com `TextRecognitionScript.latin` **100% offline no dispositivo**.
  - Preenche o campo de texto do formulário de citação/anotação para o usuário revisar/editar antes de salvar.
  - **Descartar arquivo temporário da imagem** após extração (não enviar imagens para nuvem; mantém custo zero no Firebase).

### RF5 — Controle de Empréstimos e Alerta de Atraso
- **Campos obrigatórios no registro:** `borrowerName`, `borrowerContact` (telefone/e-mail/WhatsApp), `loanDate`, `expectedReturnDate` (validar `expectedReturnDate >= loanDate`).
- **Integridade:** Um livro pode ter **no máximo 1 empréstimo ativo** (`isReturned == false`).
- **Devolução:** Atualiza o registro existente com `isReturned = true` e `returnedDate = DateTime.now()` (mantendo histórico de empréstimos) e cancela a notificação local agendada para aquele empréstimo.
- **Alerta de atraso (dupla proteção):**
  1. **Lógica de atraso:** `isOverdue = !isReturned && DateTime.now().isAfter(endOfDay(expectedReturnDate))`.
  2. **Visual imediato (independe de permissão):** Badge destacado `ATRASADO` nos cards da `LibraryScreen`, na `BookDetailsScreen` e banner de alerta na `HomeScreen`.
  3. **Notificação local agendada:** Ao registrar empréstimo, agendar notificação via `flutter_local_notifications` para a `expectedReturnDate` (respeitando permissão `POST_NOTIFICATIONS` no Android 13+).

### RF6 — Busca Avançada e Estatísticas
- **Busca Avançada (`LibraryScreen`):**
  - Busca textual instantânea por `title` ou `author` + chips rápidos (`Todos`, `Quero Ler`, `Lendo`, `Lido`, `Abandonado`, `Emprestados`, `Atrasados`).
  - Modal de **Filtros Combinados (`AND`)**: `author`, `genre`, `publishedYear`, `status`, `minRating` (`1..5`), `shelfId` e `tag`, com contador de filtros ativos e botão *Limpar*.
  - *Nota técnica Firestore:* Como o Firestore não permite consultas dinâmicas arbitrárias combinando desigualdades e múltiplos campos sem explosão de índices compostos, o repositório faz o stream da coleção `users/{uid}/books` (com cache offline) e a filtragem combinada ocorre em Dart no `LibraryViewModel`.
- **Estatísticas (`HomeScreen` com `fl_chart`):**
  - **Meta Anual:** `livros concluídos no ano corrente / annualReadingGoal` (ano dinâmico `DateTime.now().year` — corrigir `"2024"` hardcoded no protótipo).
  - **Gráficos mensais (ano selecionado/atual):**
    1. Barras de **Livros lidos por mês** (agrupados por `finishedAt`).
    2. Barras/linha de **Páginas lidas por mês** (soma de `pagesRead` de `sessions` agrupados por `date`).

### RF7 — Banco em Nuvem (Firebase), Offline-First e Exportação
- **Banco Oficial (conforme aula do Prof. Taniro):** **Firebase Authentication + Cloud Firestore**, seguindo o padrão de `https://github.com/taniro/auth_app_firebase`.
- **Offline-First Nativo do Firestore:**
  - Habilitar `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);` na inicialização.
  - O app lê/escreve normalmente mesmo sem internet (o SDK do Firestore mantém cache local em disco e sincroniza automaticamente quando a conexão retorna).
  - **Custo Zero (Plano Spark):** Não usar Firebase Storage. Capas da API armazenam apenas `coverUrl` (`String`); OCR descarta fotos após extrair texto; exportações gravam temporariamente via `path_provider` e compartilham via `share_plus`.
- **Exportação (`PDF` e `CSV`):**
  - Usuário escolhe **Escopo** (*Catálogo Completo* ou *Lista de Desejos (`wantToRead`)*) e **Formato** (*PDF* ou *CSV*).
  - **PDF:** Usar fonte `.ttf` em `assets/fonts/` no pacote `pdf` para garantir acentuação PT-BR (`ç`, `ã`, `é`, `ô`).
  - **CSV:** Incluir BOM UTF-8 (`\uFEFF`) e escapar corretamente aspas/quebras de linha de sinopses e citações.

### Transversal — Design System & Tema
- Manter estritamente a paleta de 5 tons de [`AppColors`](file:///media/natan_luc/HD%201TB/projetos/booky/lib/core/theme/app_colors.dart#L5-L35) e os estilos de [`AppTheme`](file:///media/natan_luc/HD%201TB/projetos/booky/lib/core/theme/app_theme.dart#L6-L497) em Modo Claro e Modo Escuro (observando compatibilidade `CardThemeData` caso o Flutter SDK instalado exija).

---

## 3. Arquitetura Estrita (`Aula_24` + `todo_app_arch` + `auth_app_firebase`)

O projeto segue rigorosamente a **Arquitetura Recomendada pelo Time Flutter** apresentada na `Aula_24`: **MVVM + Fluxo Unidirecional de Dados (UDF) + Fonte Única de Verdade (SSOT)** com `Provider` e `ConfigureProviders`.

```text
┌───────────────────────────────────────────────────────────────────────────┐
│ UI LAYER (lib/features/<feature>/presentation/)                           │
│   View (Screens & Widgets)  ◄── UI State / notifyListeners ──  ViewModel  │
│        │                                                        ▲         │
│        └──── User Action / Command ─────────────────────────────┘         │
└─────────────────────────────────────────────────────────┬─────────────────┘
                                                          │
┌─────────────────────────────────────────────────────────▼─────────────────┐
│ LOGIC / DOMAIN LAYER (lib/domain/use_cases/) — Somente quando necessário  │
│   UseCases combinam múltiplos Repositories ou encapsulam fluxo complexo   │
└─────────────────────────────────────────────────────────┬─────────────────┘
                                                          │
┌─────────────────────────────────────────────────────────▼─────────────────┐
│ DATA LAYER (Model)                                                        │
│   Repositories (lib/domain/repositories/ + lib/data/repositories/)        │
│     • SSOT para 1 tipo de dado (Book, Shelf, Session, Note, Loan, User)   │
│     • Expõem Streams / Futures com Domain Models                          │
│     • PROIBIDO: Repository depender de outro Repository (Slide 23)        │
│                                      │                                    │
│   Services (lib/data/services/)      ▼  (Muitos-para-muitos, Slide 25)    │
│     • Stateless, 1 por fonte externa/nativa                               │
│     • AuthService, FirestoreService, BookApiService, OcrService,          │
│       NotificationService, ExportService                                  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Leis Arquiteturais Invioláveis (Checklist para Devs e IAs)
1. **View sem regra de negócio:** Widgets só renderizam estado vindo do ViewModel (`context.watch<VM>()`) e disparam métodos/commands (`context.read<VM>()`). Permitido na View apenas: condicionais de visibilidade, animação, layout e navegação simples. **Nunca** chamar `FirebaseAuth`, `FirebaseFirestore`, `http` ou `Service` dentro de Widget.
2. **Relação 1:1 View ↔ ViewModel (Slide 15):** Toda tela principal possui seu próprio `ViewModel` (`ChangeNotifier`):
   - `AuthScreen` ↔ `AuthViewModel`
   - `HomeScreen` ↔ `HomeViewModel`
   - `LibraryScreen` ↔ `LibraryViewModel`
   - `AddBookScreen` ↔ `AddBookViewModel`
   - `BookDetailsScreen` ↔ `BookDetailsViewModel`
   - `ReadingTrackerScreen` ↔ `TrackerViewModel`
   - `ProfileScreen` ↔ `ProfileViewModel`
3. **Repositories não dependem uns dos outros (Slide 23):** Se uma operação precisa de `BookRepository` + `SessionRepository` (ou `LoanRepository` + `NotificationService`), a orquestração ocorre em um **UseCase** (`lib/domain/use_cases/`) ou no **ViewModel** quando for apenas leitura/exibição.
4. **`Repositories ↔ Services` (Slide 25):** Repositories consomem Services (ex.: `BookRepository` usa `FirestoreService` e `AuthService` para saber o `uid` ativo). Services **não** guardam estado de domínio.
5. **SSOT Reativo:** Os repositórios de dados são registrados como instâncias únicas no `ConfigureProviders` e expõem `Stream<List<T>>` (ou `Stream<UserProfile?>`) para manter `Home`, `Library`, `BookDetails`, `Tracker` e `Profile` sempre sincronizados após qualquer mutação.
6. **Injeção de Dependências no padrão Taniro (`ConfigureProviders`):**
   - `lib/core/di/configure_providers.dart` implementa `static Future<ConfigureProviders> createDependencyTree()`.
   - `lib/main.dart` inicializa `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` (como em `taniro/auth_app_firebase`), chama `await ConfigureProviders.createDependencyTree()`, injeta no `MultiProvider` e define `home: const AuthChecker()` (com `routes` / `onGenerateRoute` em `AppRoutes`).
7. **Sem `Auth` acoplado na UI como no demo simples:** Em `taniro/auth_app_firebase`, `LoginPage` chamava `AuthService` direto por ser um exemplo mínimo. No BOOKY, respeitando a `Aula_24`, `AuthChecker` e `AuthScreen` consomem `AuthViewModel` / `AuthRepository` (nunca `FirebaseAuth.instance` direto na View).

### Estrutura de Diretórios Alvo e Propriedade de Arquivos

```text
lib/
├── core/                                      [NATANAEL]
│   ├── constants/app_constants.dart           (existente)
│   ├── di/configure_providers.dart            (DI central no padrão Taniro)
│   ├── routes/app_routes.dart                 (onGenerateRoute com Args tipados)
│   ├── theme/                                 (app_colors.dart, app_theme.dart, theme_controller.dart)
│   └── utils/command.dart                     (helper Result / Command para ViewModels)
│
├── domain/
│   ├── models/                                [NATANAEL - Contratos compartilhados]
│   │   ├── enums.dart                         (BookStatus, BookFormat, NoteType)
│   │   ├── book_model.dart
│   │   ├── shelf_model.dart
│   │   ├── reading_session_model.dart
│   │   ├── note_model.dart
│   │   ├── loan_model.dart
│   │   └── user_profile_model.dart
│   ├── repositories/                          [NATANAEL - Interfaces abstratas]
│   │   ├── auth_repository.dart
│   │   ├── book_repository.dart
│   │   ├── shelf_repository.dart
│   │   ├── session_repository.dart
│   │   ├── note_repository.dart
│   │   ├── loan_repository.dart
│   │   └── user_profile_repository.dart
│   └── use_cases/
│       ├── delete_book_use_case.dart          [NATANAEL] (remove livro + subdados no Firestore)
│       ├── export_library_use_case.dart       [NATANAEL] (prepara dados + chama ExportService)
│       ├── save_reading_session_use_case.dart [CLEITON]  (salva sessão + atualiza página/status)
│       ├── get_dashboard_stats_use_case.dart  [CLEITON]  (agrega Home: livros/páginas/meta/atrasos)
│       ├── register_loan_use_case.dart        [CLEITON]  (valida 1 ativo + salva Loan + agenda notif)
│       └── return_loan_use_case.dart          [CLEITON]  (marca devolvido + cancela notif)
│
├── data/
│   ├── services/
│   │   ├── auth_service.dart                  [NATANAEL] (FirebaseAuth wrapper)
│   │   ├── firestore_service.dart             [NATANAEL] (Cloud Firestore wrapper stateless)
│   │   ├── notification_service.dart          [NATANAEL] (flutter_local_notifications)
│   │   ├── export_service.dart                [NATANAEL] (PDF + CSV + share_plus)
│   │   ├── book_api_service.dart              [CLEITON]  (Google Books + Open Library HTTP)
│   │   └── ocr_service.dart                   [CLEITON]  (image_picker + ML Kit OCR)
│   └── repositories/                          [NATANAEL - Implementações Firebase/SSOT]
│       ├── firebase_auth_repository.dart
│       ├── firestore_book_repository.dart
│       ├── firestore_shelf_repository.dart
│       ├── firestore_session_repository.dart
│       ├── firestore_note_repository.dart
│       ├── firestore_loan_repository.dart
│       └── firestore_user_profile_repository.dart
│
└── features/
    ├── auth/presentation/                     [NATANAEL]
    │   ├── viewmodels/auth_viewmodel.dart
    │   ├── screens/auth_screen.dart
    │   └── widgets/auth_checker.dart
    ├── profile/presentation/                  [NATANAEL]
    │   ├── viewmodels/profile_viewmodel.dart
    │   ├── screens/profile_screen.dart
    │   └── widgets/
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

## 4. Contratos Canônicos de Dados & Estrutura do Firebase

### 4.1 Enums Canônicos (`lib/domain/models/enums.dart`)
- `enum BookStatus { wantToRead, reading, read, abandoned }` — serializar usando `.name` (`'wantToRead'`, `'reading'`, `'read'`, `'abandoned'`).
- `enum BookFormat { physical, digital }` — serializar usando `.name` (`'physical'`, `'digital'`).
- `enum NoteType { note, quote, review }` — serializar usando `.name` (`'note'`, `'quote'`, `'review'`).

### 4.2 Modelos de Domínio (Chaves exatas para `toJson()` / `fromJson()`)

Todos os IDs primários são `String` (UUID v4 gerado no cliente antes de gravar no Firestore, garantindo criação offline sem colisão). Datas no Firestore devem usar `Timestamp` (convertendo com segurança `Timestamp` ou `String` ISO-8601 no `fromJson`).

1. **`UserProfileModel`** (`users/{uid}`)
   - `uid`: `String`
   - `name`: `String`
   - `email`: `String`
   - `annualReadingGoal`: `int` (padrão `12`)
   - `dailyReminderEnabled`: `bool` (padrão `false`)
   - `dailyReminderHour`: `int` (padrão `20`)
   - `dailyReminderMinute`: `int` (padrão `0`)
   - `updatedAt`: `DateTime`

2. **`BookModel`** (`users/{uid}/books/{bookId}`)
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

3. **`ShelfModel`** (`users/{uid}/shelves/{shelfId}`)
   - `id`: `String`
   - `name`: `String`
   - `description`: `String?`
   - `createdAt`: `DateTime`
   - `updatedAt`: `DateTime`

4. **`ReadingSessionModel`** (`users/{uid}/sessions/{sessionId}`)
   - `id`: `String`
   - `bookId`: `String`
   - `startTime`: `DateTime`
   - `durationSeconds`: `int`
   - `startPage`: `int`
   - `endPage`: `int`
   - `pagesRead`: `int` (`>= 0`)
   - `dateKey`: `String` (formato `'YYYY-MM-DD'` para agrupamento diário exato)
   - `updatedAt`: `DateTime`

5. **`NoteModel`** (`users/{uid}/notes/{noteId}`)
   - `id`: `String`
   - `bookId`: `String`
   - `type`: `NoteType` (`note` | `quote` | `review`)
   - `chapter`: `String?`
   - `page`: `int?`
   - `content`: `String`
   - `createdAt`: `DateTime`
   - `updatedAt`: `DateTime`

6. **`LoanModel`** (`users/{uid}/loans/{loanId}`)
   - `id`: `String`
   - `bookId`: `String`
   - `borrowerName`: `String`
   - `borrowerContact`: `String`
   - `loanDate`: `DateTime`
   - `expectedReturnDate`: `DateTime`
   - `returnedDate`: `DateTime?`
   - `isReturned`: `bool` (padrão `false`)
   - `notificationId`: `int?` (ID determinístico para cancelar notificação local na devolução)
   - `updatedAt`: `DateTime`
   - Getter calculado no domínio: `bool get isOverdue => !isReturned && DateTime.now().isAfter(DateTime(expectedReturnDate.year, expectedReturnDate.month, expectedReturnDate.day, 23, 59, 59));`

### 4.3 Estrutura do Cloud Firestore e Segurança (`firestore.rules`)

**Hierarquia de Coleções:**
```text
users/{uid}                         # UserProfileModel
├── books/{bookId}                  # BookModel
├── shelves/{shelfId}               # ShelfModel
├── sessions/{sessionId}            # ReadingSessionModel (campo indexado: bookId, dateKey)
├── notes/{noteId}                  # NoteModel (campo indexado: bookId, type)
└── loans/{loanId}                  # LoanModel (campo indexado: bookId, isReturned)
```

> **Por que subcoleções planas sob `users/{uid}` (e não `books/{bookId}/notes`)?**  
> Permite que `LoanRepository` observe todos os empréstimos ativos da estante em 1 única query e que `SessionRepository` agregue todas as sessões do ano para os gráficos da Home sem precisar de `collectionGroup` nem acoplar repositórios entre si.

**Regras de Segurança (`firestore.rules`) — Configurar no Console Firebase:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 4.4 Contratos das Interfaces de Repositório (`lib/domain/repositories/`)

- **`AuthRepository`**:
  - `Stream<String?> watchAuthUserId()`
  - `String? get currentUserId`
  - `String? get currentUserEmail`
  - `Future<String> signIn({required String email, required String password})`
  - `Future<String> signUp({required String name, required String email, required String password})`
  - `Future<void> resetPassword({required String email})`
  - `Future<void> signOut()`
- **`UserProfileRepository`**:
  - `Stream<UserProfileModel?> watchProfile()`
  - `Future<UserProfileModel?> getProfile()`
  - `Future<void> saveProfile(UserProfileModel profile)`
  - `Future<void> updateAnnualGoal(int goal)`
  - `Future<void> updateDailyReminder({required bool enabled, required int hour, required int minute})`
- **`BookRepository`**:
  - `Stream<List<BookModel>> watchBooks()`
  - `Stream<BookModel?> watchBookById(String bookId)`
  - `Future<List<BookModel>> getBooks()`
  - `Future<BookModel?> getBookById(String bookId)`
  - `Future<void> saveBook(BookModel book)` (create ou update)
  - `Future<void> deleteBook(String bookId)`
- **`ShelfRepository`**:
  - `Stream<List<ShelfModel>> watchShelves()`
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

### 4.5 Contratos de Rotas e Ciclo de Vida de ViewModels (`lib/core/routes/app_routes.dart`)
- `AppRoutes.auth` (`/auth`) → `AuthScreen`
- `AppRoutes.main` (`/main`) → `MainNavigationScreen`
- `AppRoutes.addBook` (`/add-book`) → `AddBookScreen` (recebe `BookModel?` opcional em `settings.arguments` para modo edição; cria `ChangeNotifierProvider<AddBookViewModel>` por tela lendo repositórios/serviços do `Provider`)
- `AppRoutes.bookDetails` (`/book-details`) → `BookDetailsScreen` (recebe `String` obrigatório `bookId` em `settings.arguments` via `onGenerateRoute`; cria `ChangeNotifierProvider<BookDetailsViewModel>` por tela e descarta no `pop`)
- `AppRoutes.tracker` (`/tracker`) → `ReadingTrackerScreen` (recebe `String?` opcional `bookId` em `settings.arguments` via `onGenerateRoute`; cria `ChangeNotifierProvider<TrackerViewModel>` por tela e descarta no `pop`)
- Rota raiz em `BookyApp`: `home: const AuthChecker()` (escuta `AuthRepository.watchAuthUserId()` / `AuthViewModel` e alterna entre `AuthScreen` e `MainNavigationScreen`).
- ViewModels das abas permanentes (`AuthViewModel`, `HomeViewModel`, `LibraryViewModel`, `ProfileViewModel`) + `ThemeController` + todos os `Services`, `Repositories` e `UseCases` são registrados em `ConfigureProviders.createDependencyTree()`.

---

## 5. Roadmap Integrado (Sprints 1 a 4)

| Sprint | Foco Principal | Natanael (Banco Firebase, Auth, Infra, Export, Perfil) | Cleiton (APIs Livros, Scanner, Biblioteca, Tracker, Home, Detalhes/OCR) | Checkpoint de Integração |
| :--- | :--- | :--- | :--- | :--- |
| **Sprint 1** | Fundação Arquitetural, Firebase & Auth | • Setup Android + `pubspec.yaml` + Firebase (`flutterfire`)<br>• Todos os Models + Interfaces de Repositories<br>• `AuthService` + `FirestoreService` + 7 Repositories<br>• `AuthChecker` + `AuthViewModel` + `AuthScreen`<br>• `ConfigureProviders`, `AppRoutes`, `ThemeController` | • `BookApiService` (Google Books + Open Library + testes HTTP)<br>• `OcrService` (`image_picker` + ML Kit)<br>• Preparar ViewModels/Fakes contra os contratos da Seção 4 | **Marco 1:** Login/Cadastro funcional no Firebase, `AuthChecker` roteando para `MainNavigationScreen` e `BookRepository` lendo/gravando no Firestore. |
| **Sprint 2** | Catalogação, Estante, Empréstimos & Diário | • `NotificationService` (agendamento + cancelamento + permissões)<br>• `DeleteBookUseCase` (exclusão em cascata no Firestore)<br>• Apoio/ajustes de índices ou regras Firestore se necessário | • `AddBookViewModel` + `AddBookScreen` (`mobile_scanner` + form completo)<br>• `LibraryViewModel` + `LibraryScreen` (estantes, tags, busca avançada, badges empréstimo/atraso)<br>• `RegisterLoanUseCase` + `ReturnLoanUseCase`<br>• `BookDetailsViewModel` + `BookDetailsScreen` (3 abas, OCR, empréstimos) | **Marco 2:** Fluxo completo cadastrar livro (ISBN/manual) → listar/filtrar → abrir detalhes → registrar notas/citações OCR/resenha → emprestar e devolver. |
| **Sprint 3** | Rastreador, Estatísticas, Meta & Exportação | • `ExportService` (PDF Unicode + CSV UTF-8 + `share_plus`)<br>• `ExportLibraryUseCase`<br>• `ProfileViewModel` + `ProfileScreen` (Meta anual, Lembrete diário, Exportação, Status nuvem/offline) | • `SaveReadingSessionUseCase`<br>• `TrackerViewModel` + `ReadingTrackerScreen` (cronômetro background, pág/%, estimativa, histórico diário)<br>• `GetDashboardStatsUseCase`<br>• `HomeViewModel` + `HomeScreen` (leitura atual, atrasos, `fl_chart` livros e páginas/mês, meta anual) | **Marco 3:** Sessão salva no Tracker atualiza progresso na Home, gráficos `fl_chart` refletem dados do Firestore e exportação PDF/CSV compartilha arquivos reais. |
| **Sprint 4** | Testes, Auditoria Visual & Entrega | • Testes unitários (`Models`, `AuthViewModel`, `ExportService`, `ExportLibraryUseCase`, `DeleteBookUseCase`)<br>• Auditoria Light/Dark (`Auth`, `Profile`)<br>• `firestore.rules` publicadas + validação multi-dispositivo + `flutter build apk --release` | • Testes unitários (`BookApiService`, `LibraryViewModel`, `SaveReadingSessionUseCase`, `TrackerViewModel`, `RegisterLoanUseCase`)<br>• Auditoria Light/Dark (`Home`, `Library`, `AddBook`, `BookDetails`, `Tracker`)<br>• Validação modo avião (offline-first Firestore) | **Marco Final:** `flutter analyze` limpo, `flutter test` passando 100%, APK validado em dispositivo físico. |

---

## 6. Fluxo de Trabalho Git e Anti-Conflitos

1. **Branches por Issue:** Nunca commitar direto na `main`. Padrão: `feat/n01-models-contracts`, `feat/c01-book-api-service`, etc.
2. **Isolamento de pastas:** Respeitar rigorosamente os donos `[NATANAEL]` e `[CLEITON]` da Seção 3.
3. **Ordem na Sprint 1:** Natanael abre e faz merge primeiro da **ISSUE-N01 + ISSUE-N02** (dependências + modelos + interfaces) para que Cleiton já puxe as classes de domínio reais na `main`.
4. **Conventional Commits:** `feat:`, `fix:`, `refactor:`, `test:`, `docs:`.
5. **Code Review Cruzado:** Todo PR é revisado pelo outro integrante antes do merge na `main`.
