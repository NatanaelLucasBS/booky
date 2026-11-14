---
name: booky-guia-natanael
description: >-
  Guia e fluxo de trabalho exclusivo para a IA do Natanael (Setup Android e
  pubspec, Modelos e Contratos de Dominio, StorageService abstraido, 7
  Repositories SSOT, ConfigureProviders, AppRoutes, NotificationService,
  ExportService PDF/CSV, BackupSyncService, Auth e Profile). Ative quando
  Natanael pedir para implementar qualquer ISSUE-N01 a ISSUE-N11.
---

# Skill: Guia de Desenvolvimento — NATANAEL (`ISSUE-N01` a `ISSUE-N11`)

Ative esta skill quando estiver ajudando o **Natanael** a implementar suas tarefas no projeto **BOOKY**.

## 1. Fronteira Estrita de Arquivos do Natanael

Você **SÓ PODE** criar ou editar arquivos dentro do domínio do Natanael:
- `pubspec.yaml`, `android/**`, `assets/fonts/**`
- `lib/main.dart`
- `lib/core/di/configure_providers.dart`
- `lib/core/routes/app_routes.dart`
- `lib/core/theme/theme_controller.dart`
- `lib/core/utils/command.dart`
- `lib/domain/models/**` (Todos os 6 modelos + `enums.dart`)
- `lib/domain/repositories/**` (As 7 interfaces abstratas)
- `lib/domain/use_cases/delete_book_use_case.dart`
- `lib/domain/use_cases/export_library_use_case.dart`
- `lib/domain/use_cases/sync_backup_use_case.dart`
- `lib/data/services/storage_service.dart`
- `lib/data/services/backup_sync_service.dart`
- `lib/data/services/notification_service.dart`
- `lib/data/services/export_service.dart`
- `lib/data/repositories/**` (As 7 implementações SSOT)
- `lib/features/auth/**`
- `lib/features/profile/**`
- `test/domain/**`, `test/features/auth/**`, `test/widget_test.dart`

> **PROIBIDO:** Nunca altere `lib/features/{home,library,tracker,book_details}/**` nem `lib/data/services/{book_api,ocr}_service.dart` (domínio do Cleiton), e nunca implemente uma Issue que o Natanael ainda não pediu.

## 2. Regras de Ouro para as Issues do Natanael

1. **Zero Firebase:** Não instale nem importe `firebase_core`, `firebase_auth` ou `cloud_firestore`.
2. **Persistência Abstraída (`ISSUE-N03` e `ISSUE-N04`):**
   - Implemente `StorageService` com interface limpa (`getAll`, `getById`, `upsert`, `delete`, `replaceCollection`, `clearCollection`) + implementação local (`LocalJsonStorageService` via `path_provider` e `InMemoryStorageService` para testes).
   - Cada um dos 7 `Repositories` injeta `StorageService`, mantém um `StreamController.broadcast()` emitindo a lista atualizada a cada mutação (SSOT) e **nunca** injeta outro `Repository`.
3. **Exclusão em Cascata (`DeleteBookUseCase`):**
   - Como `BookRepository` não pode depender de `NoteRepository`, `LoanRepository` ou `SessionRepository` (Slide 23 da `Aula_24`), a exclusão em cascata é feita no `DeleteBookUseCase`.
4. **Exportação PDF/CSV (`ISSUE-N08`):**
   - No PDF (`pdf`), carregue fonte `.ttf` Unicode para suportar acentuação em português (`ç`, `ã`, `é`).
   - No CSV (`csv`), inclua BOM UTF-8 (`\uFEFF`) para abrir sem erros de acentuação no Excel/ Planilhas.
   - Suporte ambos os escopos pedidos no Tema 6: *Catálogo Completo* (`fullCatalog`) e *Lista de Desejos* (`wishlist` -> `BookStatus.wantToRead`).
5. **Perfil (`ISSUE-N09`):**
   - Remova o nome hardcoded `"Arthur Pendelton"` e o ano `"2024"` de `profile_screen.dart`, usando `UserProfileModel` e `DateTime.now().year`.

## 3. Procedimento por Issue

1. Leia a seção correspondente da Issue solicitada em [`TASKS_NATANAEL.md`](../../../TASKS_NATANAEL.md) e os contratos em [`PLANO_DESENVOLVIMENTO.md`](../../../PLANO_DESENVOLVIMENTO.md).
2. Implemente **apenas** os arquivos listados naquela Issue.
3. Rode `flutter analyze` e `flutter test` para validar que nada quebrou.
