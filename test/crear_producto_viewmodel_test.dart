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
import 'package:tienda_flutter/viewmodels/crear_producto_estado.dart';
import 'package:tienda_flutter/viewmodels/crear_producto_viewmodel.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeAuthRepository authRepository;
  late CrearProductoViewModel viewModel;

  const sesionAdministrador = SesionUsuario(
    token: 'token-prueba',
    idUsuario: 1,
    rol: RolUsuario.administrador,
  );

  const productoRespuesta = Producto(
    id: 21,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila urbana con espacio para portátil.',
  );

  setUp(() {
    productRepository = FakeProductRepository();
    authRepository = FakeAuthRepository(sesion: sesionAdministrador);

    viewModel = CrearProductoViewModel(productRepository, authRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('inicializar carga categorías y deja el formulario listo', () async {
    productRepository.categorias = const ['electronics', "men's clothing"];

    await viewModel.inicializar();

    expect(productRepository.llamadasObtenerCategorias, 1);
    expect(viewModel.categorias, ['electronics', "men's clothing"]);
    expect(viewModel.estado, CrearProductoEstado.formularioListo);
  });

  test('datos inválidos no llaman al repositorio', () async {
    final resultado = await viewModel.crearProducto(
      titulo: '',
      precio: '109.95',
      categoria: "men's clothing",
      imageUrl: 'https://ejemplo.com/mochila.jpg',
      descripcion: 'Mochila urbana con espacio para portátil.',
    );

    expect(resultado, isFalse);
    expect(productRepository.llamadasCrearProducto, 0);
    expect(authRepository.llamadasObtenerSesion, 0);
    expect(
      viewModel.mensajeError,
      'Revisa los campos marcados antes de continuar.',
    );
  });

  test('datos válidos llaman una sola vez al repositorio', () async {
    CrearProductoInput? inputRecibido;

    productRepository.alCrearProducto = (input) async {
      inputRecibido = input;
      return productoRespuesta;
    };

    final resultado = await _crearProductoValido(viewModel);

    expect(resultado, isTrue);
    expect(productRepository.llamadasCrearProducto, 1);
    expect(inputRecibido, isNotNull);
    expect(inputRecibido!.titulo, 'Mochila urbana');
    expect(inputRecibido!.precio, 109.95);
    expect(inputRecibido!.categoria, "men's clothing");
    expect(inputRecibido!.imageUrl, 'https://ejemplo.com/mochila.jpg');
  });

  test('durante el envío expone carga e impide duplicados', () async {
    final respuestaPendiente = Completer<Producto>();

    productRepository.alCrearProducto = (_) {
      return respuestaPendiente.future;
    };

    final primeraSolicitud = _crearProductoValido(viewModel);

    expect(viewModel.enviandoProducto, isTrue);
    expect(viewModel.estado, CrearProductoEstado.enviandoProducto);

    final segundaSolicitud = await _crearProductoValido(viewModel);

    expect(segundaSolicitud, isFalse);

    await Future<void>.delayed(Duration.zero);

    expect(productRepository.llamadasCrearProducto, 1);

    respuestaPendiente.complete(productoRespuesta);

    final primerResultado = await primeraSolicitud;

    expect(primerResultado, isTrue);
    expect(viewModel.enviandoProducto, isFalse);
    expect(productRepository.llamadasCrearProducto, 1);
  });

  test('una respuesta exitosa conserva el ID generado', () async {
    productRepository.alCrearProducto = (_) async {
      return productoRespuesta;
    };

    final resultado = await _crearProductoValido(viewModel);

    expect(resultado, isTrue);
    expect(viewModel.idProductoCreado, 21);
    expect(
      viewModel.mensajeExito,
      'Producto creado (Simulación). ID generado: 21',
    );
    expect(viewModel.estado, CrearProductoEstado.productoCreado);
  });

  test('un error deja el formulario en estado recuperable', () async {
    productRepository.alCrearProducto = (_) {
      return Future<Producto>.error(
        const ProductoException(
          'No pudimos crear el producto. Inténtalo nuevamente.',
        ),
      );
    };

    final resultado = await _crearProductoValido(viewModel);

    expect(resultado, isFalse);
    expect(viewModel.idProductoCreado, isNull);
    expect(viewModel.mensajeExito, isNull);
    expect(
      viewModel.mensajeError,
      'No pudimos crear el producto. Inténtalo nuevamente.',
    );
    expect(viewModel.estado, CrearProductoEstado.errorRecuperable);
    expect(viewModel.enviandoProducto, isFalse);
  });

  test('un cliente no puede ejecutar crearProducto', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    final resultado = await _crearProductoValido(viewModel);

    expect(resultado, isFalse);
    expect(productRepository.llamadasCrearProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
    expect(viewModel.mensajeError, 'No tienes acceso a esta sección.');
  });

  test('un auditor no puede cargar categorías', () async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 3,
      rol: RolUsuario.auditor,
    );

    await viewModel.inicializar();

    expect(productRepository.llamadasObtenerCategorias, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });

  test('una sesión inexistente no puede crear productos', () async {
    authRepository.sesion = null;

    final resultado = await _crearProductoValido(viewModel);

    expect(resultado, isFalse);
    expect(productRepository.llamadasCrearProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
  });
}

Future<bool> _crearProductoValido(CrearProductoViewModel viewModel) {
  return viewModel.crearProducto(
    titulo: '  Mochila urbana  ',
    precio: '109,95',
    categoria: "men's clothing",
    imageUrl: '  https://ejemplo.com/mochila.jpg  ',
    descripcion: '  Mochila urbana con espacio para portátil.  ',
  );
}

class FakeProductRepository implements ProductRepository {
  int llamadasCrearProducto = 0;
  int llamadasObtenerCategorias = 0;

  List<String> categorias = const [
    'electronics',
    "men's clothing",
    "women's clothing",
    'jewelery',
  ];

  Future<Producto> Function(CrearProductoInput input)? alCrearProducto;

  CrearProductoInput? ultimoInput;

  @override
  Future<Producto> crearProducto(CrearProductoInput input) async {
    llamadasCrearProducto++;
    ultimoInput = input;

    final callback = alCrearProducto;

    if (callback != null) {
      return callback(input);
    }

    return Producto(
      id: 21,
      titulo: input.titulo,
      precio: input.precio,
      categoria: input.categoria,
      imageUrl: input.imageUrl,
      descripcion: input.descripcion,
    );
  }

  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) {
    throw UnimplementedError(
      'Las pruebas de creación no actualizan productos.',
    );
  }

  @override
  Future<Producto> eliminarProducto(int productoId) {
    throw UnimplementedError('Las pruebas de creación no eliminan productos.');
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    llamadasObtenerCategorias++;
    return categorias;
  }
}

class FakeAuthRepository implements AuthRepository {
  SesionUsuario? sesion;
  int llamadasObtenerSesion = 0;

  FakeAuthRepository({required this.sesion});

  @override
  Future<SesionUsuario?> obtenerSesion() async {
    llamadasObtenerSesion++;
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    sesion = null;
  }

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) {
    throw UnimplementedError();
  }
}
