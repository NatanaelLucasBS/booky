// Status de leitura do livro
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

// Formato do livro (físico ou digital)
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

// Tipos de registro no diário do livro
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

// Escopo de exportação dos livros
enum ExportScope {
  fullCatalog,
  wishlist;

  String get label => switch (this) {
        ExportScope.fullCatalog => 'Catálogo Completo',
        ExportScope.wishlist => 'Lista de Desejos (Quero Ler)',
      };
}

// Formato de arquivo para exportação
enum ExportFormat {
  pdf,
  csv;

  String get label => switch (this) {
        ExportFormat.pdf => 'Documento PDF (.pdf)',
        ExportFormat.csv => 'Planilha CSV (.csv)',
      };
}
