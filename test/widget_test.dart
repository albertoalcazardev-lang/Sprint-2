import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/main.dart';

void main() {
  testWidgets('La solución base inicia correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TiendaApp());

    expect(find.text('Solución base configurada'), findsOneWidget);
  });
}
