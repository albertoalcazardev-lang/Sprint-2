import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/product_exception.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/resultado_eliminacion_producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/viewmodels/eliminar_producto_estado.dart';
import 'package:tienda_flutter/viewmodels/eliminar_producto_viewmodel.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeAuthRepository authRepository;
  late EliminarProductoViewModel viewModel;

  const producto = Producto(
    id: 7,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila urbana con compartimento para portátil.',
  );

  const sesionAdministrador = SesionUsuario(
    token: 'token-administrador',
    idUsuario: 1,
    rol: RolUsuario.administrador,
  );

  setUp(() {
    productRepository = FakeProductRepository(productoRespuesta: producto);

    authRepository = FakeAuthRepository(sesion: sesionAdministrador);

    viewModel = EliminarProductoViewModel(productRepository, authRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('un ID inválido no llama al Repository', () async {
    const productoInvalido = Producto(
      id: 0,
      titulo: 'Producto inválido',
      precio: 10,
      categoria: 'electronics',
      imageUrl: 'https://ejemplo.com/producto.jpg',
      descripcion: 'Descripción válida del producto.',
    );

    final resultado = await viewModel.eliminarProducto(productoInvalido);

    expect(resultado, isFalse);
    expect(productRepository.llamadasEliminarProducto, 0);
    expect(viewModel.estado, EliminarProductoEstado.errorRecuperable);
    expect(
      viewModel.mensajeError,
      'No se encontró el producto que intentas eliminar.',
    );
    expect(viewModel.productoEliminado, isNull);
    expect(viewModel.resultado, isNull);
  });

  test('Administrador elimina una vez y obtiene el resultado', () async {
    final eliminado = await viewModel.eliminarProducto(producto);

    expect(eliminado, isTrue);
    expect(productRepository.llamadasEliminarProducto, 1);
    expect(productRepository.ultimoIdEliminado, producto.id);

    expect(viewModel.estado, EliminarProductoEstado.productoEliminado);
    expect(viewModel.productoEliminado, same(producto));
    expect(viewModel.eliminadoCorrectamente, isTrue);

    expect(viewModel.resultado, isNotNull);
    expect(viewModel.resultado!.productoId, producto.id);
    expect(
      viewModel.resultado!.mensaje,
      ResultadoEliminacionProducto.mensajeSimulacion,
    );
  });

  test('expone eliminando y evita dos peticiones concurrentes', () async {
    final respuestaPendiente = Completer<Producto>();
    final solicitudRecibida = Completer<void>();

    productRepository.alEliminarProducto = (productoId) {
      if (!solicitudRecibida.isCompleted) {
        solicitudRecibida.complete();
      }

      return respuestaPendiente.future;
    };

    final primeraSolicitud = viewModel.eliminarProducto(producto);

    await solicitudRecibida.future;

    expect(viewModel.eliminando, isTrue);
    expect(viewModel.estado, EliminarProductoEstado.eliminando);

    final segundaSolicitud = await viewModel.eliminarProducto(producto);

    expect(segundaSolicitud, isFalse);
    expect(productRepository.llamadasEliminarProducto, 1);

    respuestaPendiente.complete(producto);

    expect(await primeraSolicitud, isTrue);
    expect(viewModel.eliminando, isFalse);
    expect(productRepository.llamadasEliminarProducto, 1);
  });

  test(
    'un error conserva el producto solicitado y permite reintentar',
    () async {
      productRepository.alEliminarProducto = (_) {
        return Future<Producto>.error(
          const ProductoException(
            'No pudimos eliminar el producto. '
            'Inténtalo nuevamente.',
          ),
        );
      };

      final eliminado = await viewModel.eliminarProducto(producto);

      expect(eliminado, isFalse);
      expect(viewModel.productoSolicitado, same(producto));
      expect(viewModel.productoEliminado, isNull);
      expect(viewModel.resultado, isNull);
      expect(viewModel.eliminando, isFalse);
      expect(viewModel.estado, EliminarProductoEstado.errorRecuperable);
      expect(
        viewModel.mensajeError,
        'No pudimos eliminar el producto. '
        'Inténtalo nuevamente.',
      );
    },
  );

  test('rechaza una respuesta perteneciente a otro producto', () async {
    productRepository.productoRespuesta = const Producto(
      id: 99,
      titulo: 'Otro producto',
      precio: 10,
      categoria: 'electronics',
      imageUrl: 'https://ejemplo.com/otro.jpg',
      descripcion: 'Descripción de un producto diferente.',
    );

    final eliminado = await viewModel.eliminarProducto(producto);

    expect(eliminado, isFalse);
    expect(viewModel.productoEliminado, isNull);
    expect(viewModel.resultado, isNull);
    expect(viewModel.estado, EliminarProductoEstado.errorRecuperable);
    expect(viewModel.mensajeError, contains('no corresponde'));
  });

  test('Cliente no puede ejecutar la eliminación', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    final eliminado = await viewModel.eliminarProducto(producto);

    expect(eliminado, isFalse);
    expect(productRepository.llamadasEliminarProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
    expect(viewModel.mensajeError, 'No tienes acceso a esta sección.');
  });

  test('Auditor no puede ejecutar la eliminación', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 3,
      rol: RolUsuario.auditor,
    );

    final eliminado = await viewModel.eliminarProducto(producto);

    expect(eliminado, isFalse);
    expect(productRepository.llamadasEliminarProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('una sesión inexistente no ejecuta la eliminación', () async {
    authRepository.sesion = null;

    final eliminado = await viewModel.eliminarProducto(producto);

    expect(eliminado, isFalse);
    expect(productRepository.llamadasEliminarProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });
}

class FakeProductRepository implements ProductRepository {
  int llamadasEliminarProducto = 0;
  int? ultimoIdEliminado;

  Producto productoRespuesta;

  Future<Producto> Function(int productoId)? alEliminarProducto;

  FakeProductRepository({required this.productoRespuesta});

  @override
  Future<Producto> eliminarProducto(int productoId) {
    llamadasEliminarProducto++;
    ultimoIdEliminado = productoId;

    final callback = alEliminarProducto;

    if (callback != null) {
      return callback(productoId);
    }

    return Future.value(productoRespuesta);
  }

  @override
  Future<Producto> crearProducto(CrearProductoInput input) {
    throw UnimplementedError('Las pruebas de eliminación no crean productos.');
  }

  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) {
    throw UnimplementedError(
      'Las pruebas de eliminación no actualizan productos.',
    );
  }

  @override
  Future<List<String>> obtenerCategorias() {
    throw UnimplementedError(
      'Las pruebas de eliminación no cargan categorías.',
    );
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
    throw UnimplementedError('Las pruebas de eliminación no inician sesión.');
  }
}
