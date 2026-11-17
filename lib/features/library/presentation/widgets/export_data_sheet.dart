import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/export_service.dart';

/// Modal bottom sheet para Exportação (PDF/CSV) e Backup JSON no padrão Stitch.
class ExportDataSheet extends StatefulWidget {
  final Future<void> Function({
    required ExportScope scope,
    required ExportFormat format,
  }) onExport;
  final Future<void> Function() onBackup;
  final Future<int> Function(String rawJson) onRestore;

  const ExportDataSheet({
    super.key,
    required this.onExport,
    required this.onBackup,
    required this.onRestore,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function({
      required ExportScope scope,
      required ExportFormat format,
    }) onExport,
    required Future<void> Function() onBackup,
    required Future<int> Function(String rawJson) onRestore,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ExportDataSheet(
        onExport: onExport,
        onBackup: onBackup,
        onRestore: onRestore,
      ),
    );
  }

  @override
  State<ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends State<ExportDataSheet> {
  ExportScope _selectedScope = ExportScope.fullCatalog;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho Editorial
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXPORTAÇÃO & BACKUP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gere relatórios da sua biblioteca ou faça um backup completo de todos os seus dados.',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 20),

            // Seleção de Escopo
            Text(
              'ESCOPO DOS DADOS',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            ...ExportScope.values.map((scope) {
              final isSelected = scope == _selectedScope;
              return InkWell(
                onTap: () => setState(() => _selectedScope = scope),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                            : AppColors.mediumBrown,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        scope.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Seleção de Formato
            Text(
              'FORMATO DO ARQUIVO',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            ...ExportFormat.values.map((fmt) {
              final isSelected = fmt == _selectedFormat;
              return InkWell(
                onTap: () => setState(() => _selectedFormat = fmt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                            : AppColors.mediumBrown,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        fmt.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Botão Principal: Exportar Relatório
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleExport,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share, size: 16),
              label: const Text('EXPORTAR E COMPARTILHAR'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 12),

            // Botão Secundário: Backup Completo JSON
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _handleBackup,
              icon: const Icon(Icons.backup_outlined, size: 16),
              label: const Text('FAZER BACKUP COMPLETO (JSON)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 10),

            // Botão Terciário: Restaurar Backup JSON
            TextButton.icon(
              onPressed: _isProcessing ? null : () => _showRestoreDialog(context),
              icon: const Icon(Icons.restore_outlined, size: 16),
              label: const Text('RESTAURAR BACKUP (JSON)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onExport(
        scope: _selectedScope,
        format: _selectedFormat,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório gerado com sucesso!'),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('StateError: ', '')),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onBackup();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup JSON gerado com sucesso!'),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar backup: $e'),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRestoreDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Restaurar Backup (JSON)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cole abaixo o conteúdo do arquivo JSON de backup gerado pelo Booky:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jsonCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{"version": "1.0.0", "collections": { ... }}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = jsonCtrl.text.trim();
              if (raw.isEmpty) return;
              Navigator.of(ctx).pop();
              await _handleRestore(raw);
            },
            child: const Text('RESTAURAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(String rawJson) async {
    setState(() => _isProcessing = true);
    try {
      final count = await widget.onRestore(rawJson);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup restaurado com sucesso ($count registros)!'),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar backup: $e'),
            backgroundColor: AppColors.woodBrown,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
