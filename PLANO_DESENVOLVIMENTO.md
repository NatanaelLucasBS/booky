# Plano de Implementação e Divisão de Tarefas — BOOKY

> **Disciplina:** Programação para Dispositivos Móveis (2026.2)  
> **Tema Selecionado:** 6. App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Desenvolvedores:** Cleiton & Natan  
> **Repositório:** `booky`

---

## 1. Requisitos do Trabalho (Tema 6)

Com base no documento de especificação da disciplina, o **BOOKY** deve atender integralmente aos seguintes requisitos funcionais:

1. **Catalogação por ISBN (Scanner + API):** Cadastro manual ou leitura do código de barras ISBN pela câmera, buscando automaticamente capa, título, autor, sinopse, editora e número de páginas via integração com a API do **Google Books** ou **Open Library**.
2. **Organização por Estantes e Status:** Classificação por status (*Quero Ler, Lendo, Lido, Abandonado*), avaliação pessoal, tags customizadas e estantes temáticas.
3. **Rastreador de Progresso e Sessões:** Cronômetro de leitura e atualização da página atual ou porcentagem concluída, gerando histórico diário de páginas lidas e estimativa de tempo para terminar o livro.
4. **Diário de Citações e Resenhas:** Registro de anotações, resenhas e trechos favoritos de cada livro, com suporte a **OCR via câmera** para extrair texto diretamente da página física.
5. **Controle de Empréstimos:** Registro de livros emprestados (nome do amigo, contato, data do empréstimo e data prevista de devolução) com alerta de atraso.
6. **Busca Avançada e Estatísticas:** Filtros combinados por autor, gênero, ano, status ou avaliação, além de gráficos de livros/páginas lidas por mês e meta anual de leitura.
7. **Backup e Exportação:** Sincronização em nuvem entre dispositivos e exportação do catálogo completo ou lista de desejos em **PDF** e **CSV**.

*(Requisito transversal do Design System)*: Suporte completo a **Modo Claro e Modo Escuro** seguindo a paleta editorial estrita de 5 tons (`AppColors`) já configurada em `lib/core/theme/`.

---

## 2. Arquitetura Recomendada (Feature-First + MVVM com Provider)

O projeto adota o padrão **MVVM (Model - View - ViewModel)** recomendado no template base da disciplina, utilizando **`Provider`** para gerenciamento de estado e injeção de dependências (`ConfigureProviders`), combinado à organização **Feature-First** já estruturada em `lib/features/`:

- **Model / Entities:** Classes de domínio com serialização (`toMap`/`fromMap` para SQLite e `toJson`/`fromJson` para APIs e Firestore).
- **Service:** Acesso direto a dados externos ou nativos (SQLite local, API Google Books/Open Library, Câmera/Scanner, OCR, Firebase Auth/Firestore, Gerador de PDF/CSV).
- **Repository:** Camada mediadora entre Services e ViewModels. Responsável por regras de cache (estratégia *offline-first*), consolidação de dados e tratamento de erros.
- **ViewModel (`ChangeNotifier`):** Mantém o estado da tela (`isLoading`, listas, filtros, timers, erros), executa ações acionadas pela UI e chama `notifyListeners()`.
- **View (Screens & Widgets):** Widgets declarativos que consomem o estado via `context.watch<T>()` / `Consumer<T>` e disparam ações via `context.read<T>()`, sem conter lógica de negócio.
- **Injeção de Dependências (`ConfigureProviders`):** Centraliza a árvore de `Provider` e `ChangeNotifierProvider` injetada no `MultiProvider` em `lib/main.dart`.

### Estrutura de Diretórios Alvo

```text
lib/
├── core/
│   ├── constants/          # AppConstants (assets, URLs base de APIs)
│   ├── database/           # DatabaseHelper (SQLite tabelas e migrations)
│   ├── di/                 # configure_providers.dart (árvore de dependências)
│   ├── routes/             # AppRoutes
│   └── theme/              # AppColors, AppTheme, ThemeController
└── features/
    ├── auth/               # Login, Cadastro e Sessão (Firebase Auth)
    │   ├── data/           # models, services, repositories
    │   └── presentation/   # viewmodels, screens, widgets
    ├── home/               # Dashboard, Leitura Atual e Gráficos (fl_chart)
    │   ├── data/
    │   └── presentation/
    ├── library/            # Estante, Busca Avançada, Scanner ISBN e Cadastro
    │   ├── data/
    │   └── presentation/
    ├── book_details/       # Ficha do Livro, Empréstimos e Diário/OCR
    │   ├── data/
    │   └── presentation/
    ├── tracker/            # Cronômetro, Sessões e Estimativa de Tempo
    │   ├── data/
    │   └── presentation/
    └── profile/            # Perfil, Metas, Backup Nuvem e Exportação PDF/CSV
        ├── data/
        └── presentation/
```

---

## 3. Divisão de Desenvolvimento: Cleiton & Natan

A divisão foi projetada para permitir **desenvolvimento paralelo**, reduzindo conflitos de arquivos no Git e equilibrando a complexidade entre integrações de hardware/API, persistência local e nuvem.

| Área / Responsabilidade | Cleiton | Natan |
| :--- | :--- | :--- |
| **Camada Base & Infra** | SQLite (`DatabaseHelper`), Modelos Core e `ConfigureProviders` (DI) | Setup de pacotes no `pubspec.yaml`, Firebase Setup e Notificações Locais |
| **Features Verticais** | `library` (Scanner ISBN + API + Busca) e `tracker` + `home` (Cronômetro + Gráficos) | `auth` (Login/Cadastro), `book_details` (Empréstimos + OCR) e `profile` (Backup + PDF/CSV) |
| **Requisitos Cobertos** | RF1, RF2, RF3, RF6 | Auth, RF4, RF5, RF7 |

---

## 4. Plano de Implementação e Tasks por Sprint

### Sprint 1 — Fundação Arquitetural, Persistência Local e Autenticação

#### Tasks do Cleiton
- [ ] **C1.1 — Modelos de Domínio Base (`lib/core/models/` ou por feature):**
  - Criar `BookModel` (id, isbn, title, author, publisher, totalPages, currentPage, coverUrl, synopsis, genre, year, rating, status, tags, shelfName, createdAt, updatedAt).
  - Criar `ReadingSessionModel` (id, bookId, startTime, durationSeconds, pagesRead, startPage, endPage, date).
  - Criar `NoteModel` (id, bookId, type [note/quote/review], chapter, page, content, createdAt).
  - Criar `LoanModel` (id, bookId, borrowerName, borrowerContact, loanDate, expectedReturnDate, returnedDate, isReturned).
- [ ] **C1.2 — Banco de Dados Local SQLite (`lib/core/database/database_helper.dart`):**
  - Configurar `sqflite` e `path` com singleton do banco `booky.db`.
  - Criar tabelas `books`, `reading_sessions`, `notes`, `loans` com chaves estrangeiras (`ON DELETE CASCADE`).
- [ ] **C1.3 — Injeção de Dependências (`lib/core/di/configure_providers.dart`):**
  - Implementar classe `ConfigureProviders` seguindo o padrão MVVM do projeto, registrando `Services`, `Repositories` e `ViewModels` no `MultiProvider` do `lib/main.dart`.

#### Tasks do Natan
- [ ] **N1.1 — Configuração de Dependências e Permissões (`pubspec.yaml`, Android/iOS):**
  - Adicionar dependências necessárias: `sqflite`, `path`, `http`, `mobile_scanner`, `google_mlkit_text_recognition`, `image_picker`, `fl_chart`, `pdf`, `csv`, `share_plus`, `path_provider`, `flutter_local_notifications`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `intl`.
  - Configurar permissões de Câmera e Armazenamento no `AndroidManifest.xml` e `Info.plist`.
