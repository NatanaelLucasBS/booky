import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/book_api_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';
import '../viewmodels/add_book_viewmodel.dart';

/// Tela 07: Adicionar ou Editar Livro
/// Catalogação via scanner ótico de ISBN (câmera) ou formulário manual completo.
class AddBookScreen extends StatelessWidget {
  final BookModel? bookToEdit;

  const AddBookScreen({super.key, this.bookToEdit});

  @override
  Widget build(BuildContext context) {
    final argBook = bookToEdit ?? (ModalRoute.of(context)?.settings.arguments as BookModel?);

    return ChangeNotifierProvider(
      create: (ctx) => AddBookViewModel(
        bookRepository: ctx.read<BookRepository>(),
        shelfRepository: ctx.read<ShelfRepository>(),
        bookApiService: ctx.read<BookApiService>(),
        initialBook: argBook,
      )..loadShelves(),
      child: const _AddBookContent(),
    );
  }
}

class _AddBookContent extends StatefulWidget {
  const _AddBookContent();

  @override
  State<_AddBookContent> createState() => _AddBookContentState();
}

class _AddBookContentState extends State<_AddBookContent> {
  final _isbnQuickController = TextEditingController();
  final _isbnManualController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _genreController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _tagInputController = TextEditingController();

  MobileScannerController? _scannerController;
  bool _isScannerPaused = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _isbnQuickController.dispose();
    _isbnManualController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _genreController.dispose();
    _coverUrlController.dispose();
    _synopsisController.dispose();
    _tagInputController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _syncControllersWithViewModel(AddBookViewModel vm) {
    if (!_controllersInitialized && vm.initialBook != null) {
      _titleController.text = vm.title;
      _authorController.text = vm.author;
      _publisherController.text = vm.publisher ?? '';
      _yearController.text = vm.publishedYear?.toString() ?? '';
      _pagesController.text = vm.totalPages > 0 ? vm.totalPages.toString() : '';
      _genreController.text = vm.genre ?? '';
      _coverUrlController.text = vm.coverUrl ?? '';
      _synopsisController.text = vm.synopsis ?? '';
      _isbnQuickController.text = vm.isbn;
      _isbnManualController.text = vm.isbn;
      _controllersInitialized = true;
    }
  }

