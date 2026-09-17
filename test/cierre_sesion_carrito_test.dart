import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/carrito_repository.dart';
import 'package:tienda_flutter/viewmodels/cuenta_viewmodel.dart';

void main() {
  late List<String> ordenOperaciones;
  late FakeAuthRepository authRepository;
  late FakeCarritoRepository carritoRepository;
  late CuentaViewModel viewModel;

  const sesionCliente = SesionUsuario(
    token: 'token-cliente',
    idUsuario: 4,
    rol: RolUsuario.cliente,
  );

  setUp(() {
    ordenOperaciones = [];

    authRepository = FakeAuthRepository(
      sesion: sesionCliente,
      ordenOperaciones: ordenOperaciones,
    );

    carritoRepository = FakeCarritoRepository(
      ordenOperaciones: ordenOperaciones,
    );

    viewModel = CuentaViewModel(authRepository, carritoRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('limpia el carrito antes de eliminar la sesión', () async {
    await viewModel.cargarSesion();

    ordenOperaciones.clear();

    final cerrado = await viewModel.cerrarSesion();

    expect(cerrado, isTrue);

    expect(ordenOperaciones, ['limpiar-carrito', 'cerrar-sesion']);

    expect(carritoRepository.llamadasLimpiar, 1);
    expect(carritoRepository.ultimoIdLimpiado, 4);
    expect(authRepository.llamadasCerrarSesion, 1);
    expect(authRepository.sesion, isNull);
    expect(viewModel.sesion, isNull);
    expect(viewModel.cargando, isFalse);
  });

  test('limpia únicamente el carrito del usuario activo', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-usuario-7',
      idUsuario: 7,
      rol: RolUsuario.cliente,
    );

    await viewModel.cargarSesion();

    final cerrado = await viewModel.cerrarSesion();

    expect(cerrado, isTrue);
    expect(carritoRepository.llamadasLimpiar, 1);
    expect(carritoRepository.ultimoIdLimpiado, 7);
  });

  test('si falla la limpieza no elimina las credenciales', () async {
    carritoRepository.errorAlLimpiar = const PersistenciaCarritoException(
      'No pudimos limpiar el carrito local.',
    );

    await viewModel.cargarSesion();

    ordenOperaciones.clear();

    final cerrado = await viewModel.cerrarSesion();

    expect(cerrado, isFalse);

    expect(ordenOperaciones, ['limpiar-carrito']);
    expect(carritoRepository.llamadasLimpiar, 1);
    expect(authRepository.llamadasCerrarSesion, 0);

    expect(authRepository.sesion, isNotNull);
    expect(viewModel.sesion, isNotNull);
    expect(viewModel.cargando, isFalse);
  });

  test('sin sesión activa no intenta limpiar un carrito', () async {
    authRepository.sesion = null;

    await viewModel.cargarSesion();

    ordenOperaciones.clear();

    final cerrado = await viewModel.cerrarSesion();

    expect(cerrado, isTrue);
    expect(carritoRepository.llamadasLimpiar, 0);
    expect(authRepository.llamadasCerrarSesion, 1);
    expect(ordenOperaciones, ['cerrar-sesion']);
    expect(viewModel.sesion, isNull);
  });

  test('evita dos cierres concurrentes', () async {
    await viewModel.cargarSesion();

    final cierrePendiente = carritoRepository._prepararCierrePendiente();

    final primerCierre = viewModel.cerrarSesion();

    await carritoRepository.limpiezaRecibida.future;

    final segundoCierre = await viewModel.cerrarSesion();

    expect(segundoCierre, isFalse);
    expect(carritoRepository.llamadasLimpiar, 1);
    expect(authRepository.llamadasCerrarSesion, 0);

    cierrePendiente.complete();

    expect(await primerCierre, isTrue);
    expect(authRepository.llamadasCerrarSesion, 1);
  });
}

class FakeAuthRepository implements AuthRepository {
  final List<String> ordenOperaciones;

  SesionUsuario? sesion;
  int llamadasCerrarSesion = 0;

  FakeAuthRepository({required this.sesion, required this.ordenOperaciones});

  @override
  Future<SesionUsuario?> obtenerSesion() async {
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    llamadasCerrarSesion++;
    ordenOperaciones.add('cerrar-sesion');
    sesion = null;
  }

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) {
    throw UnimplementedError('Estas pruebas no inician sesión.');
  }
}

class FakeCarritoRepository implements CarritoRepository {
  final List<String> ordenOperaciones;

  int llamadasLimpiar = 0;
  int? ultimoIdLimpiado;

  CarritoException? errorAlLimpiar;

  Future<void>? _limpiezaPendiente;
  final limpiezaRecibida = _CompleterReutilizable();

  FakeCarritoRepository({required this.ordenOperaciones});

  _CompleterReutilizable _prepararCierrePendiente() {
    final completer = _CompleterReutilizable();
    _limpiezaPendiente = completer.future;
    return completer;
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) async {
    llamadasLimpiar++;
    ultimoIdLimpiado = idUsuario;
    ordenOperaciones.add('limpiar-carrito');
    limpiezaRecibida.complete();

    final error = errorAlLimpiar;

    if (error != null) {
      throw error;
    }

    final pendiente = _limpiezaPendiente;

    if (pendiente != null) {
      await pendiente;
    }
  }

  @override
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input) {
    throw UnimplementedError('Estas pruebas no agregan productos.');
  }

  @override
  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario) {
    throw UnimplementedError('Estas pruebas no consultan el carrito.');
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    return const Stream<CarritoSnapshot>.empty();
  }
}

class _CompleterReutilizable {
  bool _completado = false;

  late final Future<void> future = _crearFuture();

  void Function()? _completarFuture;

  Future<void> _crearFuture() {
    return Future<void>(() async {
      while (!_completado) {
        await Future<void>.delayed(Duration.zero);
      }
    });
  }

  void complete() {
    _completado = true;
    _completarFuture?.call();
  }
}
