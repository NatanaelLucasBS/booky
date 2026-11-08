import 'package:flutter/material.dart';

/// Tokens de cores estritos do Design System BOOKY.
/// Paleta editorial refinada inspirada em bibliotecas clássicas de carvalho.
abstract final class AppColors {
  // --- Paleta Estrita Oficial (5 Tons) ---

  /// Tom 1: #2E2A24 (Dark Brown)
  /// Usado para textos de alto contraste no tema claro, botões primários e fundo no tema escuro.
  static const Color darkBrown = Color(0xFF2E2A24);

  /// Tom 2: #5A4633 (Wood Brown)
  /// Usado para tipografia secundária, acentos amadeirados e superfícies no tema escuro.
  static const Color woodBrown = Color(0xFF5A4633);

  /// Tom 3: #8A6B4A (Medium Brown)
  /// Usado para divisores, ícones secundários, marcadores e detalhes sutis.
  static const Color mediumBrown = Color(0xFF8A6B4A);

  /// Tom 4: #C7AD84 (Beige)
  /// Usado para bordas sutis, divisores, chips desmarcados e texto atenuado no escuro.
  static const Color beige = Color(0xFFC7AD84);

  /// Tom 5: #F2E7D4 (Light Cream)
  /// Usado para o fundo pergaminho no tema claro e texto de destaque no tema escuro.
  static const Color lightCream = Color(0xFFF2E7D4);

  // Mapeamentos Semânticos de Conveniência
  static const Color primary = darkBrown;
  static const Color secondary = woodBrown;
  static const Color tertiary = mediumBrown;
  static const Color border = beige;
  static const Color backgroundLight = lightCream;
  static const Color backgroundDark = darkBrown;
}
