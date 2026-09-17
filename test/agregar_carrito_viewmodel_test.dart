import 'dart:async';

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
import 'package:tienda_flutter/viewmodels/agregar_carrito_estado.dart';
import 'package:tienda_flutter/viewmodels/agregar_carrito_viewmodel.dart';

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

  test('Cliente inicia listo con cantidad uno', () async {
    await viewModel.inicializar(producto);

    expect(viewModel.estado, AgregarCarritoEstado.listo);
    expect(viewModel.cantidad, 1);
    expect(viewModel.puedeMostrarControles, isTrue);
    expect(viewModel.puedeDisminuir, isFalse);
    expect(viewModel.puedeAgregar, isTrue);
    expect(viewModel.totalUnidades, 0);
  });

  test('incrementar y disminuir no llaman al Repository', () async {
    await viewModel.inicializar(producto);

    viewModel.incrementarCantidad();
    viewModel.incrementarCantidad();

    expect(viewModel.cantidad, 3);
    expect(carritoRepository.llamadasAgregar, 0);

    viewModel.disminuirCantidad();

    expect(viewModel.cantidad, 2);
    expect(carritoRepository.llamadasAgregar, 0);
  });

  test('la cantidad nunca disminuye de uno', () async {
    await viewModel.inicializar(producto);

    viewModel.disminuirCantidad();
    viewModel.disminuirCantidad();

    expect(viewModel.cantidad, 1);
    expect(viewModel.puedeDisminuir, isFalse);
    expect(carritoRepository.llamadasAgregar, 0);
  });

  test('Cliente agrega usando sesión, cantidad y fecha reales', () async {
    await viewModel.inicializar(producto);

    viewModel.incrementarCantidad();
    viewModel.incrementarCantidad();

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isTrue);
    expect(carritoRepository.llamadasAgregar, 1);

    final input = carritoRepository.ultimoInput;

    expect(input, isNotNull);
    expect(input!.idUsuario, 4);
    expect(input.producto, same(producto));
    expect(input.cantidad, 3);
    expect(input.fecha, DateTime(2026, 9, 17));

    expect(viewModel.estado, AgregarCarritoEstado.exito);
    expect(viewModel.mensajeExito, 'Producto añadido a tu carrito.');
    expect(viewModel.mensajeError, isNull);
    expect(viewModel.totalUnidades, 3);

    // El carrito conserva tres; solamente el selector vuelve a uno.
    expect(viewModel.cantidad, 1);
    expect(viewModel.carrito!.buscarProducto(producto.id)!.cantidad, 3);
  });

  test('un error conserva la cantidad seleccionada', () async {
    await viewModel.inicializar(producto);

    viewModel.incrementarCantidad();
    viewModel.incrementarCantidad();

    carritoRepository.errorAlAgregar = const SinConexionCarritoException();

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isFalse);
    expect(carritoRepository.llamadasAgregar, 1);
    expect(viewModel.cantidad, 3);
    expect(viewModel.totalUnidades, 0);
    expect(viewModel.estado, AgregarCarritoEstado.errorRecuperable);
    expect(
      viewModel.mensajeError,
      'Sin conexión. Revisa tu acceso a internet.',
    );
    expect(viewModel.mensajeExito, isNull);
    expect(viewModel.agregando, isFalse);
  });

  test('un doble toque genera una sola operación', () async {
    await viewModel.inicializar(producto);

    final respuestaPendiente = Completer<CarritoSnapshot>();
    final solicitudRecibida = Completer<void>();

    carritoRepository.alAgregar = (input) {
      if (!solicitudRecibida.isCompleted) {
        solicitudRecibida.complete();
      }

      return respuestaPendiente.future;
    };

    final primeraOperacion = viewModel.agregarAlCarrito();

    await solicitudRecibida.future;

    expect(viewModel.agregando, isTrue);
    expect(viewModel.estado, AgregarCarritoEstado.agregando);

    final segundaOperacion = await viewModel.agregarAlCarrito();

    expect(segundaOperacion, isFalse);
    expect(carritoRepository.llamadasAgregar, 1);

    respuestaPendiente.complete(
      CarritoSnapshot(
        idUsuario: 4,
        items: const [ItemCarrito(producto: producto, cantidad: 1)],
      ),
    );

    expect(await primeraOperacion, isTrue);
    expect(viewModel.agregando, isFalse);
    expect(carritoRepository.llamadasAgregar, 1);
  });

  test('Auditor no puede agregar al carrito', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 7,
      rol: RolUsuario.auditor,
    );

    await viewModel.inicializar(producto);

    expect(viewModel.puedeMostrarControles, isFalse);
    expect(viewModel.mensajeSoloLectura, 'Solo lectura · Perfil Auditor');

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isFalse);
    expect(carritoRepository.llamadasAgregar, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('Administrador no puede agregar al carrito', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-administrador',
      idUsuario: 1,
      rol: RolUsuario.administrador,
    );

    await viewModel.inicializar(producto);

    expect(viewModel.puedeMostrarControles, isFalse);
    expect(viewModel.mensajeSoloLectura, isNull);

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isFalse);
    expect(carritoRepository.llamadasAgregar, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('una sesión inexistente no puede agregar', () async {
    authRepository.sesion = null;

    await viewModel.inicializar(producto);

    expect(viewModel.puedeMostrarControles, isFalse);
    expect(viewModel.accesoNoAutorizado, isTrue);

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isFalse);
    expect(carritoRepository.llamadasAgregar, 0);
  });

  test('un producto inválido no llama al Repository', () async {
    const productoInvalido = Producto(
      id: 0,
      titulo: 'Producto inválido',
      precio: 10,
      categoria: 'electronics',
      imageUrl: 'https://ejemplo.com/producto.jpg',
      descripcion: 'Descripción del producto.',
    );

    await viewModel.inicializar(productoInvalido);

    final agregado = await viewModel.agregarAlCarrito();

    expect(agregado, isFalse);
    expect(carritoRepository.llamadasAgregar, 0);
    expect(viewModel.estado, AgregarCarritoEstado.errorRecuperable);
    expect(viewModel.mensajeError, 'No se encontró el producto.');
  });

  test('un cambio global actualiza el total de unidades', () async {
    await viewModel.inicializar(producto);

    carritoRepository.emitir(
      CarritoSnapshot(
        idUsuario: 4,
        items: const [ItemCarrito(producto: producto, cantidad: 5)],
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.totalUnidades, 5);
  });
}

class FakeCarritoRepository implements CarritoRepository {
  final StreamController<CarritoSnapshot> _controller =
      StreamController<CarritoSnapshot>.broadcast(sync: true);

  int llamadasAgregar = 0;
  int llamadasObtener = 0;
  int llamadasLimpiar = 0;

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
    llamadasObtener++;

    return CarritoSnapshot.vacio(idUsuario);
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) async {
    llamadasLimpiar++;
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    return _controller.stream.where(
      (carrito) => carrito.idUsuario == idUsuario,
    );
  }

  void emitir(CarritoSnapshot carrito) {
    _controller.add(carrito);
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
