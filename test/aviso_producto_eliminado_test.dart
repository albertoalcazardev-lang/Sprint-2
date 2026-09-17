import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/resultado_eliminacion_producto.dart';
import 'package:tienda_flutter/widgets/aviso_producto_eliminado.dart';

void main() {
  test(
    'ResultadoEliminacionProducto conserva el ID y mensaje de simulación',
    () {
      const resultado = ResultadoEliminacionProducto(productoId: 7);

      expect(resultado.productoId, 7);
      expect(
        resultado.mensaje,
        'Producto eliminado (Simulación). '
        'Al recargar puede reaparecer.',
      );
    },
  );

  test('ResultadoEliminacionProducto permite un mensaje personalizado', () {
    const resultado = ResultadoEliminacionProducto(
      productoId: 12,
      mensaje: 'Producto eliminado temporalmente.',
    );

    expect(resultado.productoId, 12);
    expect(resultado.mensaje, 'Producto eliminado temporalmente.');
  });

  testWidgets('P23 muestra el mensaje exacto de eliminación simulada', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: AvisoProductoEliminado(),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Producto eliminado (Simulación). '
        'Al recargar puede reaparecer.',
      ),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

 testWidgets(
  'el aviso configura correctamente su información accesible',
  (tester) async {
    const mensaje =
        'Producto eliminado (Simulación). '
        'Al recargar puede reaparecer.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvisoProductoEliminado(),
        ),
      ),
    );

    final semanticsFinder = find.descendant(
      of: find.byType(AvisoProductoEliminado),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == mensaje,
      ),
    );

    expect(semanticsFinder, findsOneWidget);

    final semanticsWidget = tester.widget<Semantics>(
      semanticsFinder,
    );

    expect(semanticsWidget.container, isTrue);
    expect(semanticsWidget.properties.liveRegion, isTrue);
    expect(semanticsWidget.properties.label, mensaje);
  },
);

  testWidgets('el aviso se adapta a pantalla compacta y texto escalado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);

          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          );
        },
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: AvisoProductoEliminado(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.text(
        'Producto eliminado (Simulación). '
        'Al recargar puede reaparecer.',
      ),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('el aviso puede mostrar un mensaje personalizado', (
    tester,
  ) async {
    const mensaje = 'Producto retirado del catálogo local.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AvisoProductoEliminado(mensaje: mensaje)),
      ),
    );

    expect(find.text(mensaje), findsOneWidget);

    expect(
      find.text(ResultadoEliminacionProducto.mensajeSimulacion),
      findsNothing,
    );
  });
}
