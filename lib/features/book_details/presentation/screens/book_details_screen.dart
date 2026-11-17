import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/ocr_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/note_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/note_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';
import '../../../../domain/use_cases/delete_book_use_case.dart';
import '../../../../domain/use_cases/register_loan_use_case.dart';
import '../../../../domain/use_cases/return_loan_use_case.dart';
import '../viewmodels/book_details_viewmodel.dart';
import '../widgets/loan_dialog.dart';
import '../widgets/note_editor_dialog.dart';

/// Tela 05: Detalhes do Livro
/// Ficha catalográfica completa, controle de empréstimos, diário de leitura
/// com 3 abas (Anotações, Citações com OCR e Resenha) e atalho para o rastreador.
class BookDetailsScreen extends StatelessWidget {
  final String? bookId;

  const BookDetailsScreen({super.key, this.bookId});

  @override
  Widget build(BuildContext context) {
    final id = bookId ?? (ModalRoute.of(context)?.settings.arguments as String?);

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Livro')),
        body: const Center(child: Text('Livro não encontrado.')),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => BookDetailsViewModel(
        bookId: id,
        bookRepository: ctx.read<BookRepository>(),
        noteRepository: ctx.read<NoteRepository>(),
        loanRepository: ctx.read<LoanRepository>(),
        shelfRepository: ctx.read<ShelfRepository>(),
        ocrService: ctx.read<OcrService>(),
        registerLoanUseCase: ctx.read<RegisterLoanUseCase>(),
        returnLoanUseCase: ctx.read<ReturnLoanUseCase>(),
        deleteBookUseCase: ctx.read<DeleteBookUseCase>(),
      ),
      child: const _BookDetailsContent(),
    );
  }
}

class _BookDetailsContent extends StatefulWidget {
  const _BookDetailsContent();

  @override
  State<_BookDetailsContent> createState() => _BookDetailsContentState();
}

class _BookDetailsContentState extends State<_BookDetailsContent> {
  bool _isSynopsisExpanded = false;
  int _activeTabIndex = 0; // 0: Anotações, 1: Citações, 2: Resenha

