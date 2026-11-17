# BOOKY — App de Biblioteca Pessoal e Rastreamento de Leitura

> **Disciplina:** Programação para Dispositivos Móveis (2026.2 — UFRN)  
> **Professor:** Taniro Chacon Rodrigues  
> **Tema:** 6 — App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Arquitetura:** MVVM com Camadas, UDF e SSOT (`Aula_24_-_Arqutietura_Recomendada.pdf`)  
> **Abordagem de Dados:** Offline-First com persistência local abstraída (`StorageService`)  
> **Referências Oficiais:**
> - [`Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf`](./Novo_-_Temas_para_o_projeto_da_disciplina_de_Programao_para_Dispositivos_Mvei.pdf) (Tema 6, pág. 7)
> - [`Aula_24_-_Arqutietura_Recomendada.pdf`](./Aula_24_-_Arqutietura_Recomendada.pdf) (Arquitetura Sugerida Flutter)

---

## 1. Visão Geral e Arquitetura (MVVM)

O **BOOKY** organiza acervos físicos e digitais, acompanha sessões e metas de leitura, registra anotações/citações (com OCR) e controla empréstimos de livros.

A organização interna segue a arquitetura recomendada pelo Flutter (`Aula_24`):

```text
lib/
├── core/                  # Tema (AppColors 5 tons), rotas (AppRoutes), DI (ConfigureProviders) e utilitários
├── domain/
│   ├── models/            # Entidades puras e imutáveis (BookModel, ShelfModel, ReadingSessionModel, NoteModel, LoanModel, AppSettingsModel)
│   ├── repositories/      # Contratos abstratos (interfaces SSOT)
│   └── use_cases/         # Orquestração de regras entre múltiplos repositórios/serviços
├── data/
│   ├── services/          # Camada mais baixa e stateless (StorageService, BookApiService, OcrService, NotificationService, ExportService, BackupSyncService)
│   └── repositories/      # Implementações concretas (SSOT com Stream reativo, sem depender de outros repositórios)
└── features/              # Camada de Apresentação (UI Layer) — relação 1:1 entre View e ViewModel
    ├── home/              # HomeScreen + HomeViewModel + ReadingChartsSection + MainNavigationScreen
    ├── library/           # LibraryScreen + LibraryViewModel + AddBookScreen + AddBookViewModel + Sheets
    ├── book_details/      # BookDetailsScreen + BookDetailsViewModel + Dialogs (Loan, Note/OCR)
    └── tracker/           # ReadingTrackerScreen + TrackerViewModel
```

### Papel de Cada Camada e Comunicação View ↔ ViewModel (UDF)
1. **Model (`domain/models`, `domain/repositories`, `data/repositories`, `data/services`):**
   - `Models`: representam as entidades do domínio com `toJson`/`fromJson` e `copyWith`.
   - `Services`: encapsulam acesso a APIs externas, câmera/OCR, sistema de arquivos, notificações e geração de PDF/CSV de forma *stateless*.
   - `Repositories`: são a **Fonte Única de Verdade (SSOT)** para cada entidade, expondo `Stream`s reativos e nunca dependendo uns dos outros.
2. **Domain / Logic (`domain/use_cases`):**
   - Coordena operações que envolvem mais de um repositório ou serviço (ex.: salvar sessão de leitura e atualizar progresso do livro; excluir livro em cascata; calcular estatísticas do dashboard; registrar/devolver empréstimo com notificação).
3. **ViewModel (`features/*/presentation/viewmodels`):**
   - Estende `ChangeNotifier` (relação **1:1** com cada tela principal).
   - Assina os `Stream`s dos repositórios/use cases, converte dados do domínio em estado pronto para exibição e expõe ações/comandos para a View.
4. **View (`features/*/presentation/screens` e `widgets`):**
   - Apenas renderiza o estado atual e encaminha eventos do usuário.
   - **Comunicação View ↔ ViewModel (Fluxo Unidirecional de Dados — UDF):**
     - A View observa o estado via `context.watch<MeuViewModel>()` (re-renderiza quando `notifyListeners()` é chamado).
     - Interações do usuário disparam métodos via `context.read<MeuViewModel>()` → que acionam UseCases/Repositories → que atualizam o `StorageService` e emitem novos dados no `Stream` → reiniciando o ciclo reativo.

---

## 2. Code Review Completo (Tema 6 + `Aula_24`)

