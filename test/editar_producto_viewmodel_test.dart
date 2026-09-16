import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/product_exception.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/viewmodels/editar_producto_estado.dart';
import 'package:tienda_flutter/viewmodels/editar_producto_viewmodel.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeAuthRepository authRepository;
  late EditarProductoViewModel viewModel;

  const productoOriginal = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila-original.jpg',
    descripcion: 'Mochila urbana con compartimento para portátil.',
  );

  const sesionAdministrador = SesionUsuario(
    token: 'token-administrador',
    idUsuario: 1,
    rol: RolUsuario.administrador,
  );

  setUp(() {
    productRepository = FakeProductRepository();
    authRepository = FakeAuthRepository(sesion: sesionAdministrador);

    viewModel = EditarProductoViewModel(productRepository, authRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('inicializar conserva el producto y carga las categorías', () async {
    await viewModel.inicializar(productoOriginal);

    expect(viewModel.productoOriginal, same(productoOriginal));
    expect(viewModel.categorias, contains(productoOriginal.categoria));
    expect(productRepository.llamadasObtenerCategorias, 1);
    expect(viewModel.estado, EditarProductoEstado.formularioListo);
    expect(viewModel.puedeGuardar, isTrue);
  });

  test('un formulario inválido no llama al repositorio', () async {
    await viewModel.inicializar(productoOriginal);

    final resultado = await viewModel.actualizarProducto(
      titulo: '   ',
      precio: '99.95',
      categoria: "men's clothing",
      descripcion: 'Descripción suficientemente extensa.',
    );

    expect(resultado, isFalse);
    expect(productRepository.llamadasActualizarProducto, 0);
    expect(viewModel.productoActualizado, isNull);
    expect(
      viewModel.mensajeError,
      'Revisa los campos marcados antes de continuar.',
    );
  });

  test('envía ID, precio, categoría e imagen original correctamente', () async {
    await viewModel.inicializar(productoOriginal);

    final resultado = await _actualizarProductoValido(viewModel);

    final input = productRepository.ultimoInputActualizacion;

    expect(resultado, isTrue);
    expect(productRepository.llamadasActualizarProducto, 1);
    expect(input, isNotNull);
    expect(input!.id, productoOriginal.id);
    expect(input.titulo, 'Mochila urbana actualizada');
    expect(input.precio, 99.95);
    expect(input.categoria, "men's clothing");
    expect(input.imageUrl, productoOriginal.imageUrl);
    expect(
      input.descripcion,
      'Mochila actualizada con compartimento para portátil.',
    );
  });

  test(
    'el éxito expone el producto actualizado y conserva la imagen',
    () async {
      await viewModel.inicializar(productoOriginal);

      productRepository.alActualizarProducto = (input) async {
        return Producto(
          id: input.id,
          titulo: input.titulo,
          precio: input.precio,
          categoria: input.categoria,
          imageUrl: 'https://servidor.com/imagen-distinta.jpg',
          descripcion: input.descripcion,
        );
      };

      final resultado = await _actualizarProductoValido(viewModel);
      final actualizado = viewModel.productoActualizado;

      expect(resultado, isTrue);
      expect(actualizado, isNotNull);
      expect(actualizado!.titulo, 'Mochila urbana actualizada');
      expect(actualizado.precio, 99.95);
      expect(actualizado.imageUrl, productoOriginal.imageUrl);
      expect(viewModel.estado, EditarProductoEstado.productoActualizado);
      expect(viewModel.mensajeExito, 'Producto actualizado (Simulación)');
    },
  );

  test('no permite dos actualizaciones concurrentes', () async {
    await viewModel.inicializar(productoOriginal);

    final respuestaPendiente = Completer<Producto>();
    final solicitudRecibida = Completer<void>();

    productRepository.alActualizarProducto = (input) {
      if (!solicitudRecibida.isCompleted) {
        solicitudRecibida.complete();
      }

      return respuestaPendiente.future;
    };

    final primeraSolicitud = _actualizarProductoValido(viewModel);

    await solicitudRecibida.future;

    expect(viewModel.enviandoCambios, isTrue);
    expect(viewModel.estado, EditarProductoEstado.enviandoCambios);

    final segundaSolicitud = await _actualizarProductoValido(viewModel);

    expect(segundaSolicitud, isFalse);
    expect(productRepository.llamadasActualizarProducto, 1);

    respuestaPendiente.complete(
      const Producto(
        id: 1,
        titulo: 'Mochila urbana actualizada',
        precio: 99.95,
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila-original.jpg',
        descripcion: 'Mochila actualizada con compartimento para portátil.',
      ),
    );

    expect(await primeraSolicitud, isTrue);
    expect(viewModel.enviandoCambios, isFalse);
    expect(productRepository.llamadasActualizarProducto, 1);
  });

  test('un error conserva el producto original y permite reintentar', () async {
    await viewModel.inicializar(productoOriginal);

    productRepository.alActualizarProducto = (_) {
      return Future<Producto>.error(
        const ProductoException(
          'No pudimos actualizar el producto. Inténtalo nuevamente.',
        ),
      );
    };

    final resultado = await _actualizarProductoValido(viewModel);

    expect(resultado, isFalse);
    expect(viewModel.productoOriginal, same(productoOriginal));
    expect(viewModel.productoActualizado, isNull);
    expect(viewModel.enviandoCambios, isFalse);
    expect(viewModel.estado, EditarProductoEstado.errorRecuperable);
    expect(
      viewModel.mensajeError,
      'No pudimos actualizar el producto. Inténtalo nuevamente.',
    );
    expect(viewModel.puedeGuardar, isTrue);
  });

  test('si la sesión deja de ser Administrador no ejecuta el PUT', () async {
    await viewModel.inicializar(productoOriginal);

    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    final resultado = await _actualizarProductoValido(viewModel);

    expect(resultado, isFalse);
    expect(productRepository.llamadasActualizarProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
    expect(viewModel.mensajeError, 'No tienes acceso a esta sección.');
  });

  test('un Cliente no carga categorías ni obtiene el formulario', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    await viewModel.inicializar(productoOriginal);

    expect(productRepository.llamadasObtenerCategorias, 0);
    expect(productRepository.llamadasActualizarProducto, 0);
    expect(viewModel.productoOriginal, isNull);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('un Auditor no carga categorías ni obtiene el formulario', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 3,
      rol: RolUsuario.auditor,
    );

    await viewModel.inicializar(productoOriginal);

    expect(productRepository.llamadasObtenerCategorias, 0);
    expect(productRepository.llamadasActualizarProducto, 0);
    expect(viewModel.productoOriginal, isNull);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('una sesión inexistente no carga ni actualiza productos', () async {
    authRepository.sesion = null;

    await viewModel.inicializar(productoOriginal);

    expect(productRepository.llamadasObtenerCategorias, 0);
    expect(productRepository.llamadasActualizarProducto, 0);
    expect(viewModel.productoOriginal, isNull);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });
}

Future<bool> _actualizarProductoValido(EditarProductoViewModel viewModel) {
  return viewModel.actualizarProducto(
    titulo: '  Mochila urbana actualizada  ',
    precio: '99,95',
    categoria: "men's clothing",
    descripcion: '  Mochila actualizada con compartimento para portátil.  ',
  );
}

class FakeProductRepository implements ProductRepository {
  int llamadasCrearProducto = 0;
  int llamadasActualizarProducto = 0;
  int llamadasObtenerCategorias = 0;

  ActualizarProductoInput? ultimoInputActualizacion;

  Future<Producto> Function(ActualizarProductoInput input)?
  alActualizarProducto;

  List<String> categorias = const [
    'electronics',
    'jewelery',
    "men's clothing",
    "women's clothing",
  ];

  @override
  Future<Producto> crearProducto(CrearProductoInput input) {
    llamadasCrearProducto++;

    throw UnimplementedError('Las pruebas de edición no crean productos.');
  }

  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) async {
    llamadasActualizarProducto++;
    ultimoInputActualizacion = input;

    final callback = alActualizarProducto;

    if (callback != null) {
      return callback(input);
    }

    return Producto(
      id: input.id,
      titulo: input.titulo,
      precio: input.precio,
      categoria: input.categoria,
      imageUrl: input.imageUrl,
      descripcion: input.descripcion,
    );
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    llamadasObtenerCategorias++;
    return categorias;
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
    throw UnimplementedError('Las pruebas de edición no inician sesión.');
  }
}
