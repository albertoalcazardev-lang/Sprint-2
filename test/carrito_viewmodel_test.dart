import 'dart:async';

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
import 'package:tienda_flutter/viewmodels/carrito_estado.dart';
import 'package:tienda_flutter/viewmodels/carrito_viewmodel.dart';

void main() {
  const producto = Producto(
    id: 1,
    titulo: 'Mochila',
    precio: 25,
    categoria: 'bags',
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Descripción',
  );

  late FakeCarritoRepository carritoRepository;
  late FakeGestionRepository gestionRepository;
  late FakeAuthRepository authRepository;
  late CarritoViewModel viewModel;

  setUp(() {
    final carrito = CarritoSnapshot(
      idUsuario: 4,
      idCarritoRemoto: 21,
      items: const [ItemCarrito(producto: producto, cantidad: 2)],
    );
    carritoRepository = FakeCarritoRepository(carrito);
    gestionRepository = FakeGestionRepository(carrito);
    authRepository = FakeAuthRepository(
      const SesionUsuario(
        token: 'token',
        idUsuario: 4,
        rol: RolUsuario.cliente,
      ),
    );
    viewModel = CarritoViewModel(
      carritoRepository,
      gestionRepository,
      authRepository,
      obtenerFechaActual: () => DateTime(2026, 9, 17),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await carritoRepository.dispose();
  });

  test(
    'Cliente carga carrito local sin ejecutar operaciones remotas',
    () async {
      await viewModel.inicializar();

      expect(viewModel.estado, CarritoEstado.listo);
      expect(viewModel.totalUnidades, 2);
      expect(viewModel.total, 50);
      expect(gestionRepository.llamadasActualizar, 0);
      expect(gestionRepository.llamadasEliminar, 0);
    },
  );

  test('incrementar modifica una sola vez y recalcula el total', () async {
    await viewModel.inicializar();

    expect(await viewModel.incrementar(1), isTrue);

    expect(gestionRepository.llamadasActualizar, 1);
    expect(gestionRepository.ultimaCantidad, 3);
    expect(viewModel.totalUnidades, 3);
    expect(viewModel.total, 75);
  });

  test('disminuir desde uno elimina la línea', () async {
    final carritoUno = CarritoSnapshot(
      idUsuario: 4,
      idCarritoRemoto: 21,
      items: const [ItemCarrito(producto: producto, cantidad: 1)],
    );
    carritoRepository.carrito = carritoUno;
    gestionRepository.carrito = carritoUno;

    await viewModel.inicializar();
    expect(await viewModel.disminuir(1), isTrue);

    expect(gestionRepository.llamadasActualizar, 0);
    expect(gestionRepository.llamadasEliminar, 1);
    expect(viewModel.estaVacio, isTrue);
    expect(viewModel.estado, CarritoEstado.vacio);
  });

  test('Administrador no carga el carrito ni ejecuta red', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'admin',
      idUsuario: 1,
      rol: RolUsuario.administrador,
    );

    await viewModel.inicializar();

    expect(viewModel.accesoNoAutorizado, isTrue);
    expect(carritoRepository.llamadasObtener, 0);
    expect(gestionRepository.llamadasActualizar, 0);
    expect(gestionRepository.llamadasEliminar, 0);
  });

  test('pago solo presenta el mensaje informativo', () async {
    await viewModel.inicializar();
    viewModel.mostrarAvisoPago();

    expect(
      viewModel.mensajeInformativo,
      'El proceso de pago aún no está definido.',
    );
    expect(gestionRepository.llamadasActualizar, 0);
    expect(gestionRepository.llamadasEliminar, 0);
  });
}

class FakeCarritoRepository implements CarritoRepository {
  final StreamController<CarritoSnapshot> controller =
      StreamController<CarritoSnapshot>.broadcast(sync: true);
  CarritoSnapshot carrito;
  int llamadasObtener = 0;

  FakeCarritoRepository(this.carrito);

  @override
  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario) async {
    llamadasObtener++;
    return carrito;
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) => controller.stream;

  @override
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input) =>
      throw UnimplementedError();

  @override
  Future<void> limpiarCarrito(int idUsuario) async {}

  Future<void> dispose() => controller.close();
}

class FakeGestionRepository implements GestionCarritoRepository {
  CarritoSnapshot carrito;
  int llamadasActualizar = 0;
  int llamadasEliminar = 0;
  int? ultimaCantidad;

  FakeGestionRepository(this.carrito);

  @override
  Future<CarritoSnapshot> actualizarCantidad({
    required int idUsuario,
    required int productoId,
    required int nuevaCantidad,
    required DateTime fecha,
  }) async {
    llamadasActualizar++;
    ultimaCantidad = nuevaCantidad;
    carrito = carrito.copiarConItems(
      carrito.items.map(
        (item) => item.producto.id == productoId
            ? item.copiarConCantidad(nuevaCantidad)
            : item,
      ),
    );
    return carrito;
  }

  @override
  Future<CarritoSnapshot> eliminarProducto({
    required int idUsuario,
    required int productoId,
  }) async {
    llamadasEliminar++;
    carrito = carrito.copiarConItems(
      carrito.items.where((item) => item.producto.id != productoId),
    );
    return carrito;
  }
}

class FakeAuthRepository implements AuthRepository {
  SesionUsuario? sesion;

  FakeAuthRepository(this.sesion);

  @override
  Future<SesionUsuario?> obtenerSesion() async => sesion;

  @override
  Future<void> cerrarSesion() async => sesion = null;

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) =>
      throw UnimplementedError();
}
