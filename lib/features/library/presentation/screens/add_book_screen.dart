import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 07: Adicionar Livro
/// Suporte a escaneamento ótico de código de barras / ISBN e cadastro manual detalhado.
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  int _activeMode = 0; // 0: Escanear Código, 1: Cadastro Manual

  final _isbnQuickController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _genreController = TextEditingController();

  String _selectedStatus = 'to-read';

  @override
  void dispose() {
    _isbnQuickController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  void _lookupISBN() {
    final query = _isbnQuickController.text.trim();
    if (query.isEmpty) return;

    // Simulação de busca rápida na base de dados de livros
    setState(() {
      _activeMode = 1; // Transita para o modo manual preenchido
      _titleController.text = 'O Nome do Vento';
      _authorController.text = 'Patrick Rothfuss';
      _pagesController.text = '656';
      _genreController.text = 'Fantasia Épica';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Livro localizado pelo ISBN! Revise os dados abaixo.'),
        backgroundColor: AppColors.darkBrown,
      ),
    );
  }

  void _saveBook() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe ao menos o título do livro.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${_titleController.text}" adicionado à sua biblioteca!'),
        backgroundColor: AppColors.darkBrown,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Livro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented Control de Modo
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      title: 'ESCANEAR CÓDIGO',
                      isSelected: _activeMode == 0,
                      onTap: () => setState(() => _activeMode = 0),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildModeTab(
                      title: 'CADASTRO MANUAL',
                      isSelected: _activeMode == 1,
                      onTap: () => setState(() => _activeMode = 1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conteúdo do Modo Selecionado
            if (_activeMode == 0) _buildScannerView(theme, isDark) else _buildManualView(theme, isDark),
          ],
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

  // --- MODO 1: SCANNER ---
  Widget _buildScannerView(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Visor de Câmera com Cantos e Linha Laser
        Container(
          width: 250,
          height: 250,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.woodBrown.withOpacity(0.4) : AppColors.beige.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cantoneiras estéticas do visor
              Positioned(
                top: 12,
                left: 12,
                child: _buildCorner(isTop: true, isLeft: true, isDark: isDark),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildCorner(isTop: true, isLeft: false, isDark: isDark),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: _buildCorner(isTop: false, isLeft: true, isDark: isDark),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: _buildCorner(isTop: false, isLeft: false, isDark: isDark),
              ),

              // Ícone central atenuado
              Icon(
                Icons.qr_code_scanner,
                size: 70,
                color: (isDark ? AppColors.beige : AppColors.mediumBrown).withOpacity(0.3),
              ),

              // Linha Laser Horizontal
              Container(
                width: 190,
                height: 1.5,
                color: isDark ? AppColors.beige : AppColors.woodBrown,
              ),
            ],
          ),
        ),

        Text(
          'Posicione o código de barras ou ISBN dentro do quadro',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        const SizedBox(height: 32),

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
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '978-85-8057-340-4',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward, size: 20),
              color: isDark ? AppColors.lightCream : AppColors.darkBrown,
              onPressed: _lookupISBN,
            ),
          ),
          onSubmitted: (_) => _lookupISBN(),
        ),
      ],
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft, required bool isDark}) {
    final color = isDark ? AppColors.lightCream : AppColors.darkBrown;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 2.0) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 2.0) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 2.0) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 2.0) : BorderSide.none,
        ),
      ),
    );
  }

  // --- MODO 2: MANUAL ---
  Widget _buildManualView(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Título do Livro'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Ex: Memórias Póstumas de Brás Cubas',
          ),
        ),

        const SizedBox(height: 16),

        _buildFieldLabel('Autor'),
        const SizedBox(height: 6),
        TextField(
          controller: _authorController,
          decoration: const InputDecoration(
            hintText: 'Ex: Machado de Assis',
          ),
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
                      hintText: 'Ex: 312',
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
                      hintText: 'Ex: Romance Clássico',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildFieldLabel('Status Inicial na Estante'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip('Quero Ler', 'to-read', isDark),
            _buildStatusChip('Lendo', 'reading', isDark),
            _buildStatusChip('Lido', 'read', isDark),
            _buildStatusChip('Emprestado', 'loaned', isDark),
          ],
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _saveBook,
          child: const Text('SALVAR NA ESTANTE'),
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

  Widget _buildStatusChip(String label, String value, bool isDark) {
    final isSelected = _selectedStatus == value;
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveBorder = isDark ? AppColors.woodBrown : AppColors.beige;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
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
