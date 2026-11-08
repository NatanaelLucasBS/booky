import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../screens/home_screen.dart';
import '../../library/presentation/screens/library_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';

/// Container de navegação principal com BottomNavigationBar nas 3 abas essenciais:
/// 1. Início (Dashboard & Leitura Atual)
/// 2. Minha Biblioteca (Estante & Filtros)
/// 3. Perfil & Ajustes (Preferências & Aparência)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final screens = [
          const HomeScreen(),
          const LibraryScreen(),
          ProfileScreen(
            isDarkMode: themeController.isDarkMode,
            onToggleTheme: () => themeController.toggleTheme(),
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Biblioteca',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}
