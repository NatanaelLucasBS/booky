import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/note_model.dart';

/// Diálogo para criar ou editar Anotação, Citação (com suporte a OCR via câmera) ou Resenha.
class NoteEditorDialog extends StatefulWidget {
  final NoteType type;
  final NoteModel? existingNote;
  final Future<String?> Function(ImageSource source) onOcrCapture;
  final Future<void> Function({
    required NoteType type,
    required String content,
    String? chapter,
    int? page,
    String? noteId,
  }) onSave;

  const NoteEditorDialog({
    super.key,
    required this.type,
    this.existingNote,
    required this.onOcrCapture,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required NoteType type,
    NoteModel? existingNote,
    required Future<String?> Function(ImageSource source) onOcrCapture,
    required Future<void> Function({
      required NoteType type,
      required String content,
      String? chapter,
      int? page,
      String? noteId,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => NoteEditorDialog(
        type: type,
        existingNote: existingNote,
        onOcrCapture: onOcrCapture,
        onSave: onSave,
      ),
    );
  }

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _contentCtrl;
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _pageCtrl;
  bool _isOcrLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.existingNote?.content ?? '');
    _chapterCtrl = TextEditingController(text: widget.existingNote?.chapter ?? '');
    _pageCtrl = TextEditingController(
      text: widget.existingNote?.page != null ? widget.existingNote!.page.toString() : '',
    );
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _chapterCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleOcr(ImageSource source) async {
    setState(() => _isOcrLoading = true);
    final text = await widget.onOcrCapture(source);
    if (mounted) {
      setState(() => _isOcrLoading = false);
      if (text != null && text.isNotEmpty) {
        if (_contentCtrl.text.trim().isEmpty) {
          _contentCtrl.text = text;
        } else {
          _contentCtrl.text = '${_contentCtrl.text}\n\n$text';
        }
      }
    }
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o conteúdo da anotação/citação.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(
      type: widget.type,
      content: content,
      chapter: _chapterCtrl.text.trim().isEmpty ? null : _chapterCtrl.text.trim(),
      page: int.tryParse(_pageCtrl.text.trim()),
      noteId: widget.existingNote?.id,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existingNote != null
        ? 'Editar ${widget.type.label}'
        : 'Nova ${widget.type.label}';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão OCR para capturar texto de página física
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.beige.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _isOcrLoading
                          ? null
                          : () => _handleOcr(ImageSource.camera),
                      icon: _isOcrLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt, size: 16),
                      label: const Text('OCR CÂMERA', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _isOcrLoading
                          ? null
                          : () => _handleOcr(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('GALERIA', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (widget.type != NoteType.review) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chapterCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Capítulo (opcional)',
                        hintText: 'Ex: Cap. 3',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Página (opcional)',
                        hintText: 'Ex: 42',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: widget.type == NoteType.quote
                    ? 'Trecho / Citação *'
                    : widget.type == NoteType.review
                        ? 'Texto da Resenha *'
                        : 'Anotação *',
                hintText: 'Escreva ou capture texto da página física...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightCream),
                )
              : const Text('SALVAR'),
        ),
      ],
    );
  }
}
