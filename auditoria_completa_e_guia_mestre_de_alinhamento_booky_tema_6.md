# Auditoria Completa e Guia Mestre de Alinhamento — Projeto BOOKY (Tema 6)

> **Disciplina:** Programação para Dispositivos Móveis (2026.2 — UFRN)  
> **Professor:** Taniro Chacon Rodrigues  
> **Tema:** 6. App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Equipe:** Natanael & Cleiton  
> **Status Geral do Projeto:** **98% Concluído** (Pendências pontuais de fechamento de rotas `ISSUE-N07` e alinhamento de DDL SQLite)  
> **Documentos Oficiais de Referência:**
> - `Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf` (Tema 6, pág. 7)
> - `Aula_24_-_Arqutietura_Recomendada.pdf` (MVVM + UDF + SSOT + Layered Architecture)
> - `PLANO_DESENVOLVIMENTO.md` | `TASKS_NATANAEL.md` | `TASKS_CLEITON.md` | `README.md`

---

## 1. Propósito deste Documento (Leitura Obrigatória para Devs e IAs)

Como o arquivo `AGENTS.md` foi removido do repositório, **este documento em conjunto com o `PLANO_DESENVOLVIMENTO.md` constitui a Fonte Única de Verdade (SSOT) de regras arquiteturais, contratos de código e estado de entrega** para qualquer desenvolvedor ou agente de IA (Natanael ou Cleiton) que atuar neste repositório.

---

## 2. Regras Invioláveis de Arquitetura e Escopo (Anti-Alucinação)

Qualquer código gerado ou modificado no repositório **DEVE** obedecer rigorosamente às 6 regras abaixo:

