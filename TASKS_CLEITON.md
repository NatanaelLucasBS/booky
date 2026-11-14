# Roadmap e Issues — CLEITON (APIs, Scanner, Biblioteca, Rastreador, Home/Gráficos & Detalhes/OCR)

> **Leia primeiro:** [`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md)  
> **Seu Domínio:** Todas as funcionalidades de leitura do Tema 6: **Catalogação (`library` + Google Books/Open Library + Scanner ISBN)**, **Rastreador (`tracker` + Cronômetro + Estimativa)**, **Dashboard (`home` + Gráficos `fl_chart`)** e **Detalhes do Livro (`book_details` + Empréstimos + Citações/Resenha + OCR)**.

---

## Como a Camada de Dados Funciona (Leia Antes de Programar ou Usar IA)

1. **Persistência 100% Abstraída:** Você **não** precisa configurar banco de dados! O Natanael fornece os 7 `Repositories` prontos na camada de dados com persistência abstraída.
2. **Como suas telas leem e gravam dados (seguindo `Aula_24_-_Arqutietura_Recomendada.pdf`):**
   - **Views (`Screens` / `Widgets` — Slides 6, 15, 16):** nunca acessam `Service` ou banco de dados e nunca contêm regra de negócio. Apenas observam o ViewModel (`context.watch<MeuViewModel>()`) e disparam comandos (`context.read<MeuViewModel>()`).
   - **ViewModels (`ChangeNotifier`, relação 1:1 por tela — Slides 15, 18):** consomem os **Repositories** criados pelo Natanael (`BookRepository`, `ShelfRepository`, `SessionRepository`, `NoteRepository`, `LoanRepository`, `UserProfileRepository`) ou **UseCases** (`lib/domain/use_cases/`).
   - **UseCases (Camada de Domínio — Slides 7, 23, 27):** como um `Repository` **nunca** pode depender de outro `Repository` (Slide 23), sempre que uma ação precisar coordenar mais de um repositório ou serviço (ex.: salvar sessão e atualizar o livro; registrar empréstimo e agendar notificação; consolidar estatísticas da Home), usamos um `UseCase` em `lib/domain/use_cases/`.
   - **SSOT Reativo (Slides 4, 22):** Os repositórios já retornam `Stream<List<...>>` como Fonte Única de Verdade. Qualquer alteração feita em `BookDetails` ou `Tracker` atualiza automaticamente `Library` e `Home`.
3. **Nunca edite pastas do Natanael:** Não altere `lib/data/repositories/**`, `lib/data/services/{storage,backup_sync,export,notification}_service.dart`, `lib/features/auth/**`, `lib/features/profile/**`, `android/` nem `pubspec.yaml` sem alinhar via PR.
4. **Como trabalhar em paralelo na Sprint 1:** Assim que Natanael concluir `ISSUE-N01` e `ISSUE-N02` (pacotes + modelos + interfaces), você já trabalha livremente criando `BookApiService`, `OcrService` e seus ViewModels/UseCases usando os contratos oficiais da **Seção 4 do `PLANO_DESENVOLVIMENTO.md`** (e fakes em memória nos testes).

---

## Sprint 1 — Serviços de Livros (HTTP) e OCR Local

### `ISSUE-C01` — `BookApiService` (Google Books API + Fallback Open Library API)
- **Branch:** `feat/c01-book-api-service`
- **Depende de:** `ISSUE-N01` e `ISSUE-N02` (`http` e `BookModel`)
- **Arquivos a criar:**
  - `lib/data/services/book_api_service.dart`
- **Checklist Técnico:**
  - [ ] Criar classe `BookLookupResult` contendo: `isbn`, `title`, `author`, `publisher`, `publishedYear`, `genre`, `synopsis`, `coverUrl`, `totalPages`.
  - [ ] Normalizar o ISBN recebido (remover `-`, espaços; validar 10 ou 13 dígitos).
  - [ ] Implementar consulta primária na **Google Books API**:
    - `GET https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}` (timeout 10s).
    - Extrair `title`, `authors.join(', ')`, `publisher`, `publishedDate` (4 primeiros dígitos para `publishedYear`), `categories.first` para `genre`, `description` para `synopsis`, `pageCount` para `totalPages`, `imageLinks.thumbnail` (converter `http://` para `https://`).
  - [ ] Implementar **fallback automático** na **Open Library API** caso o Google Books retorne vazio ou incompleto:
    - `GET https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&jscmd=data&format=json` (e `/isbn/{isbn}.json` / `/works/...` caso necessário para sinopse) preenchendo os campos faltantes.
  - [ ] Permitir injetar `http.Client` no construtor (`BookApiService({http.Client? client})`) para viabilizar testes unitários na Sprint 4.
  - [ ] Tratar falha de rede/timeout com exceção amigável para o ViewModel exibir.
- **Critérios de Aceite:** Service *stateless* (Slide 25 da `Aula_24`); ISBN válido preenche os campos; ISBN inexistente retorna `null`; offline lança erro tratado sem crash.

---

### `ISSUE-C02` — `OcrService` (Extração de Texto da Página Física via Câmera)
- **Branch:** `feat/c02-ocr-service`
- **Depende de:** `ISSUE-N01` (`image_picker` + `google_mlkit_text_recognition`)
- **Arquivos a criar:**
  - `lib/data/services/ocr_service.dart`
- **Checklist Técnico:**
  - [ ] Service **stateless** encapsulando `ImagePicker` e `TextRecognizer(script: TextRecognitionScript.latin)`.
  - [ ] Expor `Future<String?> extractTextFromImage({required ImageSource source})`:
    - Abre câmera ou galeria (`pickImage`). Se cancelar, retorna `null`.
    - Executa `processImage(InputImage.fromFilePath(xfile.path))`.
    - Normaliza espaços excessivos mantendo o texto legível.
    - Deletar o arquivo temporário da foto após extrair o texto (`File(xfile.path).delete()`) e chamar `close()` no `TextRecognizer`.
- **Critérios de Aceite:** Fotografar uma página física retorna o texto em português 100% no dispositivo sem deixar imagens residuais.

---

## Sprint 2 — Catalogação, Estante/Busca Avançada, Empréstimos & Diário com OCR

### `ISSUE-C03` — `AddBookViewModel` + `AddBookScreen` (Scanner ISBN + Cadastro/Edição Completa)
- **Branch:** `feat/c03-add-book-scanner`
- **Depende de:** `ISSUE-C01`, `ISSUE-N04`, `ISSUE-N05`
- **Arquivos a criar/editar:**
  - `lib/features/library/presentation/viewmodels/add_book_viewmodel.dart`
  - `lib/features/library/presentation/screens/add_book_screen.dart`
- **Checklist Técnico:**
  - [ ] Criar `AddBookViewModel extends ChangeNotifier` (relação 1:1 com `AddBookScreen`) consumindo `BookRepository`, `ShelfRepository` e `BookApiService`.
  - [ ] Corrigir os chips de status em `add_book_screen.dart`: substituir `'Emprestado'` por **`Abandonado`** (os 4 status oficiais do Tema 6 são: `Quero Ler`, `Lendo`, `Lido`, `Abandonado` — *Emprestado não é status!*).
  - [ ] Integrar câmera real na aba **ESCANEAR CÓDIGO** usando `mobile_scanner`:
    - Manter a moldura editorial já desenhada na tela.
    - **Trava/debounce de leitura:** ao capturar um ISBN válido, pausar o scanner, chamar `AddBookViewModel.lookupByIsbn(isbn)` com feedback de carregamento e mudar automaticamente para a aba **CADASTRO MANUAL** com o formulário preenchido.
    - Tratar permissão de câmera negada com mensagem clara e opção de ir direto ao cadastro manual.
  - [ ] Expandir o formulário manual com **todos os campos exigidos pelo Tema 6**:
    - Pré-visualização da capa (`coverUrl` com fallback editorial se vazia/offline) + campo opcional de URL da capa.
    - `ISBN`, `Título` (obrigatório), `Autor`, `Editora`, `Ano de Publicação`, `Total de Páginas`, `Gênero Literário`, `Sinopse`.
    - Seletor de **Formato**: `Físico` (`BookFormat.physical`) ou `Digital` (`BookFormat.digital`).
    - Seletor de **Status** (4 opções) + seleção/criação de **Estantes Temáticas** (`ShelfRepository`) + chips de **Tags customizadas**.
  - [ ] Suportar **Modo Edição** quando receber `BookModel? bookToEdit` pela rota `AppRoutes.addBook`.
  - [ ] Ao salvar: gerar UUID caso seja novo livro; preencher `startedAt` se status for `reading`; preencher `finishedAt` e `currentPage = totalPages` se status for `read`.
- **Critérios de Aceite:** Escanear código de barras (ou digitar ISBN) preenche todos os campos via API, permite revisar e salva no `BookRepository`.

---

### `ISSUE-C04` — `LibraryViewModel` + `LibraryScreen` (Estantes, Tags, Badges de Empréstimo & Busca Avançada)
- **Branch:** `feat/c04-library-advanced-search`
- **Depende de:** `ISSUE-N04`, `ISSUE-N05`
- **Arquivos a criar/editar:**
  - `lib/features/library/presentation/viewmodels/library_viewmodel.dart`
  - `lib/features/library/presentation/screens/library_screen.dart`
  - `lib/features/library/presentation/widgets/advanced_filter_sheet.dart`
  - `lib/features/library/presentation/widgets/shelves_manager_sheet.dart`
- **Checklist Técnico:**
  - [ ] Criar `LibraryViewModel extends ChangeNotifier` observando os streams de `BookRepository`, `LoanRepository` e `ShelfRepository`.
  - [ ] Remover a lista hardcoded `_allBooks` e contadores falsos de `library_screen.dart` — calcular contadores reais dinamicamente no ViewModel.
  - [ ] Chips de filtro rápido: `Todos`, `Lendo`, `Lidos`, `Quero Ler`, `Abandonado`, `Emprestados`, `Atrasados`.
  - [ ] Gerenciamento de **Estantes Temáticas** (`shelves_manager_sheet.dart` usando `ShelfRepository`: listar, criar, editar, excluir estante e filtrar livros pela estante selecionada).
  - [ ] **Modal de Busca Avançada (`advanced_filter_sheet.dart`):** filtros combinados (`AND`) por **Autor**, **Gênero**, **Ano**, **Status**, **Avaliação mínima (1–5★)**, **Estante** e **Tags**, exibindo contador de filtros ativos e botão *Limpar*.
  - [ ] **Cards da Estante:** exibir capa real (`Image.network` com placeholder editorial quando sem URL/offline), estrelas de avaliação quando houver, e badge de empréstimo derivada do `LoanRepository`:
    - `EMPRESTADO` (empréstimo ativo no prazo)
    - `ATRASADO` com destaque visual (quando `loan.isOverdue == true`)
  - [ ] Ao tocar em um livro, navegar para `AppRoutes.bookDetails` passando `arguments: book.id`.
- **Critérios de Aceite:** Busca avançada combina múltiplos critérios; badges de emprestado/atrasado refletem o estado real dos empréstimos.

---

### `ISSUE-C05` — UseCases de Empréstimo + `BookDetailsViewModel` & `BookDetailsScreen` (Diário, OCR & Empréstimos)
- **Branch:** `feat/c05-book-details-loans-ocr`
- **Depende de:** `ISSUE-C02`, `ISSUE-N04`, `ISSUE-N05`, `ISSUE-N06`
- **Arquivos a criar/editar:**
  - `lib/domain/use_cases/register_loan_use_case.dart`
  - `lib/domain/use_cases/return_loan_use_case.dart`
  - `lib/features/book_details/presentation/viewmodels/book_details_viewmodel.dart`
  - `lib/features/book_details/presentation/screens/book_details_screen.dart`
  - `lib/features/book_details/presentation/widgets/loan_dialog.dart`
  - `lib/features/book_details/presentation/widgets/note_editor_dialog.dart`
- **Checklist Técnico:**
  - [ ] **`RegisterLoanUseCase`**:
    - Recebe `LoanRepository` e `NotificationService` (criado pelo Natanael na `ISSUE-N06`).
    - Valida se já não existe empréstimo ativo (`!isReturned`) para o `bookId` e se `expectedReturnDate >= loanDate`.
    - Cria `LoanModel` com UUID + `notificationId` determinístico (`id.hashCode.abs() & 0x7FFFFFFF`), salva no `LoanRepository` e agenda lembrete em `NotificationService.scheduleLoanReturnReminder(...)`.
  - [ ] **`ReturnLoanUseCase`**:
    - Marca o empréstimo ativo com `isReturned = true`, `returnedDate = DateTime.now()` e chama `NotificationService.cancelNotification(...)`.
  - [ ] **`BookDetailsViewModel extends ChangeNotifier`**:
    - Observa `BookRepository.watchBookById(bookId)`, `NoteRepository.watchNotesByBook(bookId)` e `LoanRepository.watchLoansByBook(bookId)`.
    - Expõe comandos para alterar status/avaliação (`1..5★`), criar/editar/excluir notas/citações/resenhas, extrair texto via `OcrService`, registrar/devolver empréstimo e excluir livro (`DeleteBookUseCase`).
  - [ ] **Atualizar `BookDetailsScreen` (dados reais):**
    - Capa, título, autor, editora, ano, páginas, formato (`Físico`/`Digital`), estantes, tags, progresso real e botão *Continuar Leitura* abrindo `AppRoutes.tracker` com `arguments: book.id`.
    - Ações no `AppBar`: *Editar* (`AppRoutes.addBook` com `arguments: book`) e *Excluir* (com confirmação).
    - **Card e Diálogo de Empréstimo (`loan_dialog.dart`):** coletar **Nome do amigo**, **Contato (telefone/e-mail)**, **Data do empréstimo** e **Data prevista de devolução**; destacar alerta visual quando `loan.isOverdue` e exibir histórico de empréstimos devolvidos.
    - **Diário com 3 Abas:** `Anotações`, `Citações` e `Resenha` (incluindo avaliação por 1–5 estrelas).
    - **Editor de Anotação/Citação (`note_editor_dialog.dart`):** respeita o `NoteType` da aba ativa, permite informar **Capítulo** e **Página**, e possui botão **"Capturar Texto (OCR)"** que chama `OcrService` (câmera ou galeria) e preenche o campo de texto editável antes de salvar.
- **Critérios de Aceite:** Empréstimo completo com alerta visual de atraso + notificação agendada/cancelada; 3 abas do diário + OCR funcionando; edição e exclusão do livro funcionando.

---

## Sprint 3 — Rastreador de Sessões, Dashboard & Gráficos Estatísticos

### `ISSUE-C06` — `SaveReadingSessionUseCase`, `TrackerViewModel` & `ReadingTrackerScreen`
- **Branch:** `feat/c06-reading-tracker`
- **Depende de:** `ISSUE-N04`, `ISSUE-N05`
- **Arquivos a criar/editar:**
  - `lib/domain/use_cases/save_reading_session_use_case.dart`
  - `lib/features/tracker/presentation/viewmodels/tracker_viewmodel.dart`
  - `lib/features/tracker/presentation/screens/reading_tracker_screen.dart`
- **Checklist Técnico:**
  - [ ] **`SaveReadingSessionUseCase`** (combina `SessionRepository` + `BookRepository` sem acoplar repositórios — Slide 23 e 27):
    - Recebe `book`, `startTime`, `durationSeconds`, `startPage`, `endPage`.
    - Calcula `pagesRead = max(0, endPage - startPage)` e `dateKey = YYYY-MM-DD`.
    - Grava `ReadingSessionModel` no `SessionRepository`.
    - Atualiza `BookModel`: `currentPage = endPage`, `startedAt ??= startTime`; se `totalPages > 0 && endPage >= totalPages`, promove para `BookStatus.read` e preenche `finishedAt = DateTime.now()`; se estava `wantToRead` e `endPage > 0`, promove para `BookStatus.reading`.
  - [ ] **`TrackerViewModel extends ChangeNotifier`**:
    - Carrega livro pelo `bookId` (ou permite selecionar um livro em `reading` caso `bookId == null`).
    - **Cronômetro preciso em segundo plano:** usa `DateTime? _runningSince` + `int _accumulatedSeconds` + `WidgetsBindingObserver` para manter contagem real mesmo quando o app é minimizado.
    - **Atualização por página OU porcentagem (%):** suportar `-` / `+`, digitação direta da página **e** entrada por porcentagem (`0..100%`) sincronizados entre si (`page = ((pct / 100) * totalPages).round().clamp(0, totalPages)`).
    - **Velocidade e Estimativa de Tempo Restante:** calcular `pagesPerHour` com base nas sessões do livro (ou média global do usuário como fallback); estimar tempo restante tratando `totalPages == 0` ou velocidade `0` sem gerar `NaN`/`Infinity`.
    - Expor **histórico diário** das sessões agrupadas por `dateKey` (total de páginas e duração por dia).
  - [ ] Conectar `reading_tracker_screen.dart` ao `TrackerViewModel` (remover valores hardcoded de tempo e livro).
- **Critérios de Aceite:** Cronômetro mantém tempo exato após minimizar app; alternar entre página e `%` atualiza corretamente; salvar sessão atualiza progresso, histórico diário e estimativa de conclusão.

---

### `ISSUE-C07` — `GetDashboardStatsUseCase`, `HomeViewModel` & `HomeScreen` (`fl_chart`)
- **Branch:** `feat/c07-home-dashboard-charts`
- **Depende de:** `ISSUE-N04`, `ISSUE-N05`, `ISSUE-C06`
- **Arquivos a criar/editar:**
  - `lib/domain/use_cases/get_dashboard_stats_use_case.dart`
  - `lib/features/home/presentation/viewmodels/home_viewmodel.dart`
  - `lib/features/home/presentation/screens/home_screen.dart`
  - `lib/features/home/presentation/screens/main_navigation_screen.dart`
  - `lib/features/home/presentation/widgets/reading_charts_section.dart`
- **Checklist Técnico:**
  - [ ] **`GetDashboardStatsUseCase`**: combina `BookRepository`, `SessionRepository`, `LoanRepository` e `UserProfileRepository` (sem dependência entre repositórios!) calculando `DashboardStats`:
    - Nome e iniciais reais do leitor + `annualReadingGoal`
    - `booksReadThisYear` (via `finishedAt.year == currentYear`), `booksReadingNow`, `goalPercent`
    - `currentReadingBook` (último livro em leitura atualizado)
    - Lista `overdueLoans` (empréstimos com `isOverdue == true` + título do livro)
    - Séries mensais (12 meses do ano atual): `booksReadPerMonth` (via `finishedAt`) e `pagesReadPerMonth` (via `ReadingSessionModel.pagesRead` e `dateKey`).
  - [ ] **`HomeViewModel extends ChangeNotifier`**: reage aos streams para atualizar a Home em tempo real e alternar modo do gráfico (*Páginas/mês* vs *Livros/mês*).
  - [ ] **Atualizar `HomeScreen`:**
    - Saudação com nome/iniciais reais (remover `"Olá, Arthur"`).
    - Faixa de estatísticas reais + card *Leitura Atual* clicável (abrindo `BookDetailsScreen` com `book.id` e botão *Continuar Leitura* abrindo `ReadingTrackerScreen` com `book.id`), com estado vazio amigável se não houver leitura em andamento.
    - Banner de alerta para **empréstimos atrasados** (clicável para abrir os detalhes do livro).
    - Gráficos interativos com **`fl_chart`** (`reading_charts_section.dart`) usando exclusivamente a paleta `AppColors` (Claro e Escuro): **livros e páginas lidas por mês** + progresso visual da **meta anual**.
  - [ ] Coordenar com Natanael a limpeza de `MainNavigationScreen` após `ProfileScreen` consumir `ThemeController` direto do `Provider`.
- **Critérios de Aceite:** Dashboard e gráficos refletem fielmente sessões salvas, livros concluídos, meta anual editada no Perfil e empréstimos atrasados.

---

## Sprint 4 — Testes Unitários, Auditoria Visual & Validação E2E

### `ISSUE-C08` — Testes Unitários de API, Busca Avançada, Rastreador, Dashboard & Empréstimos
- **Branch:** `test/c08-unit-tests-cleiton`
- **Arquivos a criar:**
  - `test/fakes/fake_repositories.dart`
  - `test/data/book_api_service_test.dart`
  - `test/features/library/library_viewmodel_test.dart`
  - `test/domain/save_reading_session_use_case_test.dart`
  - `test/features/tracker/tracker_viewmodel_test.dart`
  - `test/domain/get_dashboard_stats_use_case_test.dart`
  - `test/domain/register_loan_use_case_test.dart`
- **Checklist Técnico:**
  - [ ] `BookApiService` com `MockClient`: resposta Google Books, fallback Open Library, erro HTTP/timeout.
  - [ ] `LibraryViewModel`: filtros combinados (`autor + gênero + ano + status + avaliação + estante + tag`) e `Emprestados` / `Atrasados`.
  - [ ] `SaveReadingSessionUseCase`: cálculo de `pagesRead`, atualização de `currentPage` e transição automática para `BookStatus.read`.
  - [ ] `TrackerViewModel`: sincronia página ↔ `%` e estimativa de tempo restante (inclusive `totalPages == 0`).
  - [ ] `GetDashboardStatsUseCase`: agregação mensal por `finishedAt` e `dateKey`.
  - [ ] `RegisterLoanUseCase`: bloqueio de segundo empréstimo ativo no mesmo livro.

---

### `ISSUE-C09` — Auditoria Visual (Light/Dark Mode) e Teste E2E Offline/Online
- **Branch:** `fix/c09-ui-offline-audit`
- **Checklist Técnico:**
  - [ ] Validar `HomeScreen`, `LibraryScreen`, `AddBookScreen`, `BookDetailsScreen` e `ReadingTrackerScreen` em **Modo Claro** e **Modo Escuro** respeitando `AppColors`.
  - [ ] Testar fluxo completo com e sem internet: cadastrar livro (ISBN via API e manual), criar estante/tag, rodar sessão no Tracker, extrair citação via OCR e registrar/devolver empréstimo.
  - [ ] Confirmar `flutter analyze` e `flutter test` passando 100%.
