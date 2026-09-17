import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/carrito_repository.dart';
import 'package:tienda_flutter/viewmodels/agregar_carrito_viewmodel.dart';
import 'package:tienda_flutter/widgets/controles_agregar_carrito.dart';
import 'package:tienda_flutter/widgets/selector_cantidad.dart';

void main() {
  late FakeCarritoRepository carritoRepository;
  late FakeAuthRepository authRepository;
  late AgregarCarritoViewModel viewModel;

  const producto = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila con compartimento para portátil.',
  );

  const sesionCliente = SesionUsuario(
    token: 'token-cliente',
    idUsuario: 4,
    rol: RolUsuario.cliente,
  );

  setUp(() {
    carritoRepository = FakeCarritoRepository();

    authRepository = FakeAuthRepository(sesion: sesionCliente);

    viewModel = AgregarCarritoViewModel(
      carritoRepository,
      authRepository,
      obtenerFechaActual: () => DateTime(2026, 9, 17),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await carritoRepository.dispose();
  });

  Future<void> mostrarControles(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ControlesAgregarCarrito(viewModel: viewModel),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets('Cliente ve selector y botón para agregar', (tester) async {
    await viewModel.inicializar(producto);
    await mostrarControles(tester);

    expect(find.byType(SelectorCantidad), findsOneWidget);
    expect(find.text('Cantidad'), findsOneWidget);
    expect(find.text('Agregar al carrito'), findsOneWidget);
    expect(find.text('Solo lectura · Perfil Auditor'), findsNothing);
  });

  testWidgets('Auditor conserva un detalle de solo lectura', (tester) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 7,
      rol: RolUsuario.auditor,
    );

    await viewModel.inicializar(producto);
    await mostrarControles(tester);

    expect(find.text('Solo lectura · Perfil Auditor'), findsOneWidget);
    expect(find.byType(SelectorCantidad), findsNothing);
    expect(find.text('Agregar al carrito'), findsNothing);
    expect(carritoRepository.llamadasAgregar, 0);
  });

  testWidgets('Administrador no ve controles de carrito', (tester) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-administrador',
      idUsuario: 1,
      rol: RolUsuario.administrador,
    );

    await viewModel.inicializar(producto);
    await mostrarControles(tester);

    expect(find.byType(SelectorCantidad), findsNothing);
    expect(find.text('Agregar al carrito'), findsNothing);
    expect(find.text('Solo lectura · Perfil Auditor'), findsNothing);
    expect(carritoRepository.llamadasAgregar, 0);
  });

  testWidgets('el éxito muestra P10 y actualiza las unidades', (tester) async {
    await viewModel.inicializar(producto);
    viewModel.incrementarCantidad();

    await mostrarControles(tester);

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar al carrito'));
    await tester.pumpAndSettle();

    expect(carritoRepository.llamadasAgregar, 1);
    expect(find.text('Producto añadido a tu carrito.'), findsOneWidget);
    expect(find.text('2 unidades en tu carrito'), findsOneWidget);

    // El selector vuelve a uno, pero el carrito conserva dos.
    expect(viewModel.cantidad, 1);
    expect(viewModel.totalUnidades, 2);
  });

  testWidgets('durante el POST deshabilita controles y doble envío', (
    tester,
  ) async {
    final respuestaPendiente = Completer<CarritoSnapshot>();
    final solicitudRecibida = Completer<void>();

    carritoRepository.alAgregar = (input) {
      if (!solicitudRecibida.isCompleted) {
        solicitudRecibida.complete();
      }

      return respuestaPendiente.future;
    };

    await viewModel.inicializar(producto);
    await mostrarControles(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar al carrito'));

    await tester.pump();
    await solicitudRecibida.future;
    await tester.pump();

    expect(find.text('Agregando...'), findsOneWidget);
    expect(viewModel.agregando, isTrue);
    expect(carritoRepository.llamadasAgregar, 1);

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(boton.onPressed, isNull);

    final botonesCantidad = tester.widgetList<IconButton>(
      find.byType(IconButton),
    );

    for (final botonCantidad in botonesCantidad) {
      expect(botonCantidad.onPressed, isNull);
    }

    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    expect(carritoRepository.llamadasAgregar, 1);

    respuestaPendiente.complete(
      CarritoSnapshot(
        idUsuario: 4,
        items: const [ItemCarrito(producto: producto, cantidad: 1)],
      ),
    );

    await tester.pumpAndSettle();

    expect(viewModel.agregando, isFalse);
    expect(carritoRepository.llamadasAgregar, 1);
    expect(find.text('Producto añadido a tu carrito.'), findsOneWidget);
  });

  testWidgets('un error conserva cantidad y permite reintentar', (
    tester,
  ) async {
    carritoRepository.errorAlAgregar = const SinConexionCarritoException();

    await viewModel.inicializar(producto);
    viewModel.incrementarCantidad();

    await mostrarControles(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar al carrito'));
    await tester.pumpAndSettle();

    expect(carritoRepository.llamadasAgregar, 1);
    expect(viewModel.cantidad, 2);

    expect(
      find.text('Sin conexión. Revisa tu acceso a internet.'),
      findsOneWidget,
    );

    expect(find.text('Producto añadido a tu carrito.'), findsNothing);

    final boton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Agregar al carrito'),
    );

    expect(boton.onPressed, isNotNull);

    carritoRepository.errorAlAgregar = null;

    await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar al carrito'));
    await tester.pumpAndSettle();

    expect(carritoRepository.llamadasAgregar, 2);
    expect(find.text('Producto añadido a tu carrito.'), findsOneWidget);
  });
}

class FakeCarritoRepository implements CarritoRepository {
  final StreamController<CarritoSnapshot> _controller =
      StreamController<CarritoSnapshot>.broadcast(sync: true);

  int llamadasAgregar = 0;
  AgregarCarritoInput? ultimoInput;
  CarritoException? errorAlAgregar;

  Future<CarritoSnapshot> Function(AgregarCarritoInput input)? alAgregar;

  @override
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input) async {
    llamadasAgregar++;
    ultimoInput = input;

    final callback = alAgregar;

    if (callback != null) {
      return callback(input);
    }

    final error = errorAlAgregar;

    if (error != null) {
      throw error;
    }

    final carrito = CarritoSnapshot(
      idUsuario: input.idUsuario,
      items: [ItemCarrito(producto: input.producto, cantidad: input.cantidad)],
    );

    _controller.add(carrito);

    return carrito;
  }

  @override
  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario) async {
    return CarritoSnapshot.vacio(idUsuario);
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) async {}

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    return _controller.stream.where(
      (carrito) => carrito.idUsuario == idUsuario,
    );
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class FakeAuthRepository implements AuthRepository {
  SesionUsuario? sesion;

  FakeAuthRepository({required this.sesion});

  @override
  Future<SesionUsuario?> obtenerSesion() async {
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    sesion = null;
  }

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) {
    throw UnimplementedError('Estas pruebas no inician sesión.');
  }
}
