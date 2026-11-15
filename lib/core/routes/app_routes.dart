import 'package:flutter/material.dart';
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

  static Map<String, WidgetBuilder> get routes => {
        main: (context) => const MainNavigationScreen(),
        bookDetails: (context) => const BookDetailsScreen(),
        tracker: (context) => const ReadingTrackerScreen(),
        addBook: (context) => const AddBookScreen(),
      };
}