  void _confirmDeleteBook(BuildContext context, BookDetailsViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Excluir Livro'),
          content: Text(
            'Tem certeza de que deseja remover "${vm.book?.title ?? 'este livro'}" da sua estante? Todas as anotações, histórico de sessões e empréstimos serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final success = await vm.deleteBook();
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Livro excluído com sucesso.'),
                      backgroundColor: AppColors.darkBrown,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('EXCLUIR', style: TextStyle(color: AppColors.lightCream)),
            ),
          ],
        );
      },
    );
  }

  void _openLoanDialog(BuildContext context, BookDetailsViewModel vm) {
    LoanDialog.show(
      context,
      onConfirm: ({
        required borrowerName,
        required borrowerContact,
        required loanDate,
        required expectedReturnDate,
      }) async {
        return await vm.registerLoan(
          borrowerName: borrowerName,
          borrowerContact: borrowerContact,
          loanDate: loanDate,
          expectedReturnDate: expectedReturnDate,
        );
      },
    );
  }

  void _openNoteEditor(
    BuildContext context,
    BookDetailsViewModel vm,
    NoteType type, {
    NoteModel? existingNote,
  }) {
    NoteEditorDialog.show(
      context,
      type: type,
      existingNote: existingNote,
      onOcrCapture: (source) => vm.extractTextFromOcr(source: source),
      onSave: ({required type, required content, chapter, page, noteId}) async {
        await vm.saveNote(
          type: type,
          content: content,
          chapter: chapter,
          page: page,
          noteId: noteId,
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookDetailsViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (vm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final book = vm.book;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Livro não encontrado')),
        body: const Center(child: Text('Este livro não foi localizado no acervo.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Livro',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.addBook,
                arguments: book,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir Livro',
            onPressed: () => _confirmDeleteBook(context, vm),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBrown : AppColors.lightCream,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.woodBrown : AppColors.beige,
              width: 1.0,
            ),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed(
              AppRoutes.tracker,
              arguments: book.id,
            );
          },
          icon: const Icon(Icons.timer_outlined, size: 20),
          label: Text(
            book.status == BookStatus.read
                ? 'REVER SESSÕES DE LEITURA'
                : 'CONTINUAR LEITURA',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho Principal: Capa + Dados Básicos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capa 2:3
                Container(
                  width: 110,
                  height: 165,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColors.woodBrown : AppColors.beige,
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholderCover(book, isDark),
                          )
                        : _buildPlaceholderCover(book, isDark),
                  ),
                ),
                const SizedBox(width: 16),

                // Dados Principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.headlineSmall?.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.beige : AppColors.woodBrown,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Estrelas Interativas de Avaliação (1 a 5)
                      Row(
                        children: [1, 2, 3, 4, 5].map((star) {
                          final currentRating = book.rating ?? 0.0;
                          final isFilled = currentRating >= star;
                          return GestureDetector(
                            onTap: () => vm.updateRating(star.toDouble()),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                isFilled ? Icons.star : Icons.star_border,
                                size: 20,
                                color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Badges de Status e Formato
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(book.status.label.toUpperCase(), isDark),
                          _buildBadge(book.format.label.toUpperCase(), isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Card de Empréstimo
            _buildLoanSection(context, vm, theme, isDark),

            const SizedBox(height: 20),

            // Ficha Catalográfica e Metadados
            _buildSectionHeader('Ficha Catalográfica', theme, isDark),
            const SizedBox(height: 8),
            _buildMetadataGrid(book, vm, theme, isDark),

            const SizedBox(height: 20),

            // Sinopse
            if (book.synopsis != null && book.synopsis!.isNotEmpty) ...[
              _buildSectionHeader('Sinopse', theme, isDark),
              const SizedBox(height: 8),
              Text(
                book.synopsis!,
                maxLines: _isSynopsisExpanded ? null : 4,
                overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    _isSynopsisExpanded ? 'LER MENOS' : 'LER MAIS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Diário de Leitura com 3 Abas Editoriais
            _buildDiarySection(context, vm, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.woodBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: isDark ? AppColors.lightCream : AppColors.darkBrown,
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BookModel book, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 32,
            color: (isDark ? AppColors.beige : AppColors.mediumBrown).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- SEÇÃO DE EMPRÉSTIMO ---
  Widget _buildLoanSection(
    BuildContext context,
    BookDetailsViewModel vm,
    ThemeData theme,
    bool isDark,
  ) {
    final loan = vm.activeLoan;

    if (loan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? AppColors.woodBrown : AppColors.beige,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVRO NA SUA ESTANTE', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text('Disponível para empréstimo', style: theme.textTheme.bodySmall),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _openLoanDialog(context, vm),
                  icon: const Icon(Icons.share, size: 14),
                  label: const Text('EMPRESTAR', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          if (vm.returnedLoans.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReturnedLoansHistory(vm, theme, isDark),
          ],
        ],
      );
    }

    final isOverdue = loan.isOverdue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOverdue
                ? AppColors.darkBrown.withValues(alpha: 0.12)
                : (isDark
                    ? AppColors.woodBrown.withValues(alpha: 0.3)
                    : AppColors.beige.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isOverdue
                  ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                  : (isDark ? AppColors.woodBrown : AppColors.beige),
              width: isOverdue ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning_amber : Icons.bookmark_border,
                        size: 18,
                        color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOverdue ? 'EMPRÉSTIMO ATRASADO' : 'LIVRO EMPRESTADO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Devolução: ${_formatDate(loan.expectedReturnDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Emprestado para: ${loan.borrowerName}${loan.borrowerContact.isNotEmpty ? " (${loan.borrowerContact})" : ""}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Desde: ${_formatDate(loan.loanDate)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => vm.returnLoan(),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('REGISTRAR DEVOLUÇÃO'),
              ),
            ],
          ),
        ),
        if (vm.returnedLoans.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildReturnedLoansHistory(vm, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildReturnedLoansHistory(
    BookDetailsViewModel vm,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown.withValues(alpha: 0.15) : AppColors.beige.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTÓRICO DE EMPRÉSTIMOS (${vm.returnedLoans.length})',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          ...vm.returnedLoans.take(3).map((item) {
            final retDate = item.returnedDate != null ? _formatDate(item.returnedDate!) : '—';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${item.borrowerName} (${_formatDate(item.loanDate)} → devolvido em $retDate)',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- METADADOS CATALOGRÁFICOS ---
  Widget _buildMetadataGrid(
    BookModel book,
    BookDetailsViewModel vm,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown.withValues(alpha: 0.25) : AppColors.beige.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildMetaRow('ISBN', book.isbn ?? 'Não catalogado', theme),
          _buildMetaRow('Editora', book.publisher ?? 'Não informada', theme),
          _buildMetaRow('Ano de Publicação', book.publishedYear?.toString() ?? '—', theme),
          _buildMetaRow('Total de Páginas', book.totalPages > 0 ? '${book.totalPages} páginas' : '—', theme),
          _buildMetaRow('Gênero', book.genre ?? 'Geral', theme),
          if (vm.bookShelves.isNotEmpty)
            _buildMetaRow(
              'Estantes',
              vm.bookShelves.map((s) => s.name).join(', '),
              theme,
            ),
          if (book.tags.isNotEmpty)
            _buildMetaRow(
              'Tags',
              book.tags.map((t) => '#$t').join(' '),
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // --- DIÁRIO COM 3 ABAS: ANOTAÇÕES, CITAÇÕES (OCR) E RESENHA ---
  Widget _buildDiarySection(
    BuildContext context,
    BookDetailsViewModel vm,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DIÁRIO DO LIVRO',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add, size: 16),
              tooltip: 'Adicionar registro',
              onPressed: () {
                final type = _activeTabIndex == 0
                    ? NoteType.note
                    : _activeTabIndex == 1
                        ? NoteType.quote
                        : NoteType.review;
                _openNoteEditor(context, vm, type);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tabs Segmented: Anotações | Citações | Resenha
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton('Anotações (${vm.plainNotes.length})', 0, isDark),
              ),
              Expanded(
                child: _buildTabButton('Citações (${vm.quotes.length})', 1, isDark),
              ),
              Expanded(
                child: _buildTabButton(
                  vm.review != null ? 'Resenha ★' : 'Resenha',
                  2,
                  isDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Conteúdo da Aba Ativa
        if (_activeTabIndex == 0)
          _buildNotesList(context, vm, vm.plainNotes, NoteType.note, theme, isDark)
        else if (_activeTabIndex == 1)
          _buildNotesList(context, vm, vm.quotes, NoteType.quote, theme, isDark)
        else
          _buildReviewTab(context, vm, theme, isDark),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    final isSelected = _activeTabIndex == index;
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    BookDetailsViewModel vm,
    List<NoteModel> items,
    NoteType type,
    ThemeData theme,
    bool isDark,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                type == NoteType.quote ? Icons.format_quote : Icons.edit_note,
                size: 36,
                color: isDark ? AppColors.woodBrown : AppColors.beige,
              ),
              const SizedBox(height: 8),
              Text(
                type == NoteType.quote
                    ? 'Nenhuma citação registrada ainda.\nCapture trechos físicos usando a câmera com OCR!'
                    : 'Nenhuma anotação registrada ainda.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.map((note) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? AppColors.woodBrown : AppColors.beige,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    [
                      if (note.chapter != null) note.chapter!,
                      if (note.page != null) 'Pág. ${note.page}',
                    ].join(' • '),
                    style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _openNoteEditor(context, vm, type, existingNote: note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => vm.deleteNote(note.id),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                type == NoteType.quote ? '“${note.content}”' : note.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: type == NoteType.quote ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewTab(
    BuildContext context,
    BookDetailsViewModel vm,
    ThemeData theme,
    bool isDark,
  ) {
    final review = vm.review;

    if (review == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(Icons.rate_review_outlined, size: 36, color: AppColors.mediumBrown),
              const SizedBox(height: 8),
              const Text('Nenhuma resenha final registrada para esta obra.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openNoteEditor(context, vm, NoteType.review),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ESCREVER RESENHA'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown.withValues(alpha: 0.2) : AppColors.beige.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.woodBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESENHA CRÍTICA',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _openNoteEditor(context, vm, NoteType.review, existingNote: review),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => vm.deleteNote(review.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.woodBrown : AppColors.beige,
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}
