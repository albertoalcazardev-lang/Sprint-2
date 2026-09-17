import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/carrito_repository.dart';
import 'package:tienda_flutter/repositories/gestion_carrito_repository.dart';
import 'package:tienda_flutter/viewmodels/carrito_viewmodel.dart';
import 'package:tienda_flutter/views/carrito_view.dart';

void main() {
  const producto = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 25,
    categoria: 'bags',
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Descripción',
  );

  testWidgets('P11 muestra artículos, totales y aviso de pago', (tester) async {
    final carrito = CarritoSnapshot(
      idUsuario: 4,
      idCarritoRemoto: 21,
      items: const [ItemCarrito(producto: producto, cantidad: 2)],
    );
    final dependencias = _DependenciasPrueba(carrito);

    await tester.pumpWidget(
      MaterialApp(
        home: CarritoView(
          viewModel: dependencias.viewModel,
          onExplorarCatalogo: () {},
          onIrACuenta: () {},
          onAccesoNoAutorizado: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Mi carrito'), findsOneWidget);
    expect(find.text('Mochila urbana'), findsOneWidget);
    expect(find.text(r'$25.00 USD'), findsOneWidget);
    expect(find.text(r'Subtotal: $50.00 USD'), findsOneWidget);
    expect(find.text(r'$50.00 USD'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('proceder-pago')));
    await tester.tap(find.byKey(const ValueKey('proceder-pago')));
    await tester.pump();

    expect(
      find.text('El proceso de pago aún no está definido.'),
      findsOneWidget,
    );

    dependencias.dispose();
  });

  testWidgets('P12 muestra estado vacío y deshabilita el pago', (tester) async {
    final dependencias = _DependenciasPrueba(CarritoSnapshot.vacio(4));

    await tester.pumpWidget(
      MaterialApp(
        home: CarritoView(
          viewModel: dependencias.viewModel,
          onExplorarCatalogo: () {},
          onIrACuenta: () {},
          onAccesoNoAutorizado: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tu carrito está vacío'), findsOneWidget);
    expect(find.text('Explorar catálogo'), findsOneWidget);

    final boton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('proceder-pago')),
    );
    expect(boton.onPressed, isNull);

    dependencias.dispose();
  });
}

class _DependenciasPrueba {
  final _FakeCarritoRepository carritoRepository;
  late final CarritoViewModel viewModel;

  _DependenciasPrueba(CarritoSnapshot carrito)
    : carritoRepository = _FakeCarritoRepository(carrito) {
    viewModel = CarritoViewModel(
      carritoRepository,
      _FakeGestionRepository(),
      _FakeAuthRepository(),
    );
  }

  void dispose() {
    viewModel.dispose();
    carritoRepository.controller.close();
  }
}

class _FakeCarritoRepository implements CarritoRepository {
  final CarritoSnapshot carrito;
  final StreamController<CarritoSnapshot> controller =
      StreamController<CarritoSnapshot>.broadcast();

  _FakeCarritoRepository(this.carrito);

  @override
  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario) async => carrito;

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) => controller.stream;

  @override
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input) =>
      throw UnimplementedError();

  @override
  Future<void> limpiarCarrito(int idUsuario) async {}
}

class _FakeGestionRepository implements GestionCarritoRepository {
  @override
  Future<CarritoSnapshot> actualizarCantidad({
    required int idUsuario,
    required int productoId,
    required int nuevaCantidad,
    required DateTime fecha,
  }) => throw UnimplementedError();

  @override
  Future<CarritoSnapshot> eliminarProducto({
    required int idUsuario,
    required int productoId,
  }) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<SesionUsuario?> obtenerSesion() async {
    return const SesionUsuario(
      token: 'token',
      idUsuario: 4,
      rol: RolUsuario.cliente,
    );
  }

  @override
  Future<void> cerrarSesion() async {}

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) =>
      throw UnimplementedError();
}
