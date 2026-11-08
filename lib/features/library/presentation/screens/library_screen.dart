import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 03: Minha Biblioteca
/// Estante pessoal completa com filtros por status, pesquisa dinâmica,
/// tags de livros emprestados e atalho flutuante para adicionar novos exemplares.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allBooks = [
    {
      'title': 'O Nome do Vento',
      'author': 'Patrick Rothfuss',
      'category': 'reading',
      'isLoaned': false,
      'color': AppColors.mediumBrown,
    },
    {
      'title': 'Cem Anos de Solidão',
      'author': 'Gabriel García Márquez',
      'category': 'read',
      'isLoaned': true,
      'loanedTo': 'Mariana Silva',
      'color': AppColors.woodBrown,
    },
    {
      'title': 'Duna',
      'author': 'Frank Herbert',
      'category': 'reading',
      'isLoaned': false,
      'color': AppColors.darkBrown,
    },
    {
      'title': 'Stoner',
      'author': 'John Williams',
      'category': 'read',
      'isLoaned': false,
      'color': AppColors.mediumBrown,
    },
    {
      'title': 'Uma Vida Pequena',
      'author': 'Hanya Yanagihara',
      'category': 'to-read',
      'isLoaned': true,
      'loanedTo': 'Carlos Eduardo',
      'color': AppColors.woodBrown,
    },
    {
      'title': 'Piranesi',
      'author': 'Susanna Clarke',
      'category': 'to-read',
      'isLoaned': false,
      'color': AppColors.darkBrown,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.toLowerCase();
    final filteredBooks = _allBooks.where((book) {
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'loaned' ? book['isLoaned'] == true : book['category'] == _selectedFilter);
      final matchesQuery = query.isEmpty ||
          (book['title'] as String).toLowerCase().contains(query) ||
          (book['author'] as String).toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Biblioteca'),
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
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por título ou autor...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.mediumBrown),
              ),
            ),
          ),

          // Chips de Filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Todos (84)', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Lendo (3)', 'reading', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Lidos (18)', 'read', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Quero Ler (38)', 'to-read', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Emprestados (4)', 'loaned', isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid de Livros
          Expanded(
            child: filteredBooks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppColors.mediumBrown),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum livro encontrado',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Não encontramos correspondências com estes termos na sua estante.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return _buildBookCard(context, book, isDark, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;

    final selectedBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final selectedFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final unselectedFg = isDark ? AppColors.beige : AppColors.woodBrown;
    final unselectedBorder = isDark ? AppColors.woodBrown : AppColors.beige;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? selectedBg : unselectedBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.8,
            color: isSelected ? selectedFg : unselectedFg,
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    Map<String, dynamic> book,
    bool isDark,
    ThemeData theme,
  ) {
    final bool isLoaned = book['isLoaned'] ?? false;
    final String? loanedTo = book['loanedTo'];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.bookDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capa com proporção 2:3
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: book['color'] as Color? ?? AppColors.woodBrown,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColors.mediumBrown : AppColors.beige,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(1, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book, color: AppColors.lightCream, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            book['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.lightCream,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tag de Emprestado (Requisito Explícito)
                if (isLoaned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.darkBrown,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.beige, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz, size: 10, color: AppColors.lightCream),
                          const SizedBox(width: 3),
                          Text(
                            'EMPRESTADO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.lightCream,
                              fontSize: 8,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Título e Autor
          Text(
            book['title'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isLoaned && loanedTo != null ? 'Com $loanedTo' : (book['author'] as String),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLoaned ? (isDark ? AppColors.beige : AppColors.mediumBrown) : null,
              fontStyle: isLoaned ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
