import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/session_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/use_cases/get_dashboard_stats_use_case.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/reading_charts_section.dart';

/// Tela 02: Início / Dashboard (ISSUE-C07)
/// Visão geral das leituras do usuário, estatísticas de progresso,
/// gráfico fl_chart e atalho direto para a leitura ativa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) {
        final bookRepo = ctx.read<BookRepository>();
        final sessionRepo = ctx.read<SessionRepository>();
        final loanRepo = ctx.read<LoanRepository>();
        final settingsRepo = ctx.read<SettingsRepository>();

        GetDashboardStatsUseCase useCase;
        try {
          useCase = ctx.read<GetDashboardStatsUseCase>();
        } catch (_) {
          useCase = GetDashboardStatsUseCase(
            bookRepository: bookRepo,
            sessionRepository: sessionRepo,
            loanRepository: loanRepo,
            settingsRepository: settingsRepo,
          );
        }

        return HomeViewModel(
          bookRepository: bookRepo,
          sessionRepository: sessionRepo,
          loanRepository: loanRepo,
          settingsRepository: settingsRepo,
          getDashboardStatsUseCase: useCase,
        );
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = vm.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            tooltip: 'Ajustar Meta Anual',
            icon: const Icon(Icons.flag_outlined, size: 20),
            onPressed: () => _showAnnualGoalDialog(context, vm),
          ),
          IconButton(
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: vm.isLoading || stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saudação Editorial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIBLIOTECA PESSOAL',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Boas Leituras',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.4),
                          border: Border.all(
                            color: isDark ? AppColors.mediumBrown : AppColors.beige,
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.menu_book,
                          size: 20,
                          color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Alerta de Empréstimos Atrasados
                  if (stats.overdueLoans.isNotEmpty && !vm.dismissOverdueAlert) ...[
                    _buildOverdueLoansAlert(context, vm, stats.overdueLoans.length, isDark),
                    const SizedBox(height: 16),
                  ],

                  // Faixa de Estatísticas de Leitura
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? AppColors.mediumBrown : AppColors.beige,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('${stats.totalBooksRead} lidos', theme, isDark),
                        _buildDot(isDark),
                        _buildStatItem('${stats.currentReadingBooks.length} lendo', theme, isDark),
                        _buildDot(isDark),
                        _buildStatItem(
                          'meta: ${(stats.annualGoalProgress * 100).toInt()}%',
                          theme,
                          isDark,
                          highlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card Principal: Leitura Atual
                  if (stats.currentBook != null)
                    _buildCurrentBookCard(context, stats.currentBook!, isDark, theme)
                  else
                    _buildNoCurrentBookCard(context, isDark, theme),

                  const SizedBox(height: 24),

                  // Seção do Gráfico de Leituras (fl_chart)
                  ReadingChartsSection(
                    stats: stats.monthlyStats,
                    selectedMetric: vm.selectedMetric,
                    onMetricChanged: vm.setChartMetric,
                  ),

                  const SizedBox(height: 24),

                  // Outros Livros em Andamento
                  if (stats.currentReadingBooks.length > 1) ...[
                    Text(
                      'OUTRAS LEITURAS EM ANDAMENTO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOtherReadingBooksList(context, stats.currentReadingBooks.skip(1).toList(), isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildOverdueLoansAlert(BuildContext context, HomeViewModel vm, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.woodBrown.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.woodBrown,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.woodBrown),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? 'Você tem 1 empréstimo em atraso!'
                  : 'Você tem $count empréstimos em atraso!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: vm.dismissAlert,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBookCard(
    BuildContext context,
    BookModel book,
    bool isDark,
    ThemeData theme,
  ) {
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.mediumBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capa com cantoneira editorial Stitch
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.bookDetails,
                  arguments: book.id,
                ),
                child: Container(
                  width: 88,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.mediumBrown,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.beige, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            book.coverUrl!,
                            width: 88,
                            height: 132,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(book, theme),
                          ),
                        )
                      else
                        _buildCoverPlaceholder(book, theme),
                      // Fita marcadora Stitch
                      Positioned(
                        top: 0,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 18,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Informações do Livro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEITURA ATUAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pág. ${book.currentPage} de ${book.totalPages}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '$percent%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: isDark ? AppColors.darkBrown : AppColors.beige,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.lightCream : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botão Continuar Leitura
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.tracker,
              arguments: book.id,
            ),
            label: const Text('CONTINUAR LEITURA'),
            icon: const Icon(Icons.arrow_forward, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCurrentBookCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.mediumBrown : AppColors.beige,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: isDark ? AppColors.beige : AppColors.mediumBrown,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma leitura em andamento',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Marque um livro como "Lendo" para acompanhar seu progresso e métricas diárias.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addBook),
            child: const Text('ADICIONAR LIVRO'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder(BookModel book, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, color: AppColors.lightCream, size: 28),
            const SizedBox(height: 6),
            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.lightCream,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherReadingBooksList(BuildContext context, List<BookModel> books, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final b = books[idx];
          return InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.bookDetails,
              arguments: b.id,
            ),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.woodBrown.withOpacity(0.5) : AppColors.beige.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.mediumBrown : AppColors.beige,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.currentPage}/${b.totalPages} pág.',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String text, ThemeData theme, bool isDark, {bool highlight = false}) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: highlight
            ? (isDark ? AppColors.lightCream : AppColors.woodBrown)
            : (isDark ? AppColors.beige : AppColors.darkBrown),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDot(bool isDark) {
    return Text(
      '•',
      style: TextStyle(
        color: isDark ? AppColors.woodBrown : AppColors.beige,
        fontSize: 14,
      ),
    );
  }

  void _showAnnualGoalDialog(BuildContext context, HomeViewModel vm) {
    final currentGoal = vm.stats?.annualGoal ?? 12;
    int goal = currentGoal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: const Text('Meta Anual de Leitura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quantos livros você deseja ler neste ano?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    onPressed: goal > 1 ? () => setState(() => goal--) : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$goal',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  IconButton.outlined(
                    onPressed: () => setState(() => goal++),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
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
                await vm.updateAnnualGoal(goal);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }
}
