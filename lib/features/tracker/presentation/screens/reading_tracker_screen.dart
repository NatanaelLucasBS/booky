import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/session_repository.dart';
import '../../../../domain/use_cases/save_reading_session_use_case.dart';
import '../viewmodels/tracker_viewmodel.dart';

/// Tela 06: Rastreador de Leitura (ISSUE-C06)
/// Cronômetro ativo, rastreamento de páginas, velocidade média,
/// estimativa de conclusão e sincronização com histórico local.
class ReadingTrackerScreen extends StatelessWidget {
  final String? bookId;

  const ReadingTrackerScreen({
    super.key,
    this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    final routeBookId = ModalRoute.of(context)?.settings.arguments as String?;
    final targetBookId = bookId ?? routeBookId;

    return ChangeNotifierProvider<TrackerViewModel>(
      create: (ctx) => TrackerViewModel(
        initialBookId: targetBookId,
        bookRepository: ctx.read<BookRepository>(),
        sessionRepository: ctx.read<SessionRepository>(),
        saveReadingSessionUseCase: ctx.read<SaveReadingSessionUseCase>(),
      ),
      child: const _ReadingTrackerView(),
    );
  }
}

class _ReadingTrackerView extends StatelessWidget {
  const _ReadingTrackerView();

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatRemainingTime(Duration? duration) {
    if (duration == null) return 'Calculando...';
    if (duration.inHours > 0) {
      final h = duration.inHours;
      final m = duration.inMinutes % 60;
      return '$h h $m min';
    }
    return '${duration.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final book = vm.selectedBook;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreador De Leitura'),
        actions: [
          if (vm.availableBooks.length > 1)
            IconButton(
              tooltip: 'Trocar Livro',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showBookSelectorModal(context, vm),
            ),
        ],
      ),
      body: SafeArea(
        child: book == null
            ? _buildEmptyState(context, isDark)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Identificação do Livro
                    Text(
                      'SESSÃO EM ANDAMENTO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.0,
                        color: isDark ? AppColors.beige : AppColors.mediumBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chip de Livro e Troca Rápida
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: vm.availableBooks.length > 1
                          ? () => _showBookSelectorModal(context, vm)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.woodBrown
                              : AppColors.beige.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? AppColors.mediumBrown : AppColors.beige,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              book.format == BookFormat.digital ? Icons.tablet_mac : Icons.menu_book,
                              size: 14,
                              color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              book.format.label,
                              style: theme.textTheme.labelMedium,
                            ),
                            if (vm.availableBooks.length > 1) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Timer Display Gigante
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: vm.isRunning ? AppColors.woodBrown : AppColors.mediumBrown,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TEMPO DECORRIDO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatDuration(vm.currentSeconds),
                        style: TextStyle(
                          fontFamilyFallback: const ['Courier', 'monospace'],
                          fontSize: 54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.isRunning ? 'Foco ininterrupto' : 'Sessão pausada',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Controle Interativo de Páginas
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.woodBrown
                            : AppColors.beige.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? AppColors.mediumBrown : AppColors.beige,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'PROGRESSO DA LEITURA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Botão Decrementar
                              IconButton.outlined(
                                tooltip: 'Diminuir página',
                                onPressed: vm.currentPage > 0 ? vm.decrementPage : null,
                                icon: const Icon(Icons.remove, size: 20),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? AppColors.mediumBrown : AppColors.beige,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () =>
                                      _showProgressInputDialog(context, vm, book.totalPages),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '${vm.currentPage}',
                                                style:
                                                    theme.textTheme.headlineMedium?.copyWith(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (book.totalPages > 0) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  'de ${book.totalPages}',
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'página atual (toque p/ digitar pág. ou %)',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botão Incrementar
                              IconButton.outlined(
                                tooltip: 'Avançar página',
                                onPressed: (book.totalPages <= 0 ||
                                        vm.currentPage < book.totalPages)
                                    ? vm.incrementPage
                                    : null,
                                icon: const Icon(Icons.add, size: 20),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? AppColors.mediumBrown : AppColors.beige,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Slider Sincronizado para Leitura Digital / Ajuste Rápido
                          if (book.totalPages > 0)
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    isDark ? AppColors.lightCream : AppColors.darkBrown,
                                inactiveTrackColor:
                                    isDark ? AppColors.darkBrown : AppColors.beige,
                                thumbColor:
                                    isDark ? AppColors.lightCream : AppColors.woodBrown,
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: vm.currentPage.toDouble().clamp(0.0, book.totalPages.toDouble()),
                                min: 0.0,
                                max: book.totalPages.toDouble(),
                                divisions: book.totalPages > 0 ? book.totalPages : 1,
                                onChanged: (value) => vm.setPage(value.round()),
                              ),
                            ),

                          // Linha de Progresso & Estatísticas Rápidas
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: vm.currentPercent,
                              minHeight: 4,
                              backgroundColor: isDark ? AppColors.darkBrown : AppColors.beige,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.lightCream : AppColors.darkBrown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(vm.currentPercent * 100).toInt()}% concluído • ${vm.pagesReadThisSession} páginas nesta sessão',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ritmo médio: ${vm.pagesPerHour.toStringAsFixed(1)} págs/h • Restam ~ ${_formatRemainingTime(vm.remainingTime)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.beige : AppColors.mediumBrown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Botões de Ação da Sessão
                    ElevatedButton.icon(
                      onPressed: () {
                        if (vm.isRunning) {
                          vm.pauseTimer();
                        } else {
                          vm.startTimer();
                        }
                      },
                      icon: Icon(vm.isRunning ? Icons.pause : Icons.play_arrow, size: 18),
                      label: Text(vm.isRunning ? 'PAUSAR SESSÃO' : 'RETOMAR LEITURA'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: vm.isSaving ? null : () => _confirmFinishSession(context, vm),
                      icon: vm.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: const Text('CONCLUIR SESSÃO DE LEITURA'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Histórico de Sessões Recentes do Livro
                    if (vm.sessions.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SESSÕES ANTERIORES',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSessionsHistory(context, vm, isDark),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: isDark ? AppColors.beige : AppColors.mediumBrown,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum livro para rastrear',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione um livro à sua biblioteca ou marque um como "Lendo" para iniciar uma sessão de foco.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.addBook);
              },
              child: const Text('ADICIONAR LIVRO'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookSelectorModal(BuildContext context, TrackerViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SELECIONAR LIVRO PARA LEITURA',
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vm.availableBooks.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (c, idx) {
                    final item = vm.availableBooks[idx];
                    final isCurrent = item.id == vm.selectedBook?.id;
                    return ListTile(
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent
                              ? (isDark ? AppColors.lightCream : AppColors.darkBrown)
                              : null,
                        ),
                      ),
                      subtitle: Text('${item.author} • ${item.currentPage}/${item.totalPages} pág.'),
                      trailing: isCurrent ? const Icon(Icons.check, size: 20) : null,
                      onTap: () {
                        vm.selectBook(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmFinishSession(BuildContext context, TrackerViewModel vm) {
    final pagesRead = vm.pagesReadThisSession;
    final seconds = vm.currentSeconds;
    final book = vm.selectedBook!;
    final isFinished = vm.currentPage >= book.totalPages && book.totalPages > 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          isFinished ? 'Parabéns! Livro Concluído! 🎉' : 'Concluir Sessão',
          style: Theme.of(ctx).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você leu $pagesRead páginas em ${_formatDuration(seconds)}.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              book.totalPages > 0
                  ? 'Página final registrada: ${vm.currentPage} de ${book.totalPages}.'
                  : 'Página final registrada: ${vm.currentPage}.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            if (isFinished) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.woodBrown.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Este livro será automaticamente movido para a sua estante de "Lidos"!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await vm.finishAndSaveSession();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFinished
                        ? 'Sensacional! Livro finalizado e sessão gravada!'
                        : 'Sessão gravada com sucesso!'),
                    backgroundColor: AppColors.woodBrown,
                  ),
                );
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  void _showProgressInputDialog(
    BuildContext context,
    TrackerViewModel vm,
    int totalPages,
  ) {
    final pageCtrl = TextEditingController(text: vm.currentPage.toString());
    final pctCtrl = TextEditingController(
      text: (vm.currentPercent * 100).round().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Atualizar Progresso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: pageCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: totalPages > 0
                    ? 'Página Atual (0 a $totalPages)'
                    : 'Página Atual',
              ),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && totalPages > 0) {
                  final pct = ((p / totalPages) * 100).clamp(0, 100).round();
                  pctCtrl.text = pct.toString();
                }
              },
            ),
            if (totalPages > 0) ...[
              const SizedBox(height: 12),
              TextField(
                controller: pctCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ou Porcentagem Concluída (0% a 100%)',
                  suffixText: '%',
                ),
                onChanged: (val) {
                  final pct = double.tryParse(val.replaceAll(',', '.'));
                  if (pct != null) {
                    final page = ((pct.clamp(0.0, 100.0) / 100.0) * totalPages).round();
                    pageCtrl.text = page.toString();
                  }
                },
              ),
            ],
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(pageCtrl.text.trim());
              if (page != null) {
                vm.setPage(page);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('APLICAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsHistory(BuildContext context, TrackerViewModel vm, bool isDark) {
    final grouped = vm.dailyGroupedSessions.entries.take(5).toList();
    return Column(
      children: grouped.map((entry) {
        final dateKey = entry.key;
        final daySessions = entry.value;
        final parts = dateKey.split('-');
        final dateStr = parts.length == 3 ? '${parts[2]}/${parts[1]}' : dateKey;
        final totalPagesDay = daySessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
        final totalSecondsDay = daySessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
        final durationMin = (totalSecondsDay / 60).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.woodBrown.withValues(alpha: 0.3) : AppColors.beige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? AppColors.mediumBrown.withValues(alpha: 0.5) : AppColors.beige,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$totalPagesDay páginas (${daySessions.length} ${daySessions.length == 1 ? "sessão" : "sessões"})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$durationMin min',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