- [ ] **N1.2 — Configuração do Firebase & Autenticação (`lib/features/auth/`):**
  - Configurar projeto Firebase e conectar `Firebase.initializeApp()` no `main.dart`.
  - Criar `AuthService` (login e-mail/senha, cadastro, recuperação de senha, logout e listener de estado).
  - Criar `AuthRepository` e `AuthViewModel` (`ChangeNotifier` com tratamento de loading e mensagens de erro).
- [ ] **N1.3 — Integração da Tela de Autenticação (`auth_screen.dart`):**
  - Conectar `AuthScreen` ao `AuthViewModel`, adicionar validação de formulários, feedback via `SnackBar` e redirecionamento automático caso já exista sessão ativa.

---

### Sprint 2 — Catalogação, Estante, Empréstimos e Diário com OCR

#### Tasks do Cleiton
- [ ] **C2.1 — Serviço de API de Livros (`lib/features/library/data/services/book_api_service.dart`):**
  - Implementar busca de metadados via ISBN consumindo **Google Books API** (com fallback para **Open Library API**).
  - Mapear capa, título, autor, sinopse, editora, ano de publicação, gênero e total de páginas.
- [ ] **C2.2 — Scanner de Código de Barras ISBN (`add_book_screen.dart`):**
  - Integrar câmera na aba *Escanear Código* usando `mobile_scanner` para detectar códigos EAN-13/ISBN em tempo real.
  - Ao detectar ou digitar ISBN, buscar na `BookApiService` e preencher automaticamente o formulário manual para revisão e salvamento.
- [ ] **C2.3 — Gerenciamento da Biblioteca & Busca Avançada (`library_screen.dart`):**
  - Criar `BookLocalService`, `LibraryRepository` e `LibraryViewModel`.
  - Conectar `LibraryScreen` ao SQLite com suporte a:
    - Status: *Quero Ler, Lendo, Lido, Abandonado* + filtro *Emprestados*.
    - Tags customizadas, estantes temáticas e avaliação por estrelas.
    - Modal de **Busca Avançada** combinando filtros por autor, gênero, ano, status e avaliação mínima.

#### Tasks do Natan
- [ ] **N2.1 — Serviço e Fluxo de Empréstimos (`lib/features/book_details/`):**
  - Criar `LoanService` (SQLite), `LoanRepository` e integrar ao `BookDetailsViewModel`.
  - Na `BookDetailsScreen`, expandir o diálogo de empréstimo para coletar: **nome do amigo, contato (telefone/e-mail), data do empréstimo e data prevista de devolução**.
  - Implementar cálculo de status de atraso e agendamento de notificação local (`flutter_local_notifications`) na data prevista de devolução.
  - Exibir indicador visual de atraso nos cards da biblioteca e detalhes quando `DateTime.now().isAfter(expectedReturnDate)`.
- [ ] **N2.2 — Diário de Citações, Resenhas e Anotações (`book_details_screen.dart`):**
  - Criar `NotesRepository` para CRUD de anotações, citações e resenha final do livro + avaliação pessoal (1 a 5 estrelas).
  - Atualizar abas da `BookDetailsScreen` (*Anotações*, *Citações* e *Resenha*) conectadas ao banco local.
- [ ] **N2.3 — Extração de Texto por OCR via Câmera (`lib/features/book_details/data/services/ocr_service.dart`):**
  - Integrar `image_picker` + `google_mlkit_text_recognition` para fotografar a página física do livro, extrair o texto automaticamente e preencher o campo de nova citação/anotação para edição antes de salvar.

---

### Sprint 3 — Rastreador de Leitura, Estatísticas, Backup e Exportação

#### Tasks do Cleiton
- [ ] **C3.1 — Rastreador de Sessões e Estimativa de Tempo (`lib/features/tracker/`):**
  - Criar `TrackerRepository` e `TrackerViewModel`.
  - Conectar `ReadingTrackerScreen` ao livro selecionado:
    - Cronômetro persistente (suportando pausar, retomar e salvar sessão no SQLite).
    - Atualização automática da `currentPage` do livro e transição automática para *Lido* ao atingir `totalPages`.
    - Cálculo dinâmico de velocidade média de leitura (páginas/hora) e **estimativa de tempo restante para terminar o livro**.
    - Registro de histórico diário de páginas lidas.
