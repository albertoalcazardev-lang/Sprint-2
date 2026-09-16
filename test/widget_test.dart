import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/di/dependency_injection.dart';
import 'package:tienda_flutter/main.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    configurarDependencias();
  });

  testWidgets('La aplicación inicia mostrando el login sin sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TiendaApp());

    await tester.pumpAndSettle();

    expect(find.text('Todo empieza por aquí.'), findsOneWidget);

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