1. **100% Offline-First (ZERO Firebase / ZERO Login):**
   - O projeto **não** possui autenticação (`auth/`), perfil de usuário (`profile/`) nem backend Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`). **Nunca** adicione esses pacotes ou telas.
   - A persistência é totalmente abstraída atrás da interface `StorageService` (`lib/data/services/storage_service.dart`), e a portabilidade de dados entre dispositivos é feita via snapshot JSON (`BackupSyncService`).
2. **Isolamento Estrito de Pastas (Anti-Conflito de Merge):**
   - **Domínio Natanael:** `lib/core/**`, `lib/domain/models/**`, `lib/domain/repositories/**`, `lib/data/repositories/**`, `lib/data/services/{storage,backup_sync,notification,export}_service.dart`, `lib/domain/use_cases/{delete_book,export_library}_use_case.dart`, `android/**`, `pubspec.yaml`.
   - **Domínio Cleiton:** `lib/data/services/{book_api,ocr}_service.dart`, `lib/domain/use_cases/{save_reading_session,get_dashboard_stats,register_loan,return_loan}_use_case.dart`, `lib/features/{home,library,tracker,book_details}/**`.
3. **Leis da `Aula_24` (Arquitetura Oficial Flutter):**
   - **View (`Screens` / `Widgets` — Slides 6, 15, 16):** Zero regra de negócio, zero acesso direto a `Service` ou chamadas `http`. Apenas observa `context.watch<ViewModel>()` e dispara comandos `context.read<ViewModel>()`.
   - **ViewModel (`ChangeNotifier` — Slides 15, 18):** Relação estrita **1:1** com sua View (`HomeScreen` ↔ `HomeViewModel`, `LibraryScreen` ↔ `LibraryViewModel`, `AddBookScreen` ↔ `AddBookViewModel`, `BookDetailsScreen` ↔ `BookDetailsViewModel`, `ReadingTrackerScreen` ↔ `TrackerViewModel`).
   - **Repository (SSOT — Slides 8, 22, 23):** Fonte Única de Verdade reativa (`Stream`) para 1 entidade. **PROIBIDO um `Repository` importar ou depender de outro `Repository` (Slide 23).**
   - **UseCase (`lib/domain/use_cases/` — Slides 7, 23, 27):** Obrigatório sempre que uma operação precisar coordenar múltiplos `Repositories` ou combinar `Repository` + `Service`.
   - **Service (`lib/data/services/` — Slide 25):** Camada mais baixa, **100% stateless**.
4. **Congelamento de Contratos:** Não renomeie models, enums (`BookStatus`, `BookFormat`, `NoteType`), métodos de repositórios ou constantes de rotas (`AppRoutes`).
5. **Paleta de Cores Estrita (`AppColors`) & Estética Editorial:** Utilize exclusivamente os 5 tons definidos em `lib/core/theme/app_colors.dart` (`darkBrown`, `woodBrown`, `mediumBrown`, `beige`, `lightCream`), preservando bordas finas (`1.0px`), cantos (`borderRadius: BorderRadius.circular(4)`) e tipografia serifada em Light e Dark Mode.

---

## 3. Auditoria Completa: Requisitos Oficiais do Tema 6 vs. Implementação

| Requisito Oficial (PDF Tema 6 — Pág. 7) | Issues Vinculadas | Status | Análise Técnica Detalhada |
| :--- | :--- | :--- | :--- |
| **RF1 — Catalogação por ISBN (Scanner + API):**<br>Cadastro manual ou leitura de código de barras ISBN pela câmera, buscando capa, título, autor, sinopse, editora e páginas via Google Books ou Open Library. | `ISSUE-C01`<br>`ISSUE-C03` | **CUMPRIDO** | `BookApiService` consulta Google Books com fallback automático para Open Library e injeta `http.Client` para testes. `AddBookScreen` usa `mobile_scanner` com trava/debounce de frame e preenche o formulário para revisão antes de salvar. |
| **RF2 — Organização por Estantes e Status:**<br>Classificação por status (*Quero Ler, Lendo, Lido, Abandonado*), avaliação pessoal, tags customizadas e estantes temáticas. | `ISSUE-N02`<br>`ISSUE-N04`<br>`ISSUE-C03`<br>`ISSUE-C04` | **CUMPRIDO** | Enums oficiais (`wantToRead`, `reading`, `read`, `abandoned`) + formato (`physical`, `digital`). *Emprestado* não polui o status de leitura (é derivado de `LoanModel`). Avaliação (`0..5★`), tags normalizadas e estantes temáticas N:N via `ShelfRepository`. |
| **RF3 — Rastreador de Progresso e Sessões:**<br>Cronômetro de leitura e atualização da página atual ou % concluída, histórico diário de páginas lidas e estimativa de tempo para terminar. | `ISSUE-C06` | **CUMPRIDO** | `TrackerViewModel` usa timestamp (`_runningSince` + `_accumulatedSeconds` + `WidgetsBindingObserver`) para não perder tempo em segundo plano. Sincroniza página ↔ `%`, agrupa histórico por `dateKey` (`YYYY-MM-DD`) e calcula `pagesPerHour` sem risco de `NaN`/`Infinity`. |
| **RF4 — Diário de Citações e Resenhas (com OCR):**<br>Registro de anotações, resenhas e trechos favoritos de cada livro, com suporte a OCR via câmera para extrair texto da página física. | `ISSUE-C02`<br>`ISSUE-C05` | **CUMPRIDO** | `BookDetailsScreen` possui 3 abas (`Anotações`, `Citações`, `Resenha` + estrelas). `OcrService` usa `image_picker` + `google_mlkit_text_recognition` (`TextRecognitionScript.latin`) 100% offline e apaga a imagem temporária após extração. |
| **RF5 — Controle de Empréstimos:**<br>Registro de livros emprestados (nome do amigo, contato, data do empréstimo e data prevista de devolução) com alerta de atraso. | `ISSUE-N06`<br>`ISSUE-C05` | **CUMPRIDO** | `RegisterLoanUseCase` impede >1 empréstimo ativo por livro, valida datas e agenda lembrete em `NotificationService`. `ReturnLoanUseCase` registra devolução e cancela a notificação. Alerta visual `ATRASADO` (`LoanModel.isOverdue`) exibido nos cards e na Home. |
| **RF6 — Busca Avançada e Estatísticas:**<br>Filtros combinados por autor, gênero, ano, status ou avaliação, além de gráficos de livros/páginas lidas por mês e meta anual de leitura. | `ISSUE-C04`<br>`ISSUE-C07` | **CUMPRIDO** | `LibraryViewModel` filtra com lógica `AND` combinando autor, gênero, ano, status, avaliação mínima, estante e tags. `HomeScreen` usa `fl_chart` com dados reais (`finishedAt` para livros/mês e `dateKey` para páginas/mês) + meta anual editável. |
| **RF7 — Backup e Exportação:**<br>Sincronização em nuvem entre dispositivos e exportação do catálogo completo ou lista de desejos em PDF e CSV. | `ISSUE-N08` | **ADAPTADO (VALIDAR)** | `ExportService` + `ExportLibraryUseCase` geram PDF (com fonte `.ttf` Unicode PT-BR) e CSV (BOM UTF-8) para *Catálogo Completo* ou *Lista de Desejos* via `share_plus`. **Ponto de atenção:** a nuvem foi substituída por backup/restore JSON local (`BackupSyncService`) devido ao escopo 100% offline. **Validar com o professor** se a portabilidade via JSON atende ao critério. |

---

## 4. Auditoria Geral dos Backlogs (`TASKS_NATANAEL.md` & `TASKS_CLEITON.md`)

### 4.1. Backlog Natanael (`ISSUE-N01` a `ISSUE-N11`)
- `ISSUE-N01` (Setup Android, `pubspec.yaml`, `Command`): `[x]` Concluído
- `ISSUE-N02` (Models e Interfaces de Repositórios): `[x]` Concluído
- `ISSUE-N03` (`StorageService` Abstraído): `[x]` Concluído
- `ISSUE-N04` (6 Repositórios SSOT + `DeleteBookUseCase`): `[x]` Concluído
- `ISSUE-N05` (`ThemeController`, `AppRoutes`, `ConfigureProviders`): `[x]` Concluído
- `ISSUE-N06` (`NotificationService`): `[x]` Concluído
- **`ISSUE-N07` (Atualização do `ConfigureProviders` e `AppRoutes` Sprint 2):** **PENDENTE (2 itens abertos)**
  - `[x]` Registrar `BookApiService`, `OcrService`, `NotificationService`, `RegisterLoanUseCase`, `ReturnLoanUseCase` no `ConfigureProviders`.
  - `[ ]` **PENDÊNCIA 1:** Em `AppRoutes.onGenerateRoute`, instanciar `ChangeNotifierProvider` com escopo de tela para `AddBookViewModel` (`bookToEdit`) e `BookDetailsViewModel` (`bookId`).
  - `[ ]` **PENDÊNCIA 2:** Validar navegação ponta-a-ponta `LibraryScreen` → `AddBookScreen` e `LibraryScreen` → `BookDetailsScreen(bookId)`.
- `ISSUE-N08` (`ExportService` PDF/CSV, `ExportLibraryUseCase`, `BackupSyncService`): `[x]` Concluído
- `ISSUE-N09` (Integração DI Sprint 3 + `AppRoutes.tracker`): `[x]` Concluído
- `ISSUE-N10` (Testes Unitários Domínio/Repositórios/Export): `[x]` Concluído
- `ISSUE-N11` (Auditoria Visual, Docs, DDL SQLite e Config Android APK): `[x]` Concluído *(requer ajuste no DDL SQLite descrito na Seção 5.2)*

### 4.2. Backlog Cleiton (`ISSUE-C01` a `ISSUE-C09`)
- `ISSUE-C01` (`BookApiService` Google Books + Open Library): `[x]` Concluído
- `ISSUE-C02` (`OcrService` ML Kit): `[x]` Concluído
- `ISSUE-C03` (`AddBookViewModel` + `AddBookScreen` + Scanner ISBN): `[x]` Concluído
- `ISSUE-C04` (`LibraryViewModel` + `LibraryScreen` + Busca Avançada + Estantes): `[x]` Concluído
- `ISSUE-C05` (`RegisterLoanUseCase`, `ReturnLoanUseCase`, `BookDetailsViewModel` + `BookDetailsScreen`): `[x]` Concluído
- `ISSUE-C06` (`SaveReadingSessionUseCase`, `TrackerViewModel` + `ReadingTrackerScreen`): `[x]` Concluído
- `ISSUE-C07` (`GetDashboardStatsUseCase`, `HomeViewModel` + `HomeScreen` + `fl_chart`): `[x]` Concluído
- `ISSUE-C08` (Testes Unitários API, Biblioteca, Tracker, Home, Empréstimos): `[x]` Concluído
- `ISSUE-C09` (Auditoria Visual Light/Dark e Teste E2E): `[x]` Concluído

---

## 5. Plano de Ação Concreto: O que Ajeitar Agora

### Ação 1 — Fechar `ISSUE-N07` em `lib/core/routes/app_routes.dart` (Código)
Garantir que todas as rotas parametrizadas criem seus ViewModels com escopo de tela via `ChangeNotifierProvider`:

```dart
case AppRoutes.addBook:
  final bookToEdit = settings.arguments as BookModel?;
  return MaterialPageRoute(
    builder: (context) => ChangeNotifierProvider(
      create: (_) => AddBookViewModel(
        bookRepository: context.read<BookRepository>(),
        shelfRepository: context.read<ShelfRepository>(),
        bookApiService: context.read<BookApiService>(),
        bookToEdit: bookToEdit,
      ),
      child: const AddBookScreen(),
    ),
  );

case AppRoutes.bookDetails:
  final bookId = settings.arguments as String;
  return MaterialPageRoute(
    builder: (context) => ChangeNotifierProvider(
      create: (_) => BookDetailsViewModel(
        bookId: bookId,
        bookRepository: context.read<BookRepository>(),
        noteRepository: context.read<NoteRepository>(),
        loanRepository: context.read<LoanRepository>(),
        shelfRepository: context.read<ShelfRepository>(),
        ocrService: context.read<OcrService>(),
        registerLoanUseCase: context.read<RegisterLoanUseCase>(),
        returnLoanUseCase: context.read<ReturnLoanUseCase>(),
        deleteBookUseCase: context.read<DeleteBookUseCase>(),
      ),
      child: const BookDetailsScreen(),
    ),
  );

case AppRoutes.tracker:
  final bookId = settings.arguments as String?;
  return MaterialPageRoute(
    builder: (context) => ChangeNotifierProvider(
      create: (_) => TrackerViewModel(
        initialBookId: bookId,
        bookRepository: context.read<BookRepository>(),
        sessionRepository: context.read<SessionRepository>(),
        saveReadingSessionUseCase: context.read<SaveReadingSessionUseCase>(),
      ),
      child: const ReadingTrackerScreen(),
    ),
  );
```
*(Nota: Conferir apenas a assinatura exata dos construtores de `AddBookViewModel`, `BookDetailsViewModel` e `TrackerViewModel` já criados pelo Cleiton e marcar `[x]` na `ISSUE-N07` do `TASKS_NATANAEL.md`.)*

---

### Ação 2 — Corrigir 3 Incompatibilidades no DDL SQLite (`PLANO_DESENVOLVIMENTO.md` — Seção 4.5)
O esquema SQLite documentado na Seção 4.5 diverge dos Models Dart da Seção 4.2. Substituir as tabelas `books`, `shelves` e `notes` pelo SQL exato abaixo para garantir compatibilidade 1:1 com `toJson()`/`fromJson()`:

```sql
-- Tabela books: campo 'author' no singular (igual ao BookModel.author)
CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY NOT NULL,
    isbn TEXT,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    publisher TEXT,
    published_year INTEGER,
    genre TEXT,
    synopsis TEXT,
    cover_url TEXT,
    total_pages INTEGER NOT NULL DEFAULT 0,
    current_page INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('wantToRead', 'reading', 'read', 'abandoned')),
    format TEXT NOT NULL CHECK (format IN ('physical', 'digital')),
    rating REAL,
    tags TEXT NOT NULL DEFAULT '[]',
    shelf_ids TEXT NOT NULL DEFAULT '[]',
    started_at TEXT,
    finished_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tabela shelves: sem coluna 'book_count' (evita duplicação e respeita SSOT)
CREATE TABLE IF NOT EXISTS shelves (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tabela notes: valores do enum NoteType ('note', 'quote', 'review') + coluna 'chapter'
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('note', 'quote', 'review')),
    chapter TEXT,
    page INTEGER,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);
```

---

### Ação 3 — Pequenos Ajustes de Documentação
1. **`TASKS_CLEITON.md` (linha 19):** Corrigir encoding corrompido `NÃ£o altere` → `Não altere`.
2. **`TASKS_NATANAEL.md` (`ISSUE-N07`):** Marcar os dois últimos checkboxes como `[x]` após validar `AppRoutes.onGenerateRoute`.

---

## 6. Checklist Final de Entrega (Antes da Apresentação)

- [ ] **Código:** `AppRoutes.onGenerateRoute` instanciando `AddBookViewModel`, `BookDetailsViewModel` e `TrackerViewModel` com escopo de rota.
- [ ] **Qualidade Estática:** `flutter analyze` retornando `No issues found!`.
- [ ] **Testes Automatizados:** `flutter test` passando 100% (Models, Repositories, UseCases, Services e ViewModels).
- [ ] **Build Release:** `flutter build apk --release` gerando o `.apk` sem erros e validado em dispositivo Android físico (testando fluxo online e offline).
- [ ] **Alinhamento com o Professor:** Confirmar com o Prof. Taniro que a exportação/importação de snapshot JSON (`BackupSyncService`) atende ao requisito de transferência entre dispositivos sem necessidade de Firebase/nuvem.