import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Tela 04: Perfil & Configurações
/// Gerenciamento do leitor, alternância entre Modo Claro/Escuro e preferências da biblioteca.
class ProfileScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil & Ajustes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do Leitor
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.mediumBrown : AppColors.beige,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.5),
                      child: Text(
                        'AP',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: isDark ? AppColors.lightCream : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Arthur Pendelton',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'arthur@booky.app',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Seção de Aparência / Tema
            _buildSectionHeader('Aparência', 'Edição Impressa', theme, isDark),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.woodBrown : AppColors.beige.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeButton(
                      context: context,
                      title: 'MODO CLARO',
                      icon: Icons.light_mode_outlined,
                      isActive: !isDark,
                      onTap: () {
                        if (isDark && onToggleTheme != null) onToggleTheme!();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildThemeButton(
                      context: context,
                      title: 'MODO ESCURO',
                      icon: Icons.dark_mode_outlined,
                      isActive: isDark,
                      onTap: () {
                        if (!isDark && onToggleTheme != null) onToggleTheme!();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Seção: Configurações Gerais
            _buildSectionHeader('Configurações Gerais', null, theme, isDark),
            const SizedBox(height: 6),

            _buildSettingsTile(
              title: 'Metas de Leitura',
              subtitle: '25 livros em 2024',
              theme: theme,
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Exportar Dados',
              subtitle: 'PDF e CSV da estante',
              theme: theme,
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Notificações e Lembretes',
              subtitle: 'Hábitos diários de leitura',
              theme: theme,
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingsTile(
              title: 'Conta e Segurança',
              subtitle: 'Gerenciar credenciais',
              theme: theme,
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // Botão Sair da Biblioteca
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('SAIR DA BIBLIOTECA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? rightBadge, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.woodBrown : AppColors.beige,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
            ),
          ),
          if (rightBadge != null)
            Text(
              rightBadge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.beige : AppColors.woodBrown,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = isDark ? AppColors.lightCream : AppColors.darkBrown;
    final activeFg = isDark ? AppColors.darkBrown : AppColors.lightCream;
    final inactiveFg = isDark ? AppColors.beige : AppColors.woodBrown;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? activeFg : inactiveFg),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: isActive ? activeFg : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.woodBrown.withOpacity(0.5) : AppColors.beige.withOpacity(0.6),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? AppColors.beige : AppColors.mediumBrown,
            ),
          ],
        ),
      ),
    );
  }
}
