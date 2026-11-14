# Diretrizes Obrigatórias para Agentes de IA — Projeto BOOKY (Tema 6)

Você está atuando no projeto **BOOKY** da disciplina de **Programação para Dispositivos Móveis (UFRN — Prof. Taniro Chacon Rodrigues)**.

## 1. Documentos de Verdade Absoluta (Consulte ANTES de programar)

- **[`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md):** Regras de negócio do **Tema 6**, arquitetura obrigatória da **`Aula_24`** e **Contratos Canônicos de Dados, Repositórios e Rotas (Seção 4)**.
- **[`TASKS_NATANAEL.md`](./TASKS_NATANAEL.md):** Backlog exclusivo do **Natanael** (`ISSUE-N01` a `ISSUE-N11`).
- **[`TASKS_CLEITON.md`](./TASKS_CLEITON.md):** Backlog exclusivo do **Cleiton** (`ISSUE-C01` a `ISSUE-C09`).

## 2. Regras Anti-Alucinação (PROIBIDO VIOLAR)

1. **ZERO FIREBASE:** O Tema 6 **não** usa Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google-services.json`, `flutterfire`). **NUNCA** adicione pacotes ou código de Firebase. A persistência é abstraída via `StorageService` e `BackupSyncService`.
2. **NÃO TOME TASKS DE OUTRA ISSUE OU DO OUTRO DESENVOLVEDOR:**
   - Implemente **estritamente** a Issue que o desenvolvedor pedir.
   - Se o desenvolvedor for **Natanael**, toque apenas nos arquivos `[NATANAEL]` (`lib/core/`, `lib/domain/models/`, `lib/domain/repositories/`, `lib/data/repositories/`, `lib/data/services/{storage,backup_sync,notification,export}_service.dart`, `lib/features/auth/`, `lib/features/profile/`).
   - Se o desenvolvedor for **Cleiton**, toque apenas nos arquivos `[CLEITON]` (`lib/data/services/{book_api,ocr}_service.dart`, `lib/domain/use_cases/{save_reading_session,get_dashboard_stats,register_loan,return_loan}_use_case.dart`, `lib/features/{home,library,tracker,book_details}/`).
3. **NÃO RENOMEIE CONTRATOS:** Os nomes de classes, enums (`BookStatus`, `BookFormat`, `NoteType`), campos de modelos, métodos de repositórios e rotas (`AppRoutes`) estão congelados na **Seção 4 do `PLANO_DESENVOLVIMENTO.md`**.
4. **ARQUITETURA ESTRITA (`Aula_24_-_Arqutietura_Recomendada.pdf`):**
   - **View (`Screens` / `Widgets`):** Zero lógica de negócio, zero chamadas diretas a `Service` ou `http`. Apenas observa `context.watch<ViewModel>()` e dispara comandos `context.read<ViewModel>()`.
   - **ViewModel (`ChangeNotifier`):** Relação **1:1** com sua View (Slide 15). Consome `Repositories` e/ou `UseCases`.
   - **Repository (SSOT):** Fonte única de verdade para 1 tipo de dado (Slide 22). **PROIBIDO um `Repository` depender de outro `Repository` (Slide 23).**
   - **UseCase (`lib/domain/use_cases/`):** Usado sempre que uma operação precisar combinar mais de um `Repository` ou `Service` (Slide 23 e 27).
   - **Service (`lib/data/services/`):** Camada mais baixa, **100% stateless** (Slide 25).
   - **Injeção de Dependências:** Centralizada em `ConfigureProviders.createDependencyTree()` (`lib/core/di/configure_providers.dart`).
5. **PALETA DE CORES ESTRITA (`AppColors`) & DESIGN STITCH DO CLEITON:**
   - Use exclusivamente os 5 tons de `lib/core/theme/app_colors.dart` (`darkBrown`, `woodBrown`, `mediumBrown`, `beige`, `lightCream`). Nunca invente `Colors.blue`, `Colors.red`, `Colors.green`, etc.
   - **Preserve 100% do Design Editorial criado pelo Cleiton no Stitch** nas 7 telas existentes (`borderRadius: BorderRadius.circular(4)`, bordas finas `1.0px`, tipografia Serif nos títulos, labels em uppercase com `letterSpacing`, segmented controls editoriais, capas 2:3 com fita marcadora e moldura de scanner com cantoneiras). Ao conectar `ViewModels` ou adicionar modais/gráficos do Tema 6, mantenha exatamente essa estética.
