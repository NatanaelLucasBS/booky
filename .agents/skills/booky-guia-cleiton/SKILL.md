---
name: booky-guia-cleiton
description: >-
  Guia e fluxo de trabalho exclusivo para a IA do Cleiton (BookApiService Google
  Books e Open Library, OcrService ML Kit, AddBookScreen com mobile_scanner,
  LibraryScreen com busca avancada e estantes, BookDetailsScreen com emprestimos
  e diario OCR, ReadingTrackerScreen com cronometro e estimativa, e HomeScreen
  com fl_chart). Ative quando Cleiton pedir para implementar qualquer ISSUE-C01
  a ISSUE-C09.
---

# Skill: Guia de Desenvolvimento — CLEITON (`ISSUE-C01` a `ISSUE-C09`)

Ative esta skill quando estiver ajudando o **Cleiton** a implementar suas tarefas no projeto **BOOKY**.

## 1. Fronteira Estrita de Arquivos do Cleiton

Você **SÓ PODE** criar ou editar arquivos dentro do domínio do Cleiton:
- `lib/data/services/book_api_service.dart`
- `lib/data/services/ocr_service.dart`
- `lib/domain/use_cases/save_reading_session_use_case.dart`
- `lib/domain/use_cases/get_dashboard_stats_use_case.dart`
- `lib/domain/use_cases/register_loan_use_case.dart`
- `lib/domain/use_cases/return_loan_use_case.dart`
- `lib/features/home/**`
- `lib/features/library/**`
- `lib/features/tracker/**`
- `lib/features/book_details/**`
- `test/fakes/**`, `test/data/book_api_service_test.dart`, `test/features/{library,tracker}/**`, `test/domain/{save_reading_session,get_dashboard_stats,register_loan}_use_case_test.dart`

> **PROIBIDO:** Nunca edite pastas do Natanael (`lib/domain/models/**`, `lib/domain/repositories/**`, `lib/data/repositories/**`, `lib/data/services/{storage,backup_sync,notification,export}_service.dart`, `lib/features/{auth,profile}/**`, `lib/core/di/**`, `pubspec.yaml`, `android/**`) sem alinhar antes, e nunca implemente uma Issue que o Cleiton ainda não pediu.

## 2. Regras de Ouro para as Issues do Cleiton

1. **Consumo da Camada de Dados Abstraída:**
   - Seus `ViewModels` e `UseCases` consomem apenas as interfaces de `lib/domain/repositories/` (`BookRepository`, `ShelfRepository`, `SessionRepository`, `NoteRepository`, `LoanRepository`, `UserProfileRepository`) e `NotificationService`.
   - Nunca acesse banco de dados ou `StorageService` diretamente nas telas ou nos `ViewModels`.
2. **Catalogação ISBN (`ISSUE-C01` e `ISSUE-C03`):**
   - `BookApiService` é **stateless** e recebe `http.Client?` opcional no construtor para testes. Consulta Google Books API e faz fallback automático na Open Library API.
   - Em `add_book_screen.dart`, corrija os chips de status: troque `'Emprestado'` por **`Abandonado`** (`BookStatus.abandoned`) e inclua o seletor de formato (`Físico` / `Digital`), editora, ano, sinopse, capa, estantes e tags.
3. **Biblioteca e Busca Avançada (`ISSUE-C04`):**
   - Remova a lista hardcoded `_allBooks` de `library_screen.dart`.
   - Combine filtros (`AND`) no `LibraryViewModel`: autor, gênero, ano, status, avaliação mínima (`1..5`), estante e tag, além dos filtros rápidos de `Emprestados` e `Atrasados`.
4. **Detalhes, Diário com OCR e Empréstimos (`ISSUE-C05`):**
   - Empréstimo exige: `borrowerName`, `borrowerContact`, `loanDate` e `expectedReturnDate`. Use `RegisterLoanUseCase` (que valida 1 empréstimo ativo por livro e agenda notificação no `NotificationService`) e `ReturnLoanUseCase`.
   - Diário com **3 abas**: `Anotações` (`NoteType.note`), `Citações` (`NoteType.quote`) e `Resenha` (`NoteType.review` + estrelas `1..5`).
   - Botão de OCR usa `OcrService` (`image_picker` + `google_mlkit_text_recognition`), preenche o texto editável e apaga o arquivo temporário da foto.
5. **Rastreador e Cronômetro (`ISSUE-C06`):**
   - Cronômetro baseado em `DateTime? _runningSince` + `_accumulatedSeconds` (não perde tempo em segundo plano).
   - Suporte atualização tanto por **página atual** quanto por **porcentagem (`0..100%`)**, calcule estimativa de tempo restante sem `NaN`/`Infinity` e salve via `SaveReadingSessionUseCase`.
6. **Dashboard e Gráficos (`ISSUE-C07`):**
   - Use `GetDashboardStatsUseCase` para agregar livros lidos por mês (`finishedAt`), páginas lidas por mês (`dateKey`), meta anual dinâmica e alerta de empréstimos atrasados, renderizando gráficos `fl_chart` com a paleta `AppColors`.

## 3. Procedimento por Issue

1. Leia a seção correspondente da Issue solicitada em [`TASKS_CLEITON.md`](../../../TASKS_CLEITON.md) e os contratos em [`PLANO_DESENVOLVIMENTO.md`](../../../PLANO_DESENVOLVIMENTO.md).
2. Implemente **apenas** os arquivos listados naquela Issue.
3. Rode `flutter analyze` e `flutter test` para validar que nada quebrou.
