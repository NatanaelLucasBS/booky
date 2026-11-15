import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book_model.dart';

enum ExportScope {
  fullCatalog,
  wishlist;

  String get label => switch (this) {
        ExportScope.fullCatalog => 'Catálogo Completo',
        ExportScope.wishlist => 'Lista de Desejos (Quero Ler)',
      };
}

enum ExportFormat {
  pdf,
  csv;

  String get label => switch (this) {
        ExportFormat.pdf => 'Documento PDF (.pdf)',
        ExportFormat.csv => 'Planilha CSV (.csv)',
      };
}

/// Serviço stateless responsável pela geração de relatórios PDF, planilhas CSV
/// e acionamento do compartilhamento nativo via share_plus (Slide 25 da Aula 24).
class ExportService {
  const ExportService();

  /// Exporta a lista de livros para CSV com BOM UTF-8 e compartilha via share_plus.
  Future<String> exportAndShareCsv({
    required List<BookModel> books,
    required String fileNamePrefix,
  }) async {
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
    final csvWithBom = '\uFEFF$csvData';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvWithBom, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Exportação da Biblioteca Booky',
    );

    return file.path;
  }

  /// Exporta a lista de livros para um relatório PDF estilizado e compartilha via share_plus.
  Future<String> exportAndSharePdf({
    required List<BookModel> books,
    required String title,
    required String fileNamePrefix,
  }) async {
    final pdf = pw.Document();

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
              headers: ['Título', 'Autor', 'Status', 'Páginas', 'Nota'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: books.map((b) {
                return [
                  b.title,
                  b.author,
                  b.status.label,
                  '${b.currentPage}/${b.totalPages}',
                  b.rating != null ? '${b.rating!.toStringAsFixed(1)} ★' : '-',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Gerado pelo Booky em ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Exportação da Biblioteca Booky em PDF',
    );

    return file.path;
  }
}
