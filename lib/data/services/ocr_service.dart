import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Serviço stateless de OCR local para extrair trechos de páginas físicas de livros.
/// Slide 25 da Aula 24 (Arquitetura Flutter).
class OcrService {
  final ImagePicker _picker;

  OcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Captura imagem da câmera ou galeria e extrai o texto reconhecido.
  /// Remove o arquivo temporário gerado e descarta o reconhecedor após o uso.
  Future<String?> extractTextFromImage({
    required ImageSource source,
  }) async {
    if (kIsWeb) {
      throw Exception(
        'O reconhecimento de texto (OCR) por câmera é suportado apenas no aplicativo Android.',
      );
    }

    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (xFile == null) {
        return null;
      }

      final inputImage = InputImage.fromFilePath(xFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        final rawText = recognizedText.text;

        final cleaned = _normalizeExtractedText(rawText);
        return cleaned.isEmpty ? null : cleaned;
      } finally {
        await textRecognizer.close();
        if (!kIsWeb) {
          final file = File(xFile.path);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      throw Exception('Erro ao processar imagem para reconhecimento de texto: $e');
    }
  }

  String _normalizeExtractedText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
