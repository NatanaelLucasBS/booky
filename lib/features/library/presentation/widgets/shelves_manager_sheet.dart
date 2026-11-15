import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/shelf_model.dart';

/// Modal para gerenciar estantes temáticas (listar, criar, editar e excluir).
class ShelvesManagerSheet extends StatefulWidget {
  final List<ShelfModel> shelves;
  final String? selectedShelfId;
  final void Function(String? shelfId) onSelectShelf;
  final Future<void> Function(String name, String? description) onCreateShelf;
  final Future<void> Function(ShelfModel shelf, String name, String? description)? onEditShelf;
  final Future<void> Function(String shelfId) onDeleteShelf;

  const ShelvesManagerSheet({
    super.key,
    required this.shelves,
    required this.selectedShelfId,
    required this.onSelectShelf,
    required this.onCreateShelf,
    this.onEditShelf,
    required this.onDeleteShelf,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ShelfModel> shelves,
    required String? selectedShelfId,
    required void Function(String? shelfId) onSelectShelf,
    required Future<void> Function(String name, String? description) onCreateShelf,
    Future<void> Function(ShelfModel shelf, String name, String? description)? onEditShelf,
    required Future<void> Function(String shelfId) onDeleteShelf,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShelvesManagerSheet(
        shelves: shelves,
        selectedShelfId: selectedShelfId,
        onSelectShelf: onSelectShelf,
        onCreateShelf: onCreateShelf,
        onEditShelf: onEditShelf,
        onDeleteShelf: onDeleteShelf,
      ),
    );
  }

  @override
  State<ShelvesManagerSheet> createState() => _ShelvesManagerSheetState();
}

class _ShelvesManagerSheetState extends State<ShelvesManagerSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    await widget.onCreateShelf(name, _descCtrl.text.trim());
    _nameCtrl.clear();
    _descCtrl.clear();
    if (mounted) setState(() => _isCreating = false);
  }

  void _showEditDialog(BuildContext context, ShelfModel shelf) {
    final nameCtrl = TextEditingController(text: shelf.name);
    final descCtrl = TextEditingController(text: shelf.description ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar Estante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome da Estante'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
              final clean = nameCtrl.text.trim();
              if (clean.isNotEmpty && widget.onEditShelf != null) {
                await widget.onEditShelf!(shelf, clean, descCtrl.text);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                if (mounted) setState(() {});
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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

            Text(
              'GERENCIAR ESTANTES TEMÁTICAS',
              style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),

            // Campo de criação rápida
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nome da nova estante...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isCreating ? null : _handleCreate,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opção "Todas as estantes"
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                widget.selectedShelfId == null ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                size: 20,
              ),
              title: const Text('Todas as Estantes'),
              onTap: () {
                widget.onSelectShelf(null);
                Navigator.of(context).pop();
              },
            ),

            const Divider(),

            // Lista de Estantes Existentes
            if (widget.shelves.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nenhuma estante customizada criada ainda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...widget.shelves.map((shelf) {
                final isSelected = widget.selectedShelfId == shelf.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                    size: 20,
                  ),
                  title: Text(shelf.name),
                  subtitle: shelf.description != null ? Text(shelf.description!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEditShelf != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: isDark ? AppColors.beige : AppColors.mediumBrown,
                          onPressed: () => _showEditDialog(context, shelf),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: isDark ? AppColors.beige : AppColors.mediumBrown,
                        onPressed: () async {
                          await widget.onDeleteShelf(shelf.id);
                          if (context.mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    widget.onSelectShelf(shelf.id);
                    Navigator.of(context).pop();
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
