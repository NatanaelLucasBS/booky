import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/backup_sync_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';
import '../../../../domain/use_cases/export_library_use_case.dart';
import '../../../../domain/use_cases/restore_backup_use_case.dart';
import '../viewmodels/library_viewmodel.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../widgets/export_data_sheet.dart';
import '../widgets/shelves_manager_sheet.dart';

/// Tela 03: Minha Biblioteca
/// Estante pessoal completa com filtros por status, pesquisa dinâmica,
/// busca avançada combinada, gestão de estantes e tags de livros emprestados/atrasados.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        ExportLibraryUseCase? exportUseCase;
        BackupSyncService? backupService;
        RestoreBackupUseCase? restoreUseCase;
        try {
          exportUseCase = ctx.read<ExportLibraryUseCase>();
        } catch (_) {}
        try {
          backupService = ctx.read<BackupSyncService>();
        } catch (_) {}
        try {
          restoreUseCase = ctx.read<RestoreBackupUseCase>();
        } catch (_) {}

        return LibraryViewModel(
          bookRepository: ctx.read<BookRepository>(),
          loanRepository: ctx.read<LoanRepository>(),
          shelfRepository: ctx.read<ShelfRepository>(),
          exportLibraryUseCase: exportUseCase,
          backupSyncService: backupService,
          restoreBackupUseCase: restoreUseCase,
        );
      },
      child: const _LibraryContent(),
    );
  }
}

class _LibraryContent extends StatefulWidget {
  const _LibraryContent();

  @override
  State<_LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<_LibraryContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAdvancedFilters(BuildContext context, LibraryViewModel vm) {
    AdvancedFilterSheet.show(
      context,
      currentFilters: vm.advancedFilters,
      shelves: vm.shelves,
      onApply: (filters) => vm.setAdvancedFilters(filters),
      onClear: () => vm.clearAdvancedFilters(),
    );
  }

  void _openShelvesManager(BuildContext context, LibraryViewModel vm) {
    ShelvesManagerSheet.show(
      context,
      shelves: vm.shelves,
      selectedShelfId: vm.selectedShelfId,
      onSelectShelf: (id) => vm.setSelectedShelf(id),
      onCreateShelf: (name, desc) => vm.createShelf(name, desc),
      onEditShelf: (shelf, name, desc) => vm.updateShelf(shelf, name, desc),
      onDeleteShelf: (id) => vm.deleteShelf(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final books = vm.filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Exportação & Backup',
            onPressed: () => ExportDataSheet.show(
              context,
              onExport: vm.exportLibrary,
              onBackup: vm.exportBackup,
              onRestore: vm.restoreBackup,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shelves),
            tooltip: 'Estantes Temáticas',
            onPressed: () => _openShelvesManager(context, vm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addBook),
        backgroundColor: isDark ? AppColors.lightCream : AppColors.darkBrown,
        foregroundColor: isDark ? AppColors.darkBrown : AppColors.lightCream,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
      body: Column(
        children: [
          // Campo de Busca com Botão de Filtros Avançados
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => vm.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título ou autor...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                vm.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.tune, size: 20),
                      onPressed: () => _openAdvancedFilters(context, vm),
                    ),
                    if (vm.advancedFilters.count > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            vm.advancedFilters.count.toString(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkBrown : AppColors.lightCream,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Seletor de Estante Temática Ativa (se houver)
          if (vm.selectedShelfId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'ESTANTE: ',
                    style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
                  ),
                  Chip(
                    label: Text(
                      vm.shelves.where((s) => s.id == vm.selectedShelfId).firstOrNull?.name ?? 'Estante',
                    ),
                    onDeleted: () => vm.setSelectedShelf(null),
                  ),
                ],
              ),
            ),

          // Segmented / Chips de Filtro Rápido
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                _buildFilterChip('TODOS', 'all', vm.totalCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('LENDO', 'reading', vm.readingCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('LIDOS', 'read', vm.readCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('QUERO LER', 'wantToRead', vm.wantToReadCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('ABANDONADOS', 'abandoned', vm.abandonedCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('EMPRESTADOS', 'loaned', vm.loanedCount, vm, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('ATRASADOS', 'overdue', vm.overdueCount, vm, isDark),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Acervo / Grid de Livros
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? _buildEmptyState(theme, isDark, vm)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return _buildBookCard(context, book, vm, isDark, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    int count,
    LibraryViewModel vm,
    bool isDark,
  ) {
    final isSelected = vm.quickFilter == value;
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveBorder = isDark ? AppColors.woodBrown : AppColors.beige;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: () => vm.setQuickFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? activeBg : inactiveBorder,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.6,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    BookModel book,
    LibraryViewModel vm,
    bool isDark,
    ThemeData theme,
  ) {
    final isLoaned = vm.isBookLoaned(book.id);
    final isOverdue = vm.isBookOverdue(book.id);
    final loan = vm.getActiveLoanForBook(book.id);

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.bookDetails,
          arguments: book.id,
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capa expandida no espaço disponível com Fita Marcadora
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
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
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, _, _) => _buildPlaceholderCover(book, isDark),
                          )
                        : _buildPlaceholderCover(book, isDark),
                  ),
                ),

                // Fita Marcadora no Canto Superior Direito
                Positioned(
                  top: 0,
                  right: 12,
                  child: Container(
                    width: 14,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                    ),
                  ),
                ),

                // Badge de Status de Empréstimo
                if (isOverdue)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkBrown,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.lightCream, width: 1.0),
                      ),
                      child: const Text(
                        'ATRASADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.lightCream,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  )
                else if (isLoaned)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.woodBrown : AppColors.beige,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'EMPRESTADO${loan != null ? ": ${loan.borrowerName.split(' ').first}" : ""}'
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Título
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),

          // Autor
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.beige : AppColors.woodBrown,
            ),
          ),

          const SizedBox(height: 4),

          // Barra de Progresso ou Status
          if (book.status == BookStatus.reading && book.totalPages > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: book.progressPercent,
                  minHeight: 2.5,
                  backgroundColor: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.5),
                  color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.currentPage} de ${book.totalPages} pág (${(book.progressPercent * 100).toInt()}%)',
                  style: const TextStyle(fontSize: 9, color: AppColors.mediumBrown),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  book.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.beige : AppColors.mediumBrown,
                  ),
                ),
                if (book.rating != null && book.rating! > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < book.rating!.round() ? Icons.star : Icons.star_border,
                        size: 11,
                        color: isDark ? AppColors.lightCream : AppColors.woodBrown,
                      );
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover(BookModel book, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 32,
              color: (isDark ? AppColors.beige : AppColors.mediumBrown).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.lightCream : AppColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, LibraryViewModel vm) {
    final hasFilters = vm.searchQuery.isNotEmpty ||
        vm.quickFilter != 'all' ||
        vm.selectedShelfId != null ||
        !vm.advancedFilters.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: isDark ? AppColors.woodBrown : AppColors.beige,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Nenhum livro corresponde aos filtros selecionados'
                  : 'Sua biblioteca ainda está vazia',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Tente ajustar ou limpar os filtros de busca para visualizar seu acervo.'
                  : 'Comece adicionando livros pelo código de barras ou preenchendo o formulário manual.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (hasFilters)
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                  vm.setQuickFilter('all');
                  vm.setSelectedShelf(null);
                  vm.clearAdvancedFilters();
                },
                child: const Text('LIMPAR TODOS OS FILTROS'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addBook),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADICIONAR PRIMEIRO LIVRO'),
              ),
          ],
        ),
      ),
    );
  }
}