### 2.1 O que já foi concretizado (Código Verificado)
- **RF1 — Catalogação por ISBN (Scanner + API):** `BookApiService` consulta Google Books com fallback automático para Open Library (`http.Client` injetável para testes). `AddBookScreen` integra `mobile_scanner` com trava/debounce e preenche o formulário para revisão antes de salvar.
- **RF2 — Organização por Estantes, Formato e Status:** `BookStatus` (`wantToRead`, `reading`, `read`, `abandoned`), `BookFormat` (`physical`, `digital`), avaliação (`0..5`), tags normalizadas, estantes temáticas (`ShelfRepository`) e indicador derivado de empréstimo ativo/atrasado.
- **RF3 — Rastreador de Progresso e Sessões:** `TrackerViewModel` usa timestamp (`_runningSince` + `_accumulatedSeconds` + `WidgetsBindingObserver`) resistente a segundo plano, sincroniza página ↔ porcentagem, agrupa histórico diário por `dateKey` (`YYYY-MM-DD`) e estima tempo restante (`pagesPerHour`).
- **RF4 — Diário de Citações, Anotações e Resenhas (com OCR):** `BookDetailsScreen` possui 3 abas (`Anotações`, `Citações`, `Resenha`), e `OcrService` usa `image_picker` + `google_mlkit_text_recognition` offline removendo a imagem temporária após o uso.
- **RF5 — Controle de Empréstimos:** `RegisterLoanUseCase` bloqueia empréstimos simultâneos no mesmo livro, valida datas e agenda lembrete em `NotificationService`; `ReturnLoanUseCase` conclui a devolução e cancela a notificação. Alerta visual de atraso (`LoanModel.isOverdue`) exibido na Home e Biblioteca.
- **RF6 — Busca Avançada e Estatísticas:** `LibraryViewModel` combina filtros `AND` (autor, gênero, ano, status, avaliação mínima, estante e tags). `HomeScreen` exibe gráficos interativos com `fl_chart` (livros lidos por `finishedAt` e páginas lidas por `dateKey`) + meta anual configurável.
- **RF7 — Exportação e Backup:** `ExportService` + `ExportLibraryUseCase` geram PDF (com fonte Unicode `assets/fonts/Roboto-*.ttf`) e CSV (BOM UTF-8) para *Catálogo Completo* ou *Lista de Desejos* via `share_plus`. `BackupSyncService` gera e restaura snapshot JSON das 6 coleções.
- **Arquitetura & Setup:**
  - 6 repositórios implementados **sem** dependências cruzadas entre si (`Book`, `Shelf`, `Session`, `Note`, `Loan`, `Settings`).
  - Injeção centralizada em `ConfigureProviders` (`lib/core/di/configure_providers.dart`).
  - **Design System Stitch & Paleta `AppColors`:** todas as 5 telas principais e modais preservam o estilo editorial (bordas `1px`, `borderRadius: 4`, rótulos em caixa alta, capas `2:3` com marcador) e funcionam em **Light e Dark Mode** usando os 5 tons estritos (`darkBrown`, `woodBrown`, `mediumBrown`, `beige`, `lightCream`), com apenas 1 exceção pontual (`Colors.black54` no overlay da câmera em `add_book_screen.dart`).
  - **Ciclo de datas e regras de negócio:** `startedAt` e `finishedAt` (com limpeza de `finishedAt = null` ao sair de `read`) validados em `AddBookViewModel`, `BookDetailsViewModel` e `SaveReadingSessionUseCase`; sincronia página ↔ `%` implementada em `TrackerViewModel`.
  - Configuração Android pronta para APK (`AGP 9.1.1`, `minSdk = 23`, `isCoreLibraryDesugaringEnabled = true`, permissões no `AndroidManifest.xml`).
  - 11 arquivos de testes automatizados em `test/`.

### 2.2 O que falta / Pontos Encontrados no Code Review
1. **Exclusão de Estante vs. Livros Associados (RF2 — Bug funcional):**
   - Em `LibraryViewModel.deleteShelf(shelfId)`, a estante é excluída no `ShelfRepository`, mas o `shelfId` **não** é removido da lista `book.shelfIds` dos livros associados (deixando referências órfãs).
2. **Reatividade após Restauração de Backup (RF7 / SSOT — Bug funcional):**
   - `BackupSyncService.restoreFromJson()` grava os dados diretamente via `_storageService.upsert(...)`, sem passar pelos repositórios. Como os repositórios mantêm cache em memória e `StreamController`, a interface **não atualiza em tempo real** após restaurar um backup (exige reiniciar o app).
3. **Acoplamento View → Service em 2 pontos (`Aula_24`):**
   - `ExportDataSheet` (`lib/features/library/presentation/widgets/export_data_sheet.dart`) lê `context.read<BackupSyncService>()` diretamente na camada de UI em vez de delegar para um ViewModel.
   - `AddBookScreen` (`lib/features/library/presentation/screens/add_book_screen.dart`) chama `BookApiService.isValidIsbn(...)` diretamente na View em vez de delegar ao `AddBookViewModel`.