- [ ] **C3.2 — Dashboard e Gráficos Estatísticos (`lib/features/home/`):**
  - Criar `HomeViewModel` agregando dados reais do SQLite (livros lidos no ano, livros em andamento, percentual da meta anual, leitura atual mais recente).
  - Integrar gráficos interativos com `fl_chart` na `HomeScreen` (ou seção de Estatísticas):
    - Gráfico de barras: **livros e páginas lidas por mês**.
    - Progresso visual da **meta anual de leitura**.

#### Tasks do Natan
- [ ] **N3.1 — Sincronização em Nuvem (`lib/features/profile/data/services/cloud_sync_service.dart`):**
  - Implementar serviço de backup/restauração no **Cloud Firestore** vinculado ao `uid` do usuário autenticado (sincronizando `books`, `loans`, `notes`, `reading_sessions`).
  - Criar indicador de última sincronização e botão manual de *"Sincronizar Agora"* na `ProfileScreen`, além de sincronização automática ao abrir/alterar dados quando online.
- [ ] **N3.2 — Exportação em PDF e CSV (`lib/features/profile/data/services/export_service.dart`):**
  - Implementar geração de relatório em **PDF** (usando pacote `pdf`) com o catálogo completo ou filtrado (ex: Lista de Desejos / Quero Ler), incluindo capa/título, autor, status e avaliação.
  - Implementar geração de planilha **CSV** (usando pacote `csv`) com todos os campos do acervo.
  - Integrar compartilhamento nativo do arquivo gerado via `share_plus`.
- [ ] **N3.3 — Tela de Perfil, Metas e Lembretes (`profile_screen.dart`):**
  - Criar `ProfileViewModel` para editar a **Meta Anual de Leitura** (persistida localmente/nuvem e refletida no Dashboard).
  - Implementar configuração de **Notificações e Lembretes diários** de leitura.
  - Conectar os botões *Exportar Dados (PDF/CSV)* e *Sincronizar Nuvem* com feedback visual de progresso.

---

### Sprint 4 — Integração Final, Testes e Refinamento

#### Tasks Conjuntas
- [ ] **J4.1 — Testes Unitários e de Widget (`test/`):**
  - **Cleiton:** Escrever testes unitários para `LibraryViewModel` (filtros combinados) e `TrackerViewModel` (cálculo de progresso e estimativa de tempo), além de mock do `BookApiService`.
  - **Natan:** Escrever testes unitários para `AuthViewModel`, `Loan` (verificação de atraso) e `ExportService` (geração válida de CSV), além de testes de widget das telas principais.
- [ ] **J4.2 — Auditoria Visual & Tema (Light/Dark Mode):**
  - Validar todas as 7 telas e modais em ambos os temas (`AppTheme.lightTheme` e `AppTheme.darkTheme`), garantindo contraste e fidelidade à paleta estrita de 5 tons.
- [ ] **J4.3 — Validação Offline-First & Fluxo E2E:**
  - Testar o aplicativo sem conexão de rede (cadastro manual, rastreador, OCR local, empréstimos) e validar a sincronização posterior ao reconectar.
- [ ] **J4.4 — Documentação Final e Build:**
  - Atualizar `README.md` com instruções de instalação, arquitetura, screenshots e credenciais/configuração de API.
  - Gerar build final (`flutter build apk --release`) e validar execução em dispositivo físico/emulador.

---

## 5. Infraestrutura, Firebase & Estratégia Offline-First

O **BOOKY** não requer servidor/backend próprio. Toda a infraestrutura em nuvem utiliza o **Firebase (Plano Spark — Gratuito)** combinado com persistência local em **SQLite**, garantindo funcionamento completo sem internet (*Offline-First*).

### 5.1 Serviços Utilizados

