import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book_model.dart';

export '../../domain/models/enums.dart' show ExportScope, ExportFormat;

// Serviço de exportação de relatórios em PDF e CSV
class ExportService {
  const ExportService();

  /// Gera a string CSV com BOM UTF-8 (\uFEFF) a partir da lista de livros.
  String buildCsvContent(List<BookModel> books) {
    final rows = <List<dynamic>>[
      // Cabeçalho em Português
      [
        'Título',
        'Autor',
        'ISBN',
        'Editora',
        'Ano',
        'Gênero',
        'Páginas Totais',
        'Página Atual',
        'Status',
        'Formato',
        'Avaliação',
        'Tags',
      ],
    ];

    for (final b in books) {
      rows.add([
        b.title,
        b.author,
        b.isbn ?? '',
        b.publisher ?? '',
        b.publishedYear ?? '',
        b.genre ?? '',
        b.totalPages,
        b.currentPage,
        b.status.label,
        b.format.label,
        b.rating != null ? b.rating!.toStringAsFixed(1) : '',
        b.tags.join('; '),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    // BOM UTF-8 para compatibilidade perfeita no Microsoft Excel e Google Planilhas
    return '\uFEFF$csvData';
  }

  /// Exporta a lista de livros para CSV com BOM UTF-8 e compartilha via share_plus.
  Future<String> exportAndShareCsv({
    required List<BookModel> books,
    required String fileNamePrefix,
  }) async {
    final csvWithBom = buildCsvContent(books);
    final fileName =
        '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      final bytes = Uint8List.fromList(utf8.encode(csvWithBom));
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'text/csv')],
        text: 'Exportação da Biblioteca Booky',
      );
      return fileName;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvWithBom, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Exportação da Biblioteca Booky',
    );

    return file.path;
  }

  Future<pw.ThemeData?> _loadUnicodePdfTheme() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (_) {
      return null;
    }
  }

  /// Gera os bytes do relatório PDF com suporte Unicode (PT-BR).
  Future<Uint8List> buildPdfBytes({
    required List<BookModel> books,
    required String title,
  }) async {
    final unicodeTheme = await _loadUnicodePdfTheme();
    final pdf = pw.Document(theme: unicodeTheme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BOOKY - $title',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${books.length} livros',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: [
                'Título',
                'Autor',
                'ISBN',
                'Editora',
                'Formato',
                'Status',
                'Páginas',
                'Nota',
                'Tags',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: books.map((b) {
                return [
                  b.title,
                  b.author,
                  b.isbn ?? '-',
                  b.publisher ?? '-',
                  b.format.label,
                  b.status.label,
                  '${b.currentPage}/${b.totalPages}',
                  b.rating != null ? '${b.rating!.toStringAsFixed(1)}/5' : '-',
                  b.tags.isNotEmpty ? b.tags.join(', ') : '-',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Gerado pelo Booky em ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Exporta a lista de livros para um relatório PDF estilizado e compartilha via share_plus.
  Future<String> exportAndSharePdf({
    required List<BookModel> books,
    required String title,
    required String fileNamePrefix,
  }) async {
    final bytes = await buildPdfBytes(books: books, title: title);
    final fileName =
        '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        text: 'Exportação da Biblioteca Booky em PDF',
      );
      return fileName;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Exportação da Biblioteca Booky em PDF',
    );

    return file.path;
  }
}
