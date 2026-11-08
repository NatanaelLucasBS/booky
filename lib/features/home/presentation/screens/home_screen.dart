import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 02: Início / Dashboard
/// Visão geral das leituras do usuário, estatísticas de progresso e atalho para leitura ativa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saudação e Avatar do Leitor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEITOR CADASTRADO',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Olá, Arthur',
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
                  child: Text(
                    'AR',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
                  _buildStatItem('18 lidos', theme, isDark),
                  _buildDot(isDark),
                  _buildStatItem('3 em andamento', theme, isDark),
                  _buildDot(isDark),
                  _buildStatItem('meta: 72%', theme, isDark, highlight: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Principal: Leitura Atual
            Container(
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
                  // Detalhes da capa e metadados
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Capa do Livro
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.bookDetails),
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
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.auto_stories, color: AppColors.lightCream, size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        'O Nome\ndo Vento',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.lightCream,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                              'O Nome do Vento',
                              style: theme.textTheme.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Patrick Rothfuss',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pág. 342 de 656',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  '52%',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Barra linear de progresso
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.52,
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

                  // Botão de Ação: Continuar Leitura
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tracker),
                    icon: const Text('CONTINUAR LEITURA'),
                    label: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
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
}