  Future<void> _handleIsbnLookup(String isbn) async {
    final vm = context.read<AddBookViewModel>();
    final success = await vm.lookupByIsbn(isbn);
    if (!mounted) return;

    if (success) {
      _isbnQuickController.text = vm.isbn;
      _isbnManualController.text = vm.isbn;
      _titleController.text = vm.title;
      _authorController.text = vm.author;
      _publisherController.text = vm.publisher ?? '';
      _yearController.text = vm.publishedYear?.toString() ?? '';
      _pagesController.text = vm.totalPages > 0 ? vm.totalPages.toString() : '';
      _genreController.text = vm.genre ?? '';
      _coverUrlController.text = vm.coverUrl ?? '';
      _synopsisController.text = vm.synopsis ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro localizado pelo ISBN! Revise os dados abaixo.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      // Retoma scanner caso tenha falhado
      _isScannerPaused = false;
      _scannerController?.start();
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isScannerPaused) return;

    final vm = context.read<AddBookViewModel>();
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty && vm.isValidIsbn(raw)) {
        setState(() => _isScannerPaused = true);
        await _scannerController?.stop();
        await _handleIsbnLookup(raw);
        break;
      }
    }
  }

  Future<void> _onSave() async {
    final vm = context.read<AddBookViewModel>();

    vm.setIsbn(_isbnManualController.text);
    vm.setTitle(_titleController.text);
    vm.setAuthor(_authorController.text);
    vm.setPublisher(_publisherController.text);
    vm.setPublishedYear(int.tryParse(_yearController.text.trim()));
    vm.setTotalPages(int.tryParse(_pagesController.text.trim()) ?? 0);
    vm.setGenre(_genreController.text);
    vm.setCoverUrl(_coverUrlController.text);
    vm.setSynopsis(_synopsisController.text);

    final success = await vm.saveBook();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${vm.title}" salvo com sucesso na sua biblioteca!'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      Navigator.of(context).pop();
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: AppColors.darkBrown,
        ),
      );
    }
  }

  void _showCreateShelfDialog(BuildContext context, AddBookViewModel vm) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Nova Estante Temática'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da Estante (ex: Favoritos, Sci-Fi)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await vm.createShelf(nameCtrl.text, descCtrl.text);
                  if (context.mounted) Navigator.of(dialogCtx).pop();
                }
              },
              child: const Text('CRIAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddBookViewModel>();
    _syncControllersWithViewModel(vm);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = vm.initialBook != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Livro' : 'Adicionar Livro'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Control de Modo (somente no cadastro novo)
              if (!isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModeTab(
                          title: 'ESCANEAR CÓDIGO',
                          isSelected: vm.activeMode == 0,
                          onTap: () {
                            vm.setMode(0);
                            setState(() => _isScannerPaused = false);
                            _scannerController?.start();
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildModeTab(
                          title: 'CADASTRO MANUAL',
                          isSelected: vm.activeMode == 1,
                          onTap: () {
                            vm.setMode(1);
                            setState(() => _isScannerPaused = true);
                            _scannerController?.stop();
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Conteúdo do Modo
              if (!isEditing && vm.activeMode == 0)
                _buildScannerView(vm, theme, isDark)
              else
                _buildManualView(vm, theme, isDark, isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }

  // --- MODO 1: SCANNER COM CÂMERA REAL ---
  Widget _buildScannerView(AddBookViewModel vm, ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Visor de Câmera Real com Cantos e Linha Laser
        Container(
          width: 260,
          height: 260,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.woodBrown.withValues(alpha: 0.4) : AppColors.beige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Câmera MobileScanner Real com tratamento seguro de erro/permissão
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (context, error, child) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off_outlined,
                            size: 36,
                            color: isDark ? AppColors.beige : AppColors.woodBrown,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Câmera indisponível ou permissão negada.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => vm.setMode(1),
                            child: const Text(
                              'USAR CADASTRO MANUAL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Cantoneiras estéticas do visor Stitch
              Positioned(
                top: 10,
                left: 10,
                child: _buildCorner(isTop: true, isLeft: true, isDark: isDark),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildCorner(isTop: true, isLeft: false, isDark: isDark),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: _buildCorner(isTop: false, isLeft: true, isDark: isDark),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: _buildCorner(isTop: false, isLeft: false, isDark: isDark),
              ),

              // Linha Laser Horizontal
              Container(
                width: 200,
                height: 1.5,
                color: isDark ? AppColors.lightCream.withValues(alpha: 0.8) : AppColors.darkBrown.withValues(alpha: 0.8),
              ),

              // Indicador de Carregamento ao buscar ISBN
              if (vm.isLookingUp)
                Container(
                  color: AppColors.darkBrown.withValues(alpha: 0.72),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.lightCream),
                  ),
                ),
            ],
          ),
        ),

        Text(
          'Posicione o código de barras ou ISBN dentro do quadro',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        const SizedBox(height: 24),

        // Digitação rápida de ISBN
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'OU DIGITE O ISBN',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _isbnQuickController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: '978-85-325-1101-0',
            suffixIcon: vm.isLookingUp
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                    onPressed: () {
                      final text = _isbnQuickController.text.trim();
                      if (text.isNotEmpty) _handleIsbnLookup(text);
                    },
                  ),
          ),
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) _handleIsbnLookup(text.trim());
          },
        ),
      ],
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft, required bool isDark}) {
    final color = isDark ? AppColors.lightCream : AppColors.darkBrown;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 2.5) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 2.5) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 2.5) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 2.5) : BorderSide.none,
        ),
      ),
    );
  }

  // --- MODO 2: CADASTRO MANUAL / EDIÇÃO ---
  Widget _buildManualView(
    AddBookViewModel vm,
    ThemeData theme,
    bool isDark,
    bool isEditing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pré-visualização da Capa se houver coverUrl
        if (_coverUrlController.text.trim().isNotEmpty)
          Center(
            child: Container(
              width: 100,
              height: 150,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.woodBrown : AppColors.beige,
                  width: 1.0,
                ),
                color: isDark ? AppColors.woodBrown : AppColors.beige.withValues(alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  _coverUrlController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: AppColors.mediumBrown,
                  ),
                ),
              ),
            ),
          ),

        _buildFieldLabel('Título do Livro *'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Ex: Dom Casmurro',
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Autor'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Machado de Assis',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ISBN (10 ou 13 dígitos)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _isbnManualController,
                    decoration: InputDecoration(
                      hintText: 'Ex: 9788532511010',
                      suffixIcon: IconButton(
                        tooltip: 'Buscar dados pelo ISBN',
                        icon: const Icon(Icons.search, size: 18),
                        onPressed: () {
                          final raw = _isbnManualController.text.trim();
                          if (raw.isNotEmpty) _handleIsbnLookup(raw);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Total de Páginas'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pagesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 256',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Gênero Literário'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _genreController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Romance',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Editora'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _publisherController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Companhia das Letras',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Ano de Publicação'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 1899',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildFieldLabel('URL da Imagem da Capa'),
        const SizedBox(height: 6),
        TextField(
          controller: _coverUrlController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'https://exemplo.com/capa.jpg',
          ),
        ),

        const SizedBox(height: 16),

        _buildFieldLabel('Formato do Livro (Tema 6)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'Físico',
                isSelected: vm.format == BookFormat.physical,
                onTap: () => vm.setFormat(BookFormat.physical),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: 'Digital (E-book)',
                isSelected: vm.format == BookFormat.digital,
                onTap: () => vm.setFormat(BookFormat.digital),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status Canônicos do Tema 6 (4 opções mutuamente exclusivas)
        _buildFieldLabel('Status na Estante'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip('Quero Ler', BookStatus.wantToRead, vm.status, vm, isDark),
            _buildStatusChip('Lendo', BookStatus.reading, vm.status, vm, isDark),
            _buildStatusChip('Lido', BookStatus.read, vm.status, vm, isDark),
            _buildStatusChip('Abandonado', BookStatus.abandoned, vm.status, vm, isDark),
          ],
        ),

        const SizedBox(height: 20),

        // Estantes Temáticas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('Estantes Temáticas'),
            TextButton.icon(
              onPressed: () => _showCreateShelfDialog(context, vm),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('NOVA ESTANTE', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        if (vm.availableShelves.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Nenhuma estante temática criada. Clique em "Nova Estante" para organizar por temas.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.availableShelves.map((shelf) {
              final isSelected = vm.selectedShelfIds.contains(shelf.id);
              return FilterChip(
                label: Text(shelf.name),
                selected: isSelected,
                onSelected: (_) => vm.toggleShelf(shelf.id),
                selectedColor: isDark ? AppColors.lightCream : AppColors.darkBrown,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? (isDark ? AppColors.darkBrown : AppColors.lightCream)
                      : (isDark ? AppColors.lightCream : AppColors.darkBrown),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // Tags Customizadas
        _buildFieldLabel('Tags Customizadas'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: 'Adicionar tag (ex: clássico, nacional)',
                ),
                onSubmitted: (tag) {
                  if (tag.trim().isNotEmpty) {
                    vm.addTag(tag);
                    _tagInputController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () {
                final tag = _tagInputController.text.trim();
                if (tag.isNotEmpty) {
                  vm.addTag(tag);
                  _tagInputController.clear();
                }
              },
            ),
          ],
        ),
        if (vm.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                onDeleted: () => vm.removeTag(tag),
                deleteIconColor: isDark ? AppColors.beige : AppColors.mediumBrown,
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 20),

        _buildFieldLabel('Sinopse'),
        const SizedBox(height: 6),
        TextField(
          controller: _synopsisController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Breve resumo ou sinopse da obra...',
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: vm.isSaving ? null : _onSave,
          child: vm.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightCream),
                )
              : Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR NA ESTANTE'),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.woodBrown,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveBorder = isDark ? AppColors.woodBrown : AppColors.beige;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.8,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    BookStatus status,
    BookStatus currentStatus,
    AddBookViewModel vm,
    bool isDark,
  ) {
    final isSelected = currentStatus == status;
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveBorder = isDark ? AppColors.woodBrown : AppColors.beige;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: () => vm.setStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? activeBg : inactiveBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.8,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
