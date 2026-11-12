# Roadmap e Issues — NATANAEL (Banco Firebase, Infra, Auth & Perfil/Exportação)

> **Leia primeiro:** [`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md)  
> **Seu Domínio:** Setup Android/Firebase, `pubspec.yaml`, Modelos & Contratos, **todo o Banco (Cloud Firestore + Offline Persistence)**, Autenticação (`auth_app_firebase` + MVVM), DI (`ConfigureProviders`), Rotas, Notificações Locais, Exportação (PDF/CSV) e feature `profile`.

---

## Regras Estritas para Você e para sua IA

1. **Não edite pastas do Cleiton:** Nunca altere `lib/features/home/**`, `lib/features/library/**`, `lib/features/tracker/**` ou `lib/features/book_details/**` (a não ser em PR de integração revisado).
2. **Siga exatamente os nomes do contrato:** Todos os campos de `Model`, chaves JSON do Firestore, assinaturas de `Repository` e nomes de rotas devem obedecer estritamente à **Seção 4 do `PLANO_DESENVOLVIMENTO.md`**.
3. **Arquitetura do Prof. Taniro (`Aula_24` + `auth_app_firebase`):**
   - `Services` (`auth_service.dart`, `firestore_service.dart`, `notification_service.dart`, `export_service.dart`) são **stateless** e encapsulam SDKs/plugins.
   - `Repositories` implementam as interfaces de `lib/domain/repositories/`, são **SSOT** (único local que escreve/lê daquele tipo de dado), consomem `FirestoreService` + `AuthService` (para obter `uid`), e **nunca** dependem de outro `Repository`.
   - `ViewModels` (`AuthViewModel`, `ProfileViewModel`) estendem `ChangeNotifier` (relação 1:1 com sua View) e nunca chamam `FirebaseAuth` ou `FirebaseFirestore` diretamente.
   - `Views` (`AuthScreen`, `AuthChecker`, `ProfileScreen`) nunca acessam `Service` nem contêm lógica de negócio.
4. **Ordem de entrega crítica:** Faça merge das **ISSUE-N01 e ISSUE-N02** primeiro na `main` para destravar o Cleiton com os pacotes e contratos reais.

---

## Sprint 1 — Setup, Firebase, Contratos, Banco Firestore & Autenticação

### `ISSUE-N01` — Setup do Projeto Android, Dependências (`pubspec.yaml`) e Utils Base
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
  - [ ] Ajustar `minSdk` em `android/app/build.gradle.kts` para `23` (compatível com `firebase_auth`, `cloud_firestore`, `google_mlkit_text_recognition` e `mobile_scanner`) e habilitar `isCoreLibraryDesugaringEnabled = true` + dependência `coreLibraryDesugaring` para `flutter_local_notifications`.
  - [ ] Em `AndroidManifest.xml`, alterar `android:label` para `"BOOKY"` e adicionar permissões: `INTERNET`, `CAMERA`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
  - [ ] Adicionar no `pubspec.yaml` todas as dependências da equipe (via `flutter pub add`):
    - Banco/Auth/DI: `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, `uuid`, `intl`
    - Features Cleiton: `http`, `mobile_scanner`, `google_mlkit_text_recognition`, `image_picker`, `fl_chart`
    - Features Natanael: `pdf`, `csv`, `share_plus`, `path_provider`, `flutter_local_notifications`, `timezone`
  - [ ] Criar `lib/core/utils/command.dart` com helper `Result<T>` / `Command` (estados `running`, `error`, `completed`) seguindo `Aula_24` (Slide 18) e `todo_app_arch`.
  - [ ] Rodar `flutter analyze` e `flutter test` para confirmar que a base compila limpa antes do merge.
- **Critérios de Aceite:** `pubspec.yaml` completo na `main`, `flutter analyze` sem erros e Android configurado para receber o Firebase.

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
  - [ ] Garantir tratamento seguro de datas no `fromJson`: aceitar `Timestamp` (Firestore), `String` (ISO-8601) ou `DateTime`.
  - [ ] Em `LoanModel`, implementar o getter `bool get isOverdue` validando `!isReturned` e fim do dia (`23:59:59`) de `expectedReturnDate`.
  - [ ] Em `BookModel`, implementar getters puros `double get progressPercent` (retornando `0.0` se `totalPages <= 0`) e `bool get isFinished`.
  - [ ] Criar as 7 interfaces (`abstract interface class`) em `lib/domain/repositories/` com exatamente as assinaturas da **Seção 4.4 do `PLANO_DESENVOLVIMENTO.md`**.
- **Critérios de Aceite:** Todos os modelos e interfaces compilam sem erros e não importam pacotes de UI (camada `domain/` pura).

---

### `ISSUE-N03` — Criação do Projeto Firebase & Configuração (`flutterfire configure`)
- **Branch:** `feat/n03-firebase-setup`
- **Depende de:** `ISSUE-N01`
- **Arquivos gerados/editados:**
  - `lib/firebase_options.dart` (gerado automaticamente pelo CLI — **não escrever manualmente**)
  - `android/app/google-services.json`
  - `android/settings.gradle.kts` e `android/app/build.gradle.kts` (plugin `com.google.gms.google-services`, exatamente como em `taniro/auth_app_firebase`)
- **Passo a passo manual no Console Firebase (fazer você mesmo):**
  1. Acessar o **Firebase Console** e criar o projeto `booky-app` (Plano Spark gratuito).
  2. Habilitar **Authentication → Sign-in method → E-mail/Senha**.
  3. Criar o banco **Cloud Firestore** em modo produção (região `southamerica-east1` ou `us-central1`) e aplicar as **Rules** definidas na **Seção 4.3 do `PLANO_DESENVOLVIMENTO.md`**.
  4. No terminal, autenticar e rodar `flutterfire configure` selecionando Android (usando o `applicationId` definido na `ISSUE-N01`).
  5. Conferir se `android/settings.gradle.kts` e `android/app/build.gradle.kts` ficaram com o plugin `google-services` no mesmo padrão do repo `taniro/auth_app_firebase`.
- **Critérios de Aceite:** `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` executa sem erro ao iniciar o app no emulador/celular.

---

### `ISSUE-N04` — Services Base do Firebase (`AuthService` & `FirestoreService`) + Persistência Offline
- **Branch:** `feat/n04-firebase-services`
- **Depende de:** `ISSUE-N02`, `ISSUE-N03`
- **Arquivos a criar:**
  - `lib/data/services/auth_service.dart`
  - `lib/data/services/firestore_service.dart`
- **Checklist Técnico:**
  - [ ] `AuthService` (seguindo `taniro/auth_app_firebase/lib/services/auth_service.dart`, porém **null-safe**):
    - `Stream<User?> authStateChanges()`
    - `User? get currentUser` (usar `?.`, nunca `currentUser!` sem checar)
    - `Future<UserCredential> signInWithEmailAndPassword(String email, String password)`
    - `Future<UserCredential> signUpWithEmailAndPassword(String email, String password, {required String name})` (chamar `updateDisplayName(name)`)
    - `Future<void> resetPassword(String email)`
    - `Future<void> signOut()`
    - Mapear códigos do `FirebaseAuthException` (`user-not-found`, `wrong-password`, `invalid-credential`, `email-already-in-use`, `weak-password`, `invalid-email`, `network-request-failed`) para mensagens claras em português.
  - [ ] `FirestoreService` (stateless wrapper sobre `FirebaseFirestore.instance`):
    - Habilitar persistência offline: `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);`.
    - Expor operações genéricas/puras para coleções sob `users/{uid}/{collection}` e documento raiz `users/{uid}`: `watchCollection`, `watchDocument`, `getCollection`, `getDocument`, `setDocument`, `deleteDocument`, `runBatchDelete`.
- **Critérios de Aceite:** Services sem estado de domínio, zero lógica de UI, exceções tratadas e cache offline do Firestore habilitado.

---

### `ISSUE-N05` — Implementação dos 7 Repositórios Firebase (SSOT do Banco)
- **Branch:** `feat/n05-firestore-repositories`
- **Depende de:** `ISSUE-N02`, `ISSUE-N04`
- **Arquivos a criar:**
  - `lib/data/repositories/firebase_auth_repository.dart`
  - `lib/data/repositories/firestore_user_profile_repository.dart`
  - `lib/data/repositories/firestore_book_repository.dart`
  - `lib/data/repositories/firestore_shelf_repository.dart`
  - `lib/data/repositories/firestore_session_repository.dart`
  - `lib/data/repositories/firestore_note_repository.dart`
  - `lib/data/repositories/firestore_loan_repository.dart`
  - `lib/domain/use_cases/delete_book_use_case.dart`
- **Checklist Técnico:**
  - [ ] Cada Repository recebe `FirestoreService` e `AuthService` (`Repositories ↔ Services` permitido na `Aula_24` Slide 25; **nunca** injetar outro Repository dentro de um Repository!).
  - [ ] **Regra de Isolamento por Usuário (`uid`):** Nos métodos `watch*()`, observar `authStateChanges()` do `AuthService`: se `uid == null`, emitir lista vazia (`[]`) / `null`; se `uid != null`, fazer stream da coleção `users/$uid/...` e mapear para Domain Models. Isso garante que trocar de conta nunca misture dados.
  - [ ] Em `FirestoreBookRepository.saveBook(...)`: atualizar `updatedAt = DateTime.now()` antes de gravar.
  - [ ] Em `DeleteBookUseCase`: receber `BookRepository`, `NoteRepository`, `LoanRepository`, `SessionRepository` e remover o livro + todas as notas/empréstimos/sessões ligadas àquele `bookId`.
- **Critérios de Aceite:** Leitura, escrita, atualização, exclusão e streams reativos funcionando online e offline.

---

### `ISSUE-N06` — Feature `auth`, `AuthChecker`, `ThemeController` no Provider, `AppRoutes` e `ConfigureProviders`
- **Branch:** `feat/n06-auth-di-routes`
- **Depende de:** `ISSUE-N05`
- **Arquivos a criar/editar:**
  - `lib/core/di/configure_providers.dart`
  - `lib/core/routes/app_routes.dart`
  - `lib/core/theme/theme_controller.dart`
  - `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`
  - `lib/features/auth/presentation/widgets/auth_checker.dart`
  - `lib/features/auth/presentation/screens/auth_screen.dart`
  - `lib/main.dart`
- **Checklist Técnico:**
  - [ ] Criar `AuthViewModel extends ChangeNotifier` consumindo `AuthRepository` e `UserProfileRepository` (login, cadastro com validação de nome/email/senha mínima 6 caracteres, criação inicial do `UserProfileModel` no Firestore ao cadastrar, recuperação de senha, logout, `isLoading`, `errorMessage`).
  - [ ] Criar `AuthChecker` (baseado no `auth_checker.dart` do `taniro/auth_app_firebase`, adaptado para a `Aula_24` lendo `AuthRepository.watchAuthUserId()` via `Provider` — nunca `FirebaseAuth.instance` direto na View!): exibe loading inicial, `MainNavigationScreen` se logado, `AuthScreen` se deslogado.
  - [ ] Atualizar `AuthScreen` (preservando o design editorial existente em `auth_screen.dart`) para consumir `AuthViewModel`, mostrar loading no botão, `SnackBar` de erro/sucesso e modal/diálogo funcional para `"Esqueci a senha"`.
  - [ ] Migrar `ThemeController` para `ChangeNotifierProvider<ThemeController>` no `ConfigureProviders` e consumir em `main.dart` via `context.watch<ThemeController>()`.
  - [ ] Implementar `ConfigureProviders.createDependencyTree()` (padrão `todo_app_arch` + `auth_app_firebase`) registrando Services → Repositories → UseCases → ViewModels iniciais.
  - [ ] Atualizar `AppRoutes` com `onGenerateRoute`:
    - `AppRoutes.addBook` → recebe `BookModel?` em `settings.arguments`
    - `AppRoutes.bookDetails` → recebe `String` (`bookId`) em `settings.arguments`
    - `AppRoutes.tracker` → recebe `String?` (`bookId`) em `settings.arguments`
  - [ ] Atualizar `main.dart` seguindo `auth_app_firebase/lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, `final data = await ConfigureProviders.createDependencyTree()`, `runApp(BookyApp(data: data))` com `MultiProvider(providers: data.providers, ...)` e `home: const AuthChecker()`.
- **Critérios de Aceite:** Cadastrar cria usuário no Firebase Auth + `users/{uid}` no Firestore; fechar e reabrir app mantém sessão pelo `AuthChecker`; sair volta automaticamente para `AuthScreen`.

---

## Sprint 2 — Serviço de Notificações Locais & Integração DI

### `ISSUE-N07` — `NotificationService` (Agendamento de Devolução e Lembrete Diário)
- **Branch:** `feat/n07-notification-service`
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

### `ISSUE-N08` — Atualização do `ConfigureProviders` para Features da Sprint 2
- **Branch:** `feat/n08-di-sprint2`
- **Depende de:** Merge das issues Sprint 2 do Cleiton + `ISSUE-N07`
- **Arquivos alvo:**
  - `lib/core/di/configure_providers.dart`
  - `lib/core/routes/app_routes.dart`
- **Checklist Técnico:**
  - [ ] Registrar no `ConfigureProviders`: `BookApiService`, `OcrService`, `NotificationService`, `RegisterLoanUseCase`, `ReturnLoanUseCase` e `LibraryViewModel`.
  - [ ] Em `AppRoutes.onGenerateRoute`: instanciar `ChangeNotifierProvider` com escopo de tela para `AddBookViewModel` (`bookToEdit`) e `BookDetailsViewModel` (`bookId`) consumindo os serviços/repositórios/usecases já providos pelo `ConfigureProviders`.
  - [ ] Validar navegação ponta-a-ponta `LibraryScreen` → `AddBookScreen` e `LibraryScreen` → `BookDetailsScreen(bookId)`.

---

## Sprint 3 — Exportação (PDF/CSV), Meta Anual, Lembretes & Tela de Perfil

### `ISSUE-N09` — `ExportService` (PDF Unicode + CSV UTF-8 + Share) e `ExportLibraryUseCase`
- **Branch:** `feat/n09-export-pdf-csv`
- **Depende de:** `ISSUE-N05`
- **Arquivos a criar/editar:**
  - `assets/fonts/` (adicionar fonte `.ttf` com suporte Unicode PT-BR, ex.: `Roboto-Regular.ttf` e `Roboto-Bold.ttf`, declarando no `pubspec.yaml`)
  - `lib/data/services/export_service.dart`
  - `lib/domain/use_cases/export_library_use_case.dart`
- **Checklist Técnico:**
  - [ ] Definir `enum ExportScope { fullCatalog, wishlist }` e `enum ExportFormat { pdf, csv }`.
  - [ ] `ExportLibraryUseCase`: obtém livros de `BookRepository.getBooks()`; se `wishlist`, filtra `status == BookStatus.wantToRead`; se lista vazia, lança erro amigável; envia para `ExportService`.
  - [ ] `ExportService`:
    - **PDF (`pdf`):** carrega fonte `.ttf` de `assets/fonts/` via `rootBundle` para acentuação PT-BR; gera documento com Título, Autor, ISBN, Editora, Páginas, Status, Formato, Avaliação e Estantes/Tags; salva em `getTemporaryDirectory()` (`path_provider`) e compartilha via `share_plus`.
    - **CSV (`csv`):** cabeçalho em PT-BR, BOM UTF-8 (`\uFEFF`), `ListToCsvConverter`, salva arquivo temporário e compartilha via `share_plus`.
- **Critérios de Aceite:** PDF sem caracteres quebrados e CSV abrindo corretamente acentos e quebras de linha tanto para *Catálogo Completo* quanto para *Lista de Desejos*.

---

### `ISSUE-N10` — `ProfileViewModel` e Integração Completa da `ProfileScreen`
- **Branch:** `feat/n10-profile-feature`
- **Depende de:** `ISSUE-N06`, `ISSUE-N07`, `ISSUE-N09`
- **Arquivos a criar/editar:**
  - `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/core/di/configure_providers.dart` (registrar `ExportService`, `ExportLibraryUseCase`, `ProfileViewModel`, `SaveReadingSessionUseCase`, `GetDashboardStatsUseCase`, `HomeViewModel`)
  - `lib/core/routes/app_routes.dart` (garantir `ChangeNotifierProvider<TrackerViewModel>` com escopo de tela na rota `AppRoutes.tracker`)
- **Checklist Técnico:**
  - [ ] `ProfileViewModel extends ChangeNotifier`: consome `UserProfileRepository`, `AuthRepository`, `ExportLibraryUseCase`, `NotificationService` e `ThemeController`.
  - [ ] Exibir **nome real, iniciais e e-mail** do `UserProfileModel` (remover *"Arthur Pendelton"*).
  - [ ] **Metas de Leitura:** diálogo para editar `annualReadingGoal` (`> 0`), exibindo ano dinâmico `DateTime.now().year` (corrigir *"2024"* hardcoded!) e salvando no Firestore.
  - [ ] **Notificações e Lembretes:** seletor de horário + toggle para ativar/desativar lembrete diário (`UserProfileRepository.updateDailyReminder` + `NotificationService`).
  - [ ] **Exportar Dados:** diálogo escolhendo *Catálogo Completo* ou *Lista de Desejos* + *PDF* ou *CSV*, com indicador de progresso e `SnackBar`.
  - [ ] **Sincronização em Nuvem:** exibir status do backup Cloud Firestore (e-mail vinculado + botão *"Sincronizar / Verificar Nuvem"* consultando servidor quando online e mostrando data/hora da última verificação).
  - [ ] **Conta e Segurança:** editar nome do leitor e disparar redefinição de senha via `AuthRepository.resetPassword`.
  - [ ] **Sair da Biblioteca:** chamar `ProfileViewModel.signOut()` (o `AuthChecker` cuida da transição de volta ao login).
- **Critérios de Aceite:** Alterar meta anual ou nome no perfil reflete em tempo real na `HomeScreen`; exportação e lembretes operacionais.

---

## Sprint 4 — Testes Unitários, Auditoria, Regras Firestore & Release

### `ISSUE-N11` — Testes Unitários da Camada de Domínio, Auth, Empréstimos e Exportação
- **Branch:** `test/n11-unit-tests-natanael`
- **Arquivos a criar/editar:**
  - `test/domain/models_serialization_test.dart`
  - `test/domain/loan_overdue_test.dart`
  - `test/domain/export_library_use_case_test.dart`
  - `test/features/auth/auth_viewmodel_test.dart`
  - `test/widget_test.dart` (atualizar smoke test para o novo `BookyApp` / `MultiProvider` / `AuthChecker`)
- **Checklist Técnico:**
  - [ ] Testar `toJson`/`fromJson` dos 6 modelos (incluindo nulos e datas).
  - [ ] Testar `LoanModel.isOverdue` (no prazo, vence hoje, vencido, já devolvido).
  - [ ] Testar `ExportLibraryUseCase` com mocks (`fullCatalog` vs `wishlist` e lista vazia).
  - [ ] Testar geração de CSV válido em `ExportService`.
  - [ ] Testar `AuthViewModel` com `FakeAuthRepository` (login, cadastro, erro de credenciais).

---

### `ISSUE-N12` — Auditoria Final Firebase, Light/Dark Mode e Build Release
- **Branch:** `chore/n12-release-audit`
- **Checklist Técnico:**
  - [ ] Confirmar publicação e teste das `firestore.rules` no Firebase Console (usuário A bloqueado de acessar `users/userB`).
  - [ ] Auditar `AuthScreen` e `ProfileScreen` (e modais) no **Modo Claro** e **Modo Escuro** com `AppColors`.
  - [ ] Testar sincronização real entre **2 dispositivos/emuladores** logados na mesma conta.
  - [ ] Executar `flutter analyze`, `flutter test` e `flutter build apk --release`, validando instalação do APK final.
