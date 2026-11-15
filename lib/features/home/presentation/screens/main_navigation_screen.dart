import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../screens/home_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';

/// Container de navegação principal com BottomNavigationBar nas 2 abas essenciais:
/// 1. Início (Dashboard de Leitura, Metas & Leitura Atual)
/// 2. Minha Biblioteca (Estante Pessoal, Filtros Avançados & Gestão de Estantes)
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
          LibraryScreen(),
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
            ],
          ),
        );
      },
    );
  }
}
