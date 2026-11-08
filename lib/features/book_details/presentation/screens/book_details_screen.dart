import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 05: Detalhes do Livro
/// Ficha catalográfica completa, controle de empréstimo, sinopse,
/// progresso de leitura e bloco de anotações/citações do leitor.
class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isSynopsisExpanded = false;
  int _activeTabIndex = 0; // 0: Anotações, 1: Citações

  // Controle de Empréstimo
  bool _isLoaned = false;
  String _loanedTo = 'Mariana Silva';

  final List<Map<String, String>> _notes = [
    {
      'header': 'Capítulo 7 • Pág. 84',
      'date': '12 Out',
      'text':
          '“O silêncio de três partes na estalagem... O contraste entre o terceiro silêncio de Kvothe e a atmosfera geral estabelece com precisão o peso de seu passado.”',
    },
    {
      'header': 'Capítulo 12 • Pág. 142',
      'date': '18 Out',
      'text':
          '“A descrição do arquivo da Universidade evoca a sensação pura de um santuário de manuscritos antigos.”',
    },
  ];

  final List<Map<String, String>> _quotes = [
    {
      'header': 'Prólogo • Pág. 11',
      'tag': 'Citação Destacada',
      'text': '“Era o silêncio de um homem que está esperando para morrer.”',
    },
  ];

  void _showLoanDialog() {
    final controller = TextEditingController(text: _isLoaned ? _loanedTo : '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            _isLoaned ? 'Devolução de Livro' : 'Registrar Empréstimo',
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          content: _isLoaned
              ? Text('Confirmar a devolução deste livro por $_loanedTo à sua estante?')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Para quem você está emprestando este exemplar?'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Nome do amigo ou leitor',
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
              onPressed: () {
                setState(() {
                  if (_isLoaned) {
                    _isLoaned = false;
                    _loanedTo = '';
                  } else {
                    _isLoaned = true;
                    _loanedTo = controller.text.trim().isEmpty ? 'Amigo' : controller.text.trim();
                  }
                });
                Navigator.of(ctx).pop();
              },
              child: Text(_isLoaned ? 'CONFIRMAR DEVOLUÇÃO' : 'REGISTRAR'),
            ),
          ],
        );
      },
    );
  }

  void _addNewNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nova Anotação', style: Theme.of(ctx).textTheme.titleLarge),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Digite sua reflexão sobre o trecho lido...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _notes.insert(0, {
                      'header': 'Nova Anotação • Hoje',
                      'date': 'Agora',
                      'text': controller.text.trim(),
                    });
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes Do Livro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Capa com fita marcadora
            Center(
              child: Container(
                width: 140,
                height: 210,
                decoration: BoxDecoration(
                  color: AppColors.mediumBrown,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.mediumBrown : AppColors.beige,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(3, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_stories, size: 40, color: AppColors.lightCream),
                            const SizedBox(height: 10),
                            Text(
                              'O Nome do Vento',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.lightCream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Fita marcadora
                    Positioned(
                      top: 0,
                      right: 16,
                      child: Container(
                        width: 12,
                        height: 28,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Título, Autor e Edição
            Text(
              'O Nome do Vento',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Patrick Rothfuss',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Editora Arqueiro • 656 páginas • 1ª Edição'.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Controle de Empréstimo (Card Interativo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.mediumBrown : AppColors.beige,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isLoaned ? Icons.assignment_ind_outlined : Icons.check_circle_outline,
                        size: 20,
                        color: _isLoaned ? AppColors.mediumBrown : (isDark ? AppColors.lightCream : AppColors.darkBrown),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoaned ? 'EMPRESTADO' : 'DISPONÍVEL NA ESTANTE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (_isLoaned)
                            Text(
                              'Emprestado para $_loanedTo',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: _showLoanDialog,
                    child: Text(_isLoaned ? 'DEVOLVER' : 'EMPRESTAR'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Divisor
            const Divider(),

            const SizedBox(height: 16),

            // Sinopse
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SINOPSE',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSynopsisExpanded
                  ? 'Conheça a história de Kvothe: um herói lendário, músico prodígio e fugitivo procurado, narrando sua própria saga de mistério e magia. Ao longo de três dias na pacata estalagem Marco do Percurso, ele decide finalmente revelar a verdade nua e crua por trás de seus mitos, desde a infância com a trupe de artistas itinerantes Edema Ruh até o ingresso na temida Universidade.'
                  : 'Conheça a história de Kvothe: um herói lendário, músico prodígio e fugitivo procurado, narrando sua própria saga de mistério e magia...',
              textAlign: TextAlign.justify,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _isSynopsisExpanded ? 'Recolher —>' : 'Ler mais —>',
                  style: theme.textTheme.labelMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Ação Principal: Continuar Leitura
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tracker),
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('CONTINUAR LEITURA'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESSO ATUAL',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  'Pág. 248 de 656 (37%)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 0.37,
                minHeight: 3,
                backgroundColor: isDark ? AppColors.woodBrown : AppColors.beige,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.lightCream : AppColors.darkBrown,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Abas de Anotações & Citações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSubTab('Minhas Anotações (${_notes.length})', 0, isDark),
                    const SizedBox(width: 16),
                    _buildSubTab('Citações (${_quotes.length})', 1, isDark),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addNewNoteDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('NOVA ANOTAÇÃO'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: isDark ? AppColors.lightCream : AppColors.darkBrown,
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lista de Anotações / Citações
            if (_activeTabIndex == 0)
              ..._notes.map((n) => _buildNoteCard(n['header']!, n['date']!, n['text']!, isDark, theme))
            else
              ..._quotes.map((q) => _buildNoteCard(q['header']!, q['tag']!, q['text']!, isDark, theme, isQuote: true)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(String label, int index, bool isDark) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? (isDark ? AppColors.lightCream : AppColors.darkBrown) : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                : (isDark ? AppColors.beige : AppColors.woodBrown),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(
    String header,
    String tag,
    String text,
    bool isDark,
    ThemeData theme, {
    bool isQuote = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.woodBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                header.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
              ),
              Text(
                tag.toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
