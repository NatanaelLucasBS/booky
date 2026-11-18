import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/shelf_model.dart';
import '../viewmodels/library_viewmodel.dart';

/// Modal de Busca Avançada combinando filtros por Autor, Gênero, Ano,
/// Status, Avaliação Mínima, Estante e Tag.
class AdvancedFilterSheet extends StatefulWidget {
  final AdvancedFilters currentFilters;
  final List<ShelfModel> shelves;
  final void Function(AdvancedFilters filters) onApply;
  final VoidCallback onClear;

  const AdvancedFilterSheet({
    super.key,
    required this.currentFilters,
    required this.shelves,
    required this.onApply,
    required this.onClear,
  });

  static Future<void> show(
    BuildContext context, {
    required AdvancedFilters currentFilters,
    required List<ShelfModel> shelves,
    required void Function(AdvancedFilters filters) onApply,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdvancedFilterSheet(
        currentFilters: currentFilters,
        shelves: shelves,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late final TextEditingController _authorCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _tagCtrl;

  BookStatus? _selectedStatus;
  double? _selectedMinRating;
  String? _selectedShelfId;

  @override
  void initState() {
    super.initState();
    _authorCtrl = TextEditingController(text: widget.currentFilters.author ?? '');
    _genreCtrl = TextEditingController(text: widget.currentFilters.genre ?? '');
    _yearCtrl = TextEditingController(
      text: widget.currentFilters.publishedYear?.toString() ?? '',
    );
    _tagCtrl = TextEditingController(text: widget.currentFilters.tag ?? '');
    _selectedStatus = widget.currentFilters.status;
    _selectedMinRating = widget.currentFilters.minRating;
    _selectedShelfId = widget.currentFilters.shelfId;
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _genreCtrl.dispose();
    _yearCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final filters = AdvancedFilters(
      author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
      genre: _genreCtrl.text.trim().isEmpty ? null : _genreCtrl.text.trim(),
      publishedYear: int.tryParse(_yearCtrl.text.trim()),
      status: _selectedStatus,
      minRating: _selectedMinRating,
      shelfId: _selectedShelfId,
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
    );

    widget.onApply(filters);
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onClear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBrown : AppColors.lightCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.woodBrown : AppColors.beige,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.woodBrown : AppColors.beige,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BUSCA AVANÇADA',
                    style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: const Text('LIMPAR', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Autor
              _buildLabel('Autor'),
              const SizedBox(height: 4),
              TextField(
                controller: _authorCtrl,
                decoration: const InputDecoration(hintText: 'Ex: Machado de Assis'),
              ),
              const SizedBox(height: 12),

              // Gênero & Ano
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gênero'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _genreCtrl,
                          decoration: const InputDecoration(hintText: 'Ex: Romance'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Ano de Publicação'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Ex: 1899'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status
              _buildLabel('Status de Leitura'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildStatusFilterChip('Todos', null, isDark),
                  _buildStatusFilterChip('Quero Ler', BookStatus.wantToRead, isDark),
                  _buildStatusFilterChip('Lendo', BookStatus.reading, isDark),
                  _buildStatusFilterChip('Lido', BookStatus.read, isDark),
                  _buildStatusFilterChip('Abandonado', BookStatus.abandoned, isDark),
                ],
              ),
              const SizedBox(height: 14),

              // Avaliação Mínima
              _buildLabel('Avaliação Mínima'),
              const SizedBox(height: 6),
              Row(
                children: [1, 2, 3, 4, 5].map((star) {
                  final isSelected = _selectedMinRating != null && _selectedMinRating! >= star;
                  return IconButton(
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_selectedMinRating == star.toDouble()) {
                          _selectedMinRating = null;
                        } else {
                          _selectedMinRating = star.toDouble();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Estante Temática
              if (widget.shelves.isNotEmpty) ...[
                _buildLabel('Estante Temática'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedShelfId,
                  decoration: const InputDecoration(hintText: 'Selecione uma estante'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas as estantes')),
                    ...widget.shelves.map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedShelfId = val),
                ),
                const SizedBox(height: 12),
              ],

              // Tag
              _buildLabel('Tag Customizada'),
              const SizedBox(height: 4),
              TextField(
                controller: _tagCtrl,
                decoration: const InputDecoration(hintText: 'Ex: clássico, favorito'),
              ),
              const SizedBox(height: 24),

              // Botão Aplicar
              ElevatedButton(
                onPressed: _apply,
                child: const Text('APLICAR FILTROS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.woodBrown,
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, BookStatus? status, bool isDark) {
    final isSelected = _selectedStatus == status;
    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveBorder = isDark ? AppColors.woodBrown : AppColors.beige;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.6,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
