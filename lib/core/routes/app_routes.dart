import 'package:flutter/material.dart';
import '../../domain/models/book_model.dart';
import '../../features/home/presentation/screens/main_navigation_screen.dart';
import '../../features/book_details/presentation/screens/book_details_screen.dart';
import '../../features/tracker/presentation/screens/reading_tracker_screen.dart';
import '../../features/library/presentation/screens/add_book_screen.dart';

abstract final class AppRoutes {
  static const String initial = main;

  static const String main = '/main';
  static const String bookDetails = '/book-details';
  static const String tracker = '/tracker';
  static const String addBook = '/add-book';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationScreen(),
        );
      case addBook:
        final bookToEdit = settings.arguments is BookModel
            ? settings.arguments as BookModel
            : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddBookScreen(bookToEdit: bookToEdit),
        );
      case bookDetails:
        final bookId = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BookDetailsScreen(bookId: bookId),
        );
      case tracker:
        final bookId = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReadingTrackerScreen(bookId: bookId),
        );
      default:
        return null;
    }
  }
}
