# Roadmap e Issues — NATANAEL (Arquitetura Base, Contratos, Persistência Abstraída, Notificações & Exportação/Perfil)

> **Leia primeiro:** [`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md)  
> **Seu Domínio:** Setup Android/`pubspec.yaml`, Modelos & Contratos de Domínio, **Camada de Dados Abstraída (`StorageService`, `BackupSyncService` e os 7 `Repositories` SSOT)**, Fluxo de Sessão/Acesso (`AuthViewModel` + `SessionGate`), Injeção de Dependências (`ConfigureProviders`), Rotas (`AppRoutes`), Notificações Locais, Exportação (`PDF` e `CSV`) e feature `profile`.

---

## Regras Estritas para Você e para sua IA

1. **Não edite pastas do Cleiton:** Nunca altere `lib/features/home/**`, `lib/features/library/**`, `lib/features/tracker/**` ou `lib/features/book_details/**` (a não ser em PR de integração revisado).
2. **Siga exatamente os nomes do contrato:** Todos os campos de `Model`, chaves de serialização (`toJson`/`fromJson`), assinaturas de `Repository` e nomes de rotas devem obedecer estritamente à **Seção 4 do `PLANO_DESENVOLVIMENTO.md`**.
3. **Arquitetura do Prof. Taniro (`Aula_24_-_Arqutietura_Recomendada.pdf` + `todo_app_arch`):**
   - `Services` (`storage_service.dart`, `backup_sync_service.dart`, `notification_service.dart`, `export_service.dart`) são **stateless** (Slide 8 e 25) e isolam acesso a recursos externos/arquivos/plugins.
   - `Repositories` implementam as interfaces de `lib/domain/repositories/`, são a **Fonte Única de Verdade (SSOT)** para seu respectivo modelo (Slide 22), consomem `StorageService`, expõem `Stream` reativo e **nunca** dependem de outro `Repository` (Slide 23).
   - `ViewModels` (`AuthViewModel`, `ProfileViewModel`) estendem `ChangeNotifier` (relação 1:1 com sua View — Slide 15) e expõem *commands* para a View (Slide 18).
   - `Views` (`AuthScreen`, `SessionGate`, `ProfileScreen`) nunca acessam `Service` nem contêm lógica de negócio (Slide 16).
4. **Persistência Abstraída:** Toda leitura e gravação passa pela interface `StorageService`. Assim, o app funciona imediatamente sem depender de nenhum serviço proprietário externo, e qualquer banco de dados definitivo pode ser plugado na implementação de `StorageService` sem alterar nenhum `Repository`, `UseCase` ou `ViewModel`.
5. **Ordem de entrega crítica:** Faça merge das **ISSUE-N01 e ISSUE-N02** primeiro na `main` para destravar o Cleiton com os pacotes e contratos reais.

---

## Sprint 1 — Setup, Contratos de Domínio, Persistência Abstraída, Repositórios SSOT & DI

### `ISSUE-N01` — Setup do Projeto Android, Dependências (`pubspec.yaml`) e `Command` Helper
- **Branch:** `feat/n01-project-setup`
- **Prioridade:** Bloqueante (fazer 1º de tudo)
- **Arquivos alvo:**
  - `android/app/build.gradle.kts`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/.../MainActivity.kt` (ajustar package caso altere `namespace`)
  - `pubspec.yaml`
  - `lib/core/utils/command.dart`
  - `lib/core/theme/app_theme.dart` (somente se `flutter analyze` apontar `CardTheme` -> `CardThemeData`)
- **Checklist Técnico:**
  - [ ] Alterar `namespace` e `applicationId` em `android/app/build.gradle.kts` de `ufrn.br.todo_app_architecture` para `br.ufrn.booky` (e mover `MainActivity.kt` para o novo package).
  - [ ] Ajustar `minSdk` em `android/app/build.gradle.kts` para `23` (compatível com `google_mlkit_text_recognition` e `mobile_scanner`) e habilitar `isCoreLibraryDesugaringEnabled = true` + dependência `coreLibraryDesugaring` para `flutter_local_notifications`.
  - [ ] Em `AndroidManifest.xml`, alterar `android:label` para `"BOOKY"` e adicionar permissões: `INTERNET`, `CAMERA`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
  - [ ] Adicionar no `pubspec.yaml` todas as dependências necessárias para os requisitos do Tema 6:
    - Arquitetura/DI/Utilitários: `provider`, `uuid`, `intl`, `path_provider`
    - Features Cleiton (Tema 6 — ISBN, Scanner, OCR, Gráficos): `http`, `mobile_scanner`, `google_mlkit_text_recognition`, `image_picker`, `fl_chart`
    - Features Natanael (Tema 6 — Exportação PDF/CSV, Compartilhamento, Alertas): `pdf`, `csv`, `share_plus`, `flutter_local_notifications`, `timezone`
  - [ ] Criar `lib/core/utils/command.dart` com helper `Result<T>` / `Command` (estados `running`, `error`, `completed`) seguindo `Aula_24` (Slide 18) e o guia de arquitetura do Flutter.
  - [ ] Rodar `flutter analyze` e `flutter test` para confirmar que a base compila limpa antes do merge.
- **Critérios de Aceite:** `pubspec.yaml` completo na `main`, `flutter analyze` sem erros e projeto Android pronto.

---

### `ISSUE-N02` — Modelos de Domínio e Interfaces Abstratas de Repositórios (Contratos)
- **Branch:** `feat/n02-domain-contracts`
- **Depende de:** `ISSUE-N01`
- **Prioridade:** Bloqueante para Cleiton iniciar integração real
- **Arquivos a criar:**
  - `lib/domain/models/enums.dart`
  - `lib/domain/models/user_profile_model.dart`
  - `lib/domain/models/book_model.dart`
  - `lib/domain/models/shelf_model.dart`
  - `lib/domain/models/reading_session_model.dart`
  - `lib/domain/models/note_model.dart`
  - `lib/domain/models/loan_model.dart`
  - `lib/domain/repositories/auth_repository.dart`
  - `lib/domain/repositories/user_profile_repository.dart`
  - `lib/domain/repositories/book_repository.dart`
  - `lib/domain/repositories/shelf_repository.dart`
  - `lib/domain/repositories/session_repository.dart`
  - `lib/domain/repositories/note_repository.dart`
  - `lib/domain/repositories/loan_repository.dart`
- **Checklist Técnico:**
  - [ ] Implementar exatamente todos os campos, tipos, `copyWith`, `toJson()` e `fromJson()` especificados na **Seção 4.1 e 4.2 do `PLANO_DESENVOLVIMENTO.md`**.
  - [ ] Garantir tratamento seguro de datas no `fromJson`: aceitar `String` (ISO-8601), `int` (millisecondsSinceEpoch) ou `DateTime`.
  - [ ] Em `LoanModel`, implementar o getter `bool get isOverdue` validando `!isReturned` e fim do dia (`23:59:59`) de `expectedReturnDate`.
  - [ ] Em `BookModel`, implementar getters puros `double get progressPercent` (retornando `0.0` se `totalPages <= 0`) e `bool get isFinished`.
  - [ ] Criar as 7 interfaces (`abstract interface class`) em `lib/domain/repositories/` com exatamente as assinaturas da **Seção 4.4 do `PLANO_DESENVOLVIMENTO.md`**.
- **Critérios de Aceite:** Todos os modelos e interfaces compilam sem erros e não importam pacotes de UI nem de banco de dados (camada `domain/` 100% pura).

---

### `ISSUE-N03` — `StorageService` (Camada de Persistência Abstraída)
- **Branch:** `feat/n03-storage-service`
- **Depende de:** `ISSUE-N02`
- **Arquivos a criar:**
  - `lib/data/services/storage_service.dart`
- **Checklist Técnico:**
  - [ ] Definir a interface `abstract interface class StorageService` com operações assíncronas puras por coleção (`'books'`, `'shelves'`, `'sessions'`, `'notes'`, `'loans'`, `'user_profile'`, `'auth_session'`):
    - `Future<void> init()`
    - `Future<List<Map<String, dynamic>>> getAll(String collection)`
    - `Future<Map<String, dynamic>?> getById(String collection, String id)`
    - `Future<void> upsert(String collection, String id, Map<String, dynamic> data)`
    - `Future<void> delete(String collection, String id)`
    - `Future<void> replaceCollection(String collection, List<Map<String, dynamic>> items)`
    - `Future<void> clearCollection(String collection)`
  - [ ] Implementar uma classe concreta padrão (`LocalJsonStorageService` usando `path_provider` para persistir em disco no dispositivo + `InMemoryStorageService` para testes unitários rápidos), mantendo o motor de banco totalmente encapsulado atrás de `StorageService`.
- **Critérios de Aceite:** Service *stateless* (Slide 25 da `Aula_24`), persistindo dados entre reinicializações do app e permitindo substituição transparente no futuro.

---

### `ISSUE-N04` — Implementação dos 7 Repositórios (SSOT) e `DeleteBookUseCase`
- **Branch:** `feat/n04-repositories-ssot`
- **Depende de:** `ISSUE-N02`, `ISSUE-N03`
- **Arquivos a criar:**
  - `lib/data/repositories/auth_repository_impl.dart`
  - `lib/data/repositories/user_profile_repository_impl.dart`
  - `lib/data/repositories/book_repository_impl.dart`
  - `lib/data/repositories/shelf_repository_impl.dart`
  - `lib/data/repositories/session_repository_impl.dart`
  - `lib/data/repositories/note_repository_impl.dart`
  - `lib/data/repositories/loan_repository_impl.dart`
  - `lib/domain/use_cases/delete_book_use_case.dart`
- **Checklist Técnico:**
  - [ ] Cada Repository recebe `StorageService` no construtor (`Repositories ↔ Services`, conforme Slide 25 da `Aula_24`).
  - [ ] **Regra Inviolável do Slide 23:** Nenhum Repository pode importar ou receber outro Repository.
  - [ ] Cada Repository mantém um `StreamController.broadcast()` (ou emite o estado atualizado imediatamente ao assinar `watch*()`) funcionando como **Fonte Única de Verdade (SSOT)** para sua entidade: sempre que `save*`, `add*` ou `delete*` for chamado, persiste no `StorageService` e emite a nova lista ordenada no `Stream`.
  - [ ] Em `BookRepositoryImpl.saveBook(...)`: atualizar `updatedAt = DateTime.now()` antes de gravar.
  - [ ] Em `DeleteBookUseCase` (Camada de Domínio — Slide 27): receber `BookRepository`, `NoteRepository`, `LoanRepository` e `SessionRepository`, removendo o livro e todas as notas, empréstimos e sessões associadas àquele `bookId`.
- **Critérios de Aceite:** Leitura, escrita, atualização, exclusão e streams reativos funcionando em todas as 7 entidades.

---

### `ISSUE-N05` — Feature `auth` (`AuthViewModel` + `SessionGate`), `ThemeController`, `AppRoutes` e `ConfigureProviders`
- **Branch:** `feat/n05-auth-di-routes`
- **Depende de:** `ISSUE-N04`
- **Arquivos a criar/editar:**
  - `lib/core/di/configure_providers.dart`
  - `lib/core/routes/app_routes.dart`
  - `lib/core/theme/theme_controller.dart`
  - `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`
  - `lib/features/auth/presentation/widgets/session_gate.dart`
  - `lib/features/auth/presentation/screens/auth_screen.dart`
  - `lib/main.dart`
- **Checklist Técnico:**
  - [ ] Criar `AuthViewModel extends ChangeNotifier` consumindo `AuthRepository` e `UserProfileRepository` (login, cadastro com validação de nome/e-mail/senha, criação/atualização do `UserProfileModel` ao cadastrar, recuperação de senha, logout, `isLoading`, `errorMessage`).
  - [ ] Criar `SessionGate` lendo `AuthViewModel` / `AuthRepository.watchAuthUserId()` via `Provider`: exibe `MainNavigationScreen` se houver sessão ativa, ou `AuthScreen` caso contrário.
  - [ ] Atualizar `AuthScreen` (preservando o design editorial existente) para consumir `AuthViewModel`, mostrar loading no botão e exibir `SnackBar` de erro/sucesso.
  - [ ] Registrar `ThemeController` como `ChangeNotifierProvider<ThemeController>` no `ConfigureProviders` e consumir em `main.dart` via `context.watch<ThemeController>()`.
  - [ ] Implementar `ConfigureProviders.createDependencyTree()` (exatamente no padrão do `todo_app_arch` do Prof. Taniro) registrando `Services` → `Repositories` → `UseCases` → `ViewModels`.
  - [ ] Atualizar `AppRoutes` com `onGenerateRoute`:
    - `AppRoutes.addBook` → recebe `BookModel?` em `settings.arguments`
    - `AppRoutes.bookDetails` → recebe `String` (`bookId`) em `settings.arguments`
    - `AppRoutes.tracker` → recebe `String?` (`bookId`) em `settings.arguments`
  - [ ] Atualizar `main.dart` para inicializar `final data = await ConfigureProviders.createDependencyTree()` e envolver `BookyApp` em `MultiProvider(providers: data.providers, ...)`.
- **Critérios de Aceite:** Fluxo de entrada/cadastro cria perfil do leitor, mantém sessão ao reabrir o app e `ConfigureProviders` injeta todas as dependências.

---

## Sprint 2 — Serviço de Notificações Locais & Integração DI da Sprint 2

### `ISSUE-N06` — `NotificationService` (Alerta de Atraso/Devolução de Empréstimo e Lembrete Diário)
- **Branch:** `feat/n06-notification-service`
- **Depende de:** `ISSUE-N01`
- **Arquivos a criar:**
  - `lib/data/services/notification_service.dart`
  - Atualizar `lib/core/di/configure_providers.dart`
- **Checklist Técnico:**
  - [ ] Inicializar `flutter_local_notifications` + `timezone` (`tz.initializeTimeZones()`, fuso local).
  - [ ] Solicitar permissão `POST_NOTIFICATIONS` no Android 13+ com tratamento seguro caso o usuário negue.
  - [ ] Expor exatamente estas assinaturas (serão consumidas pelo Cleiton na `ISSUE-C05`):
    - `Future<void> initialize()`
    - `Future<void> scheduleLoanReturnReminder({required int id, required String bookTitle, required String borrowerName, required DateTime expectedReturnDate})`
    - `Future<void> cancelNotification(int id)`
    - `Future<void> scheduleDailyReadingReminder({required int hour, required int minute})`
    - `Future<void> cancelDailyReadingReminder()`
- **Critérios de Aceite:** Agendamento e cancelamento de notificações locais executando sem exceções no Android.

---

### `ISSUE-N07` — Atualização do `ConfigureProviders` para Features da Sprint 2
- **Branch:** `feat/n07-di-sprint2`
- **Depende de:** Merge das issues Sprint 2 do Cleiton + `ISSUE-N06`
- **Arquivos alvo:**
  - `lib/core/di/configure_providers.dart`
  - `lib/core/routes/app_routes.dart`
- **Checklist Técnico:**
  - [ ] Registrar no `ConfigureProviders`: `BookApiService`, `OcrService`, `NotificationService`, `RegisterLoanUseCase`, `ReturnLoanUseCase` e `LibraryViewModel`.
  - [ ] Em `AppRoutes.onGenerateRoute`: instanciar `ChangeNotifierProvider` com escopo de tela para `AddBookViewModel` (`bookToEdit`) e `BookDetailsViewModel` (`bookId`) consumindo os serviços/repositórios/usecases já providos pelo `ConfigureProviders`.
  - [ ] Validar navegação ponta-a-ponta `LibraryScreen` → `AddBookScreen` e `LibraryScreen` → `BookDetailsScreen(bookId)`.

---

## Sprint 3 — Exportação (PDF/CSV), Backup/Sincronização, Meta Anual & Tela de Perfil

### `ISSUE-N08` — `ExportService` (PDF Unicode + CSV UTF-8 + Share), `ExportLibraryUseCase`, `BackupSyncService` e `SyncBackupUseCase`
- **Branch:** `feat/n08-export-and-backup`
- **Depende de:** `ISSUE-N04`
- **Arquivos a criar/editar:**
  - `assets/fonts/` (adicionar fonte `.ttf` com suporte Unicode PT-BR, ex.: `Roboto-Regular.ttf` e `Roboto-Bold.ttf`, declarando no `pubspec.yaml`)
  - `lib/data/services/export_service.dart`
  - `lib/data/services/backup_sync_service.dart`
  - `lib/domain/use_cases/export_library_use_case.dart`
  - `lib/domain/use_cases/sync_backup_use_case.dart`
- **Checklist Técnico:**
  - [ ] Definir `enum ExportScope { fullCatalog, wishlist }` e `enum ExportFormat { pdf, csv }`.
  - [ ] `ExportLibraryUseCase`: obtém livros de `BookRepository.getBooks()`; se `wishlist`, filtra `status == BookStatus.wantToRead`; se lista vazia, lança erro amigável; envia para `ExportService`.
  - [ ] `ExportService`:
    - **PDF (`pdf`):** carrega fonte `.ttf` de `assets/fonts/` via `rootBundle` para acentuação PT-BR; gera documento com Título, Autor, ISBN, Editora, Páginas, Status, Formato, Avaliação e Estantes/Tags; salva em `getTemporaryDirectory()` (`path_provider`) e compartilha via `share_plus`.
    - **CSV (`csv`):** cabeçalho em PT-BR, BOM UTF-8 (`\uFEFF`), `ListToCsvConverter`, salva arquivo temporário e compartilha via `share_plus`.
  - [ ] `BackupSyncService` + `SyncBackupUseCase`: gera snapshot completo das coleções do `StorageService`, permite exportar/compartilhar e restaurar/sincronizar os dados entre dispositivos, recarregando os repositórios SSOT e atualizando `lastSyncAt` no perfil.
- **Critérios de Aceite:** PDF sem caracteres quebrados e CSV abrindo corretamente acentos e quebras de linha tanto para *Catálogo Completo* quanto para *Lista de Desejos*; backup/restauração operacional.

---

### `ISSUE-N09` — `ProfileViewModel` e Integração Completa da `ProfileScreen`
- **Branch:** `feat/n09-profile-feature`
- **Depende de:** `ISSUE-N05`, `ISSUE-N06`, `ISSUE-N08`
- **Arquivos a criar/editar:**
  - `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/core/di/configure_providers.dart` (registrar `ExportService`, `BackupSyncService`, `ExportLibraryUseCase`, `ProfileViewModel`, `SaveReadingSessionUseCase`, `GetDashboardStatsUseCase`, `HomeViewModel`)
  - `lib/core/routes/app_routes.dart` (garantir `ChangeNotifierProvider<TrackerViewModel>` com escopo de tela na rota `AppRoutes.tracker`)
- **Checklist Técnico:**
  - [ ] `ProfileViewModel extends ChangeNotifier`: consome `UserProfileRepository`, `AuthRepository`, `ExportLibraryUseCase`, `BackupSyncService`, `NotificationService` e `ThemeController`.
  - [ ] Exibir **nome real, iniciais e e-mail** do `UserProfileModel` (remover *"Arthur Pendelton"* hardcoded).
  - [ ] **Metas de Leitura:** diálogo para editar `annualReadingGoal` (`> 0`), exibindo ano dinâmico `DateTime.now().year` (corrigir *"2024"* hardcoded).
  - [ ] **Notificações e Lembretes:** seletor de horário + toggle para ativar/desativar lembrete diário (`UserProfileRepository.updateDailyReminder` + `NotificationService`).
  - [ ] **Exportar Dados (Requisito Tema 6):** diálogo escolhendo *Catálogo Completo* ou *Lista de Desejos* + *PDF* ou *CSV*, com indicador de progresso e `SnackBar`.
  - [ ] **Backup e Sincronização (Requisito Tema 6):** seção para acionar backup/sincronização de dados entre dispositivos via `BackupSyncService` e exibir data/hora do último backup (`lastSyncAt`).
  - [ ] **Conta e Segurança:** editar nome do leitor e credenciais.
  - [ ] **Sair da Biblioteca:** chamar `ProfileViewModel.signOut()`.
- **Critérios de Aceite:** Alterar meta anual ou nome no perfil reflete em tempo real na `HomeScreen`; exportação PDF/CSV, backup e lembretes operacionais.

---

## Sprint 4 — Testes Unitários, Auditoria Visual & Build Release

### `ISSUE-N10` — Testes Unitários da Camada de Domínio, Repositórios, Empréstimos e Exportação
- **Branch:** `test/n10-unit-tests-natanael`
- **Arquivos a criar/editar:**
  - `test/domain/models_serialization_test.dart`
  - `test/domain/loan_overdue_test.dart`
  - `test/domain/delete_book_use_case_test.dart`
  - `test/domain/export_library_use_case_test.dart`
  - `test/features/auth/auth_viewmodel_test.dart`
  - `test/widget_test.dart` (atualizar smoke test para o novo `BookyApp` / `MultiProvider`)
- **Checklist Técnico:**
  - [ ] Testar `toJson`/`fromJson` dos 6 modelos (incluindo nulos e datas).
  - [ ] Testar `LoanModel.isOverdue` (no prazo, vence hoje, vencido, já devolvido).
  - [ ] Testar `DeleteBookUseCase` garantindo remoção em cascata de notas, sessões e empréstimos usando `InMemoryStorageService`.
  - [ ] Testar `ExportLibraryUseCase` (`fullCatalog` vs `wishlist` e lista vazia).
  - [ ] Testar geração de CSV válido em `ExportService`.
  - [ ] Testar `AuthViewModel`.

---

### `ISSUE-N11` — Auditoria Final Light/Dark Mode, Documentação e Build Release
- **Branch:** `chore/n11-release-audit`
- **Checklist Técnico:**
  - [ ] Auditar `AuthScreen` e `ProfileScreen` (e modais) no **Modo Claro** e **Modo Escuro** com `AppColors`.
  - [ ] Revisar `README.md` com instruções de execução e arquitetura.
  - [ ] Executar `flutter analyze`, `flutter test` e `flutter build apk --release`, validando instalação do APK final.