4. **Requisito RF7 ("Sincronização em nuvem entre dispositivos"):**
   - O PDF oficial do Tema 6 menciona *"Sincronização em nuvem entre dispositivos"*. O projeto adotou arquitetura **100% offline-first** com portabilidade via snapshot JSON (`BackupSyncService`). É necessário **validar/justificar** essa decisão na apresentação ou implementar sincronização remota caso o professor exija.
5. **Persistência Atual (JSON) vs. Banco SQLite:**
   - Atualmente os dados persistem em arquivos JSON locais (`LocalJsonStorageService`). A migração para SQLite está planejada na Seção 4 (ainda não implementada em código).
6. **Helper `Command` (`lib/core/utils/command.dart`):**
   - A classe existe no projeto conforme `Aula_24` (Slide 18), mas não é utilizada pelos ViewModels (que usam flags booleanas `_isLoading` + `_errorMessage`). Ponto opcional de refatoração ou explicação no vídeo.
7. **Validação Final, APK e Vídeo:**
   - Executar `flutter analyze`, `flutter test` e `flutter build apk --release` após eventuais correções, testar ponta a ponta em dispositivo físico e gravar o vídeo de entrega.

---

## 3. Plano Unificado em Fases (Concluído vs. Faltante)

### Fase 1 — Fundação Arquitetural, Contratos & Setup Android
- [x] Setup `pubspec.yaml`, `AppColors` (5 tons Light/Dark), `ThemeController`, `AppRoutes` e `ConfigureProviders`.
- [x] Configuração Android (`namespace br.ufrn.booky`, `AGP 9.1.1`, `minSdk = 23`, `desugaring`, permissões de câmera, internet e notificações).
- [x] Modelos de domínio (`BookModel`, `ShelfModel`, `ReadingSessionModel`, `NoteModel`, `LoanModel`, `AppSettingsModel` e enums).
- [x] Interfaces e implementações SSOT dos 6 Repositórios + `StorageService` (`LocalJsonStorageService` e `InMemoryStorageService`).
- [ ] *(Opcional / Futuro)* Implementar `SqliteStorageService` conforme DDL da Seção 4.

### Fase 2 — Catalogação, Biblioteca, Estantes & Busca Avançada
- [x] `BookApiService` (Google Books + fallback Open Library + timeout + testes com `MockClient`).
- [x] `AddBookViewModel` + `AddBookScreen` (scanner ISBN com trava de frame + formulário completo de cadastro/edição).
- [x] `LibraryViewModel` + `LibraryScreen` (filtros combinados, gestão de estantes, badges de empréstimo/atraso).
- [ ] **Corrigir `deleteShelf`:** ao excluir uma estante, limpar `shelfId` de `book.shelfIds` nos livros afetados.
- [ ] **Ajustar `AddBookScreen`:** mover validação `BookApiService.isValidIsbn` para método no `AddBookViewModel` (conformidade estrita `Aula_24`).

### Fase 3 — Rastreador de Leitura, Diário com OCR, Empréstimos & Dashboard
- [x] `SaveReadingSessionUseCase` + `TrackerViewModel` + `ReadingTrackerScreen` (cronômetro resiliente a background, página ↔ %, estimativa de tempo, histórico diário).
- [x] `OcrService` (ML Kit offline + limpeza de foto temporária) + `BookDetailsViewModel` + `BookDetailsScreen` (3 abas: anotações, citações OCR, resenha) + `DeleteBookUseCase`.
- [x] `NotificationService` + `RegisterLoanUseCase` + `ReturnLoanUseCase` (bloqueio de empréstimo duplicado, agendamento/cancelamento de alerta, detecção de atraso).
- [x] `GetDashboardStatsUseCase` + `HomeViewModel` + `HomeScreen` + `ReadingChartsSection` (`fl_chart` livros/páginas por mês e meta anual).

### Fase 4 — Exportação, Backup & Conformidade de Camadas
- [x] `ExportService` (PDF Unicode PT-BR + CSV UTF-8 + `share_plus`) + `ExportLibraryUseCase`.
- [x] `BackupSyncService` (exportação e restauração de snapshot JSON).
- [ ] **Corrigir reatividade pós-restore:** garantir que `BackupSyncService.restoreFromJson()` atualize os repositórios/streams em memória sem exigir reinício do app.
- [ ] **Desacoplar `ExportDataSheet`:** acionar exportação/backup via ViewModel/UseCase em vez de `context.read<BackupSyncService>()` direto no widget.

