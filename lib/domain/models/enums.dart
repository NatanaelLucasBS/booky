/// Status de leitura oficial do Tema 6 (4 opções mutuamente exclusivas).
enum BookStatus {
  wantToRead,
  reading,
  read,
  abandoned;

  String get label => switch (this) {
        BookStatus.wantToRead => 'Quero Ler',
        BookStatus.reading => 'Lendo',
        BookStatus.read => 'Lido',
        BookStatus.abandoned => 'Abandonado',
      };

  static BookStatus fromString(String? value) {
    return BookStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookStatus.wantToRead,
    );
  }
}

/// Formato do livro (Acervo físico ou digital conforme Tema 6).
enum BookFormat {
  physical,
  digital;

  String get label => switch (this) {
        BookFormat.physical => 'Físico',
        BookFormat.digital => 'Digital',
      };

  static BookFormat fromString(String? value) {
    return BookFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookFormat.physical,
    );
  }
}

/// Tipos de anotação na ficha do livro.
enum NoteType {
  note,
  quote,
  review;

  String get label => switch (this) {
        NoteType.note => 'Anotação',
        NoteType.quote => 'Citação',
        NoteType.review => 'Resenha',
      };

  static NoteType fromString(String? value) {
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.note,
    );
  }
}

/// Escopo de exportação do acervo (Tema 6 - RF7).
enum ExportScope {
  fullCatalog,
  wishlist;

  String get label => switch (this) {
        ExportScope.fullCatalog => 'Catálogo Completo',
        ExportScope.wishlist => 'Lista de Desejos (Quero Ler)',
      };
}

/// Formato de arquivo para exportação (Tema 6 - RF7).
enum ExportFormat {
  pdf,
  csv;

  String get label => switch (this) {
        ExportFormat.pdf => 'Documento PDF (.pdf)',
        ExportFormat.csv => 'Planilha CSV (.csv)',
      };
}
