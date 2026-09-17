import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/widgets/aviso_producto_actualizado.dart';

void main() {
  testWidgets('P21 muestra el aviso de actualización simulada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AvisoProductoActualizado())),
    );

    expect(find.text('Producto actualizado (Simulación)'), findsOneWidget);

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('el aviso permite recibir un mensaje personalizado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvisoProductoActualizado(mensaje: 'Actualización confirmada'),
        ),
      ),
    );

    expect(find.text('Actualización confirmada'), findsOneWidget);

    expect(find.text('Producto actualizado (Simulación)'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
