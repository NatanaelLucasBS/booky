---
name: booky-contratos-tema6
description: >-
  Contratos canonicos de dados, modelos, enums, interfaces de repositorios,
  regras de negocio dos 7 requisitos funcionais do Tema 6 e paleta AppColors do
  BOOKY. Ative ao implementar qualquer Model, Repository, UseCase, ViewModel ou
  Widget do Tema 6 para evitar alucinacao de campos, status ou cores.
---

# Skill: Contratos Canônicos & Regras do Tema 6 — BOOKY

Use esta skill sempre que implementar ou revisar funcionalidades do **Tema 6 (App de Biblioteca Pessoal e Rastreamento de Leitura)**. Nunca invente campos, enums ou assinaturas fora deste contrato.

## 1. Enums Oficiais (`lib/domain/models/enums.dart`)

- `enum BookStatus { wantToRead, reading, read, abandoned }`
  - **ATENÇÃO:** *Emprestado* **NÃO** é um `BookStatus`! Empréstimo é controlado por `LoanModel` (`isReturned == false`).
- `enum BookFormat { physical, digital }`
- `enum NoteType { note, quote, review }`

Serialização obrigatória: usar `.name` (`'wantToRead'`, `'reading'`, `'read'`, `'abandoned'`, `'physical'`, `'digital'`, `'note'`, `'quote'`, `'review'`).

## 2. Regras de Negócio dos 7 Requisitos Funcionais (Tema 6)

1. **RF1 — Catalogação por ISBN (Scanner + API):**
   - Normalizar ISBN removendo `-` e espaços (aceitar 10 ou 13 dígitos).
   - Pausar `mobile_scanner` ao detectar ISBN válido para evitar múltiplas chamadas HTTP.
   - Consultar Google Books API primeiro; se faltar dados ou não achar, fazer fallback automático na Open Library API.
   - Preencher formulário manual (`AddBookScreen`) para revisão do usuário antes de salvar.
2. **RF2 — Estantes, Formato e Status:**
   - 4 status: *Quero Ler, Lendo, Lido, Abandonado*.
   - Ao mudar para `reading` pela 1ª vez: `startedAt ??= DateTime.now()`.
   - Ao mudar para `read`: `finishedAt = DateTime.now()` e, se `totalPages > 0`, `currentPage = totalPages`.
   - `finishedAt` é o único campo usado para contar *"livros lidos por mês"* nos gráficos.
3. **RF3 — Rastreador de Progresso e Sessões:**
   - Suportar atualização por **página atual** OU **porcentagem (`0..100%`)**: `page = ((pct / 100) * totalPages).round().clamp(0, totalPages)`.
   - Cronômetro resiliente a background usando `DateTime activeStartedAt` + `accumulatedSeconds`.
   - `pagesRead = max(0, endPage - startPage)` e `dateKey = 'YYYY-MM-DD'`.
   - Estimativa de tempo restante baseada em `pagesPerHour` das sessões (tratar `totalPages == 0` ou `pagesPerHour == 0` sem `NaN`/`Infinity`).
4. **RF4 — Diário de Citações, Anotações e Resenhas (com OCR):**
   - 3 abas em `BookDetailsScreen`: `Anotações` (`NoteType.note`), `Citações` (`NoteType.quote`) e `Resenha` (`NoteType.review` + avaliação `1..5` estrelas).
   - OCR local via `image_picker` + `google_mlkit_text_recognition` (`TextRecognitionScript.latin`), preenchendo o campo de texto editável e deletando a foto temporária em seguida.
5. **RF5 — Controle de Empréstimos:**
   - Campos obrigatórios: `borrowerName`, `borrowerContact`, `loanDate`, `expectedReturnDate` (`>= loanDate`).
   - Máximo de 1 empréstimo ativo (`!isReturned`) por livro.
   - Getter de atraso: `bool get isOverdue => !isReturned && DateTime.now().isAfter(DateTime(expectedReturnDate.year, expectedReturnDate.month, expectedReturnDate.day, 23, 59, 59));`.
   - Exibir badge visual `ATRASADO` + agendar notificação local via `NotificationService` (cancelando na devolução).
6. **RF6 — Busca Avançada e Estatísticas (`fl_chart`):**
   - Filtros combinados (`AND`): autor, gênero, ano, status, avaliação mínima (`1..5`), estante (`shelfId`) e tag.
   - Gráficos mensais na `HomeScreen`: livros lidos por mês (`finishedAt`) e páginas lidas por mês (`ReadingSessionModel.pagesRead` por `dateKey`), mais progresso da meta anual dinâmica (`DateTime.now().year`).
7. **RF7 — Persistência Abstraída, Backup e Exportação (`PDF` e `CSV`):**
   - Persistência via `StorageService` e backup/sincronização via `BackupSyncService` (zero Firebase).
   - Exportação com escolha de escopo (*Catálogo Completo* ou *Lista de Desejos* `wantToRead`) e formato (*PDF* com fonte Unicode `.ttf` ou *CSV* com BOM UTF-8 `\uFEFF`), compartilhando via `share_plus`.

## 3. Design System, Paleta Estrita (`AppColors`) & Padrão Stitch do Cleiton

Use apenas os 5 tons definidos em `lib/core/theme/app_colors.dart`:
- `AppColors.darkBrown` (`#2E2A24`)
- `AppColors.woodBrown` (`#5A4633`)
- `AppColors.mediumBrown` (`#8A6B4A`)
- `AppColors.beige` (`#C7AD84`)
- `AppColors.lightCream` (`#F2E7D4`)

**Regras de Fidelidade ao Protótipo Stitch (criado pelo Cleiton):**
- **Não descaracterize as 7 telas existentes:** Ao refatorar para `ViewModel` ou adicionar campos novos do Tema 6, preserve a estrutura visual já construída nas telas.
- **Containers e Cards:** `borderRadius: BorderRadius.circular(4)` (ou `2` em tags/barras), `Border.all(color: isDark ? AppColors.mediumBrown : AppColors.beige, width: 1.0)`, fundo `AppColors.woodBrown` (no escuro) ou `AppColors.beige.withOpacity(0.2..0.35)` (no claro).
- **Rótulos e Cabeçalhos de Seção:** Sempre em `.toUpperCase()`, `fontSize: 10..11`, `fontWeight: FontWeight.w600`, `letterSpacing: 0.8..1.5`.
- **Segmented Controls / Chips:** Seguir exatamente o padrão de abas de `auth_screen.dart`, `add_book_screen.dart` e `profile_screen.dart` (fundo ativo `lightCream` no escuro / `darkBrown` no claro).
- **Capas de Livros:** Proporção `2:3` com fita marcadora no topo direito (`Positioned(top: 0, right: ..., child: Container(color: AppColors.darkBrown))`) e fallback editorial com `Icons.auto_stories` / `Icons.menu_book` quando o livro não tiver `coverUrl`.

Todas as telas e componentes devem funcionar tanto no **Modo Claro** quanto no **Modo Escuro**.

## 4. Referência Completa de Campos e Assinaturas

Para conferir os nomes exatos de todos os campos de `UserProfileModel`, `BookModel`, `ShelfModel`, `ReadingSessionModel`, `NoteModel`, `LoanModel` e as assinaturas exatas dos 7 `Repositories`, leia a **Seção 4** de [`PLANO_DESENVOLVIMENTO.md`](../../../PLANO_DESENVOLVIMENTO.md).