### Fase 5 — Qualidade, Build APK, Validação Física & Entrega (Vídeo)
- [x] 11 suítes de testes unitários e de widget implementadas em `test/`.
- [ ] Rodar `flutter analyze` (zero erros/warnings) e `flutter test` (100% passando) após os ajustes finais.
- [ ] Gerar APK release (`flutter build apk --release`) e validar fluxo completo online/offline em celular Android físico (câmera ISBN, OCR, notificações, exportação PDF/CSV e persistência após fechar o app).
- [ ] Gravar e revisar o vídeo de apresentação para entrega na disciplina.

---

## 4. Planejamento do Banco de Dados Relacional (SQLite — Futuro)

Como a persistência está isolada atrás da interface `StorageService`, a troca futura do `LocalJsonStorageService` por um banco SQLite (`sqflite` ou `drift`) exigirá apenas criar `SqliteStorageService implements StorageService` e trocá-lo no `ConfigureProviders`, **sem alterar ViewModels, UseCases ou Telas**.

Esquema relacional canônico alinhado 1:1 aos Models Dart:

```sql
CREATE TABLE IF NOT EXISTS app_settings (
    id TEXT PRIMARY KEY NOT NULL,
    annual_goal INTEGER NOT NULL DEFAULT 12,
    reminder_enabled INTEGER NOT NULL DEFAULT 0,
    reminder_hour INTEGER NOT NULL DEFAULT 20,
    reminder_minute INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
);

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

CREATE TABLE IF NOT EXISTS shelves (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS book_shelves (
    book_id TEXT NOT NULL,
    shelf_id TEXT NOT NULL,
    PRIMARY KEY (book_id, shelf_id),
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
    FOREIGN KEY (shelf_id) REFERENCES shelves (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reading_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    date_key TEXT NOT NULL,
    start_page INTEGER NOT NULL,
    end_page INTEGER NOT NULL,
    pages_read INTEGER NOT NULL,
    duration_seconds INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);

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

CREATE TABLE IF NOT EXISTS loans (
    id TEXT PRIMARY KEY NOT NULL,
    book_id TEXT NOT NULL,
    borrower_name TEXT NOT NULL,
    borrower_contact TEXT NOT NULL,
    loan_date TEXT NOT NULL,
    expected_return_date TEXT NOT NULL,
    returned_date TEXT,
    is_returned INTEGER NOT NULL DEFAULT 0,
    notification_id INTEGER,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);
CREATE INDEX IF NOT EXISTS idx_sessions_book_id ON reading_sessions(book_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date_key ON reading_sessions(date_key);
CREATE INDEX IF NOT EXISTS idx_notes_book_id ON notes(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_book_id ON loans(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_active ON loans(is_returned, expected_return_date);
```

---

## 5. Roteiro Sugerido para o Vídeo de Entrega

1. **Demonstração Prática das Funcionalidades (Tema 6):**
   - **Catalogação (RF1/RF2):** Cadastrar livro via scanner ISBN (ou busca por ISBN) e manualmente; editar status, avaliação, tags e estantes temáticas.
   - **Biblioteca e Busca Avançada (RF2/RF6):** Demonstrar pesquisa dinâmica e filtros combinados (status, gênero, ano, avaliação, estante).
   - **Rastreador de Leitura (RF3):** Iniciar cronômetro, atualizar página/porcentagem, salvar sessão e mostrar histórico diário + estimativa de conclusão.
   - **Diário e OCR (RF4):** Abrir detalhes do livro, criar anotação, extrair citação via câmera (OCR) e registrar resenha.
   - **Empréstimos (RF5):** Registrar empréstimo com data prevista, mostrar badge na biblioteca/atraso na Home e registrar devolução.
   - **Dashboard, Meta e Exportação (RF6/RF7):** Mostrar gráficos `fl_chart` na Home, alterar meta anual, exportar catálogo/lista de desejos (PDF/CSV) e demonstrar persistência reabrindo o app.
2. **Explicação da Arquitetura MVVM no Código:**
   - Mostrar a estrutura de pastas (`core`, `domain`, `data`, `features`) e o `ConfigureProviders` montando as dependências.
   - Explicar o papel de **Model** (`BookModel`, `BookRepositoryImpl`, `StorageService`/`BookApiService`), **UseCase** (`SaveReadingSessionUseCase`), **ViewModel** (`TrackerViewModel` / `LibraryViewModel` com `ChangeNotifier`) e **View** (`ReadingTrackerScreen` / `LibraryScreen`).
   - Evidenciar no código como **View e ViewModel se comunicam**: `context.watch<VM>()` para reagir a mudanças de estado e `context.read<VM>()` para disparar ações (UDF + SSOT).

---

## 6. Comandos Úteis

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
