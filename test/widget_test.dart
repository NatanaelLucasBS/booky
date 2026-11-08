import 'package:flutter_test/flutter_test.dart';
import 'package:booky/main.dart';

void main() {
  testWidgets('BookyApp smoke test inicializa com sucesso', (WidgetTester tester) async {
    await tester.pumpWidget(const BookyApp());
    expect(find.text('Início'), findsWidgets);
  });
}
