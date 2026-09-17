import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/widgets/selector_cantidad.dart';

void main() {
  testWidgets('muestra la cantidad inicial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorCantidad(
            cantidad: 1,
            onIncrementar: () {},
            onDisminuir: () {},
          ),
        ),
      ),
    );

    expect(find.text('Cantidad'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('deshabilita disminuir cuando la cantidad es uno', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorCantidad(
            cantidad: 1,
            onIncrementar: () {},
            onDisminuir: () {},
          ),
        ),
      ),
    );

    final disminuir = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_rounded),
    );

    final aumentar = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_rounded),
    );

    expect(disminuir.onPressed, isNull);
    expect(aumentar.onPressed, isNotNull);
  });

  testWidgets('incrementa y disminuye una unidad', (tester) async {
    var cantidad = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SelectorCantidad(
                cantidad: cantidad,
                onIncrementar: () {
                  setState(() {
                    cantidad++;
                  });
                },
                onDisminuir: () {
                  if (cantidad <= 1) {
                    return;
                  }

                  setState(() {
                    cantidad--;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add_rounded));
    await tester.pump();

    expect(cantidad, 2);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove_rounded));
    await tester.pump();

    expect(cantidad, 1);
    expect(find.text('1'), findsOneWidget);

    final disminuir = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_rounded),
    );

    expect(disminuir.onPressed, isNull);
  });

  testWidgets('deshabilita ambos botones durante el envío', (tester) async {
    var llamadasIncrementar = 0;
    var llamadasDisminuir = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorCantidad(
            cantidad: 3,
            habilitado: false,
            onIncrementar: () {
              llamadasIncrementar++;
            },
            onDisminuir: () {
              llamadasDisminuir++;
            },
          ),
        ),
      ),
    );

    final disminuir = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_rounded),
    );

    final aumentar = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_rounded),
    );

    expect(disminuir.onPressed, isNull);
    expect(aumentar.onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.remove_rounded),
      warnIfMissed: false,
    );

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.add_rounded),
      warnIfMissed: false,
    );

    expect(llamadasIncrementar, 0);
    expect(llamadasDisminuir, 0);
  });

  testWidgets('se adapta a pantalla compacta y texto escalado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 500));

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
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectorCantidad(
                cantidad: 12,
                onIncrementar: () {},
                onDisminuir: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Cantidad'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