| Componente | Tecnologia | Papel no Projeto |
| :--- | :--- | :--- |
| **Autenticação** | Firebase Authentication | Cadastro, login (e-mail/senha) e recuperação de senha. |
| **Banco Local (Primário)** | SQLite (`sqflite`) | Fonte principal de leitura/escrita no dispositivo (rápido e 100% offline). |
| **Backup & Sync na Nuvem** | Cloud Firestore | Sincronização entre dispositivos vinculada ao `uid` do usuário autenticado. |
| **Catalogação ISBN** | Google Books API / Open Library | Consultas HTTP diretas do app para preenchimento de metadados e URL da capa. |
| **OCR de Citações** | Google ML Kit (`text_recognition`) | Processamento local no dispositivo (extrai o texto da foto sem precisar enviar imagem para nuvem). |
| **Distribuição (Testes)** | APK / Firebase App Distribution | Geração de `.apk` de release ou distribuição de versões de teste entre a equipe e avaliador. |

### 5.2 Modelagem do Cloud Firestore

Os dados sincronizados são isolados por usuário autenticado (`uid`), mantendo espelhamento direto com as tabelas locais do SQLite:

```text
users/{uid}
├── (documento raiz)        # name, email, annualReadingGoal, updatedAt
├── books/{bookId}          # isbn, title, author, publisher, totalPages, currentPage, coverUrl, status, rating, tags, shelfName, isDeleted, updatedAt
├── loans/{loanId}          # bookId, borrowerName, borrowerContact, loanDate, expectedReturnDate, returnedDate, isReturned, updatedAt
├── notes/{noteId}          # bookId, type (note|quote|review), chapter, page, content, createdAt, updatedAt
└── sessions/{sessionId}    # bookId, startTime, durationSeconds, pagesRead, startPage, endPage, date, updatedAt
```

### 5.3 Regras de Segurança do Firestore (`firestore.rules`)

Garante que cada leitor acesse e modifique apenas seus próprios registros:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5.4 Fluxo de Sincronização Offline-First & Gestão de Imagens

1. **Escrita Local Imediata:** Toda criação, edição ou sessão de leitura salva primeiro no SQLite com `updatedAt` (e flag `isSynced = 0` / `isDeleted` para exclusões lógicas).
2. **Sincronização em Segundo Plano / Manual:** Quando há conectividade e usuário autenticado, o `CloudSyncService` envia registros pendentes (`isSynced = 0`) ao Firestore e baixa documentos remotos com `updatedAt` mais recente.
3. **Estratégia para Imagens (Custo Zero, sem Firebase Storage):**
   - **Capas da API:** Armazenar apenas a string `coverUrl` retornada pelo Google Books / Open Library.
   - **Fotos do OCR:** Processar localmente via ML Kit na captura, extrair apenas o texto da citação e descartar a imagem temporária.
   - **Capas Manuais / Avatar:** Salvar no armazenamento local do dispositivo (`path_provider`) para evitar exigência do plano Blaze (cartão de crédito) no Firebase Storage.

---

## 6. Fluxo de Trabalho Git e Boas Práticas

Para evitar conflitos de merge durante o desenvolvimento paralelo:

1. **Branches por Feature:** Nunca commitar diretamente na `main`. Criar branches descritivas a partir da `main`:
   - `feat/cleiton-sqlite-models`
   - `feat/natan-firebase-auth`
   - `feat/cleiton-isbn-scanner`
   - `feat/natan-loans-ocr`
   - etc.
2. **Arquivos Compartilhados (`pubspec.yaml`, `configure_providers.dart`, `app_routes.dart`):**
   - Sempre realizar `git pull origin main` antes de editar arquivos compartilhados.
   - Registrar dependências da Sprint 1 antecipadamente para ambos trabalharem sobre a mesma base.
3. **Padrão de Commits (Conventional Commits):**
   - `feat: ...` (nova funcionalidade)
   - `fix: ...` (correção de bug)
   - `refactor: ...` (melhoria de código sem alterar comportamento)
   - `test: ...` (adição/ajuste de testes)
   - `docs: ...` (documentação)
4. **Code Review Cruzado:** Todo Pull Request aberto por um desenvolvedor deve ser revisado e testado pelo outro antes do merge na `main`.
