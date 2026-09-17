import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/di/dependency_injection.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/viewmodels/editar_producto_viewmodel.dart';
import 'package:tienda_flutter/views/editar_producto_view.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeAuthRepository authRepository;

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

  setUp(() async {
    await getIt.reset();

    productRepository = FakeProductRepository();
    authRepository = FakeAuthRepository(sesion: sesionAdministrador);

    getIt.registerFactory<EditarProductoViewModel>(
      () => EditarProductoViewModel(productRepository, authRepository),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('P20 muestra los datos precargados y no muestra la imagen', (
    tester,
  ) async {
    await _mostrarVista(tester, producto: productoOriginal);

    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.text('ADMINISTRADOR'), findsOneWidget);

    expect(find.text('Mochila urbana'), findsOneWidget);
    expect(find.text('109.95'), findsOneWidget);
    expect(find.text("men's clothing"), findsOneWidget);
    expect(
      find.text('Mochila urbana con compartimento para portátil.'),
      findsOneWidget,
    );

    expect(find.text('URL de imagen'), findsNothing);
    expect(find.text('https://ejemplo.com/mochila-original.jpg'), findsNothing);

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('los campos inválidos muestran errores y no ejecutan el PUT', (
    tester,
  ) async {
    await _mostrarVista(tester, producto: productoOriginal);

    final campos = find.byType(TextFormField);

    await tester.enterText(campos.at(0), '   ');
    await tester.enterText(campos.at(1), '0');
    await tester.enterText(campos.at(2), '   ');

    await _tocarBotonVisible(tester, 'Guardar cambios');
    await tester.pump();

    expect(find.text('Completa el título.'), findsOneWidget);
    expect(find.text('El precio debe ser mayor que cero.'), findsOneWidget);
    expect(find.text('Completa la descripción.'), findsOneWidget);

    expect(productRepository.llamadasActualizarProducto, 0);
  });

  testWidgets('una categoría ausente muestra su validación junto al campo', (
    tester,
  ) async {
    const productoSinCategoria = Producto(
      id: 1,
      titulo: 'Mochila urbana',
      precio: 109.95,
      categoria: '',
      imageUrl: 'https://ejemplo.com/mochila-original.jpg',
      descripcion: 'Mochila urbana con compartimento para portátil.',
    );

    await _mostrarVista(tester, producto: productoSinCategoria);

    await _tocarBotonVisible(tester, 'Guardar cambios');
    await tester.pump();

    expect(find.text('Selecciona una categoría.'), findsOneWidget);
    expect(productRepository.llamadasActualizarProducto, 0);
  });

  testWidgets('deshabilita el botón y evita un segundo envío durante el PUT', (
    tester,
  ) async {
    final respuestaPendiente = Completer<Producto>();
    final solicitudRecibida = Completer<void>();

    productRepository.alActualizarProducto = (input) {
      if (!solicitudRecibida.isCompleted) {
        solicitudRecibida.complete();
      }

      return respuestaPendiente.future;
    };

    await _mostrarVista(tester, producto: productoOriginal);

    await _tocarBotonVisible(tester, 'Guardar cambios');
    await tester.pump();

    await solicitudRecibida.future;
    await tester.pump();

    expect(find.text('Guardando cambios...'), findsOneWidget);
    expect(productRepository.llamadasActualizarProducto, 1);

    final boton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Guardando cambios...'),
    );

    expect(boton.onPressed, isNull);

    respuestaPendiente.complete(
      const Producto(
        id: 1,
        titulo: 'Mochila urbana',
        precio: 109.95,
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila-original.jpg',
        descripcion: 'Mochila urbana con compartimento para portátil.',
      ),
    );

    await tester.pumpAndSettle();

    expect(productRepository.llamadasActualizarProducto, 1);
  });

  testWidgets('un éxito entrega el producto actualizado', (tester) async {
    Producto? resultado;

    productRepository.alActualizarProducto = (input) async {
      return Producto(
        id: input.id,
        titulo: input.titulo,
        precio: input.precio,
        categoria: input.categoria,
        imageUrl: input.imageUrl,
        descripcion: input.descripcion,
      );
    };

    await _mostrarVista(
      tester,
      producto: productoOriginal,
      onProductoActualizado: (producto) {
        resultado = producto;
      },
    );

    final campos = find.byType(TextFormField);

    await tester.enterText(campos.at(0), 'Mochila urbana actualizada');
    await tester.enterText(campos.at(1), '99.95');
    await tester.enterText(
      campos.at(2),
      'Mochila actualizada con compartimento para portátil.',
    );

    await _tocarBotonVisible(tester, 'Guardar cambios');
    await tester.pumpAndSettle();

    expect(productRepository.llamadasActualizarProducto, 1);
    expect(resultado, isNotNull);
    expect(resultado!.titulo, 'Mochila urbana actualizada');
    expect(resultado!.precio, 99.95);
    expect(resultado!.imageUrl, productoOriginal.imageUrl);
  });

  testWidgets('Cancelar vuelve sin ejecutar una actualización', (tester) async {
    var llamadasVolver = 0;

    await _mostrarVista(
      tester,
      producto: productoOriginal,
      onVolver: () {
        llamadasVolver++;
      },
    );

    await _tocarBotonVisible(tester, 'Cancelar');
    await tester.pump();

    expect(llamadasVolver, 1);
    expect(productRepository.llamadasActualizarProducto, 0);
  });

  testWidgets('un Cliente no obtiene el formulario funcional', (tester) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    var accesosBloqueados = 0;

    await _mostrarVista(
      tester,
      producto: productoOriginal,
      esperarAnimaciones: false,
      onAccesoNoAutorizado: () {
        accesosBloqueados++;
      },
    );

    expect(accesosBloqueados, 1);
    expect(find.byType(Form), findsNothing);
    expect(productRepository.llamadasObtenerCategorias, 0);
    expect(productRepository.llamadasActualizarProducto, 0);
  });
}

Future<void> _tocarBotonVisible(WidgetTester tester, String texto) async {
  final boton = find.text(texto);

  expect(boton, findsOneWidget);

  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
}

Future<void> _mostrarVista(
  WidgetTester tester, {
  required Producto producto,
  VoidCallback? onVolver,
  ValueChanged<Producto>? onProductoActualizado,
  VoidCallback? onAccesoNoAutorizado,
  bool esperarAnimaciones = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: EditarProductoView(
        producto: producto,
        onVolver: onVolver ?? () {},
        onProductoActualizado: onProductoActualizado ?? (_) {},
        onAccesoNoAutorizado: onAccesoNoAutorizado ?? () {},
      ),
    ),
  );

  if (esperarAnimaciones) {
    await tester.pumpAndSettle();
    return;
  }

  await tester.pump();
  await tester.pump();
}

class FakeProductRepository implements ProductRepository {
  int llamadasCrearProducto = 0;
  int llamadasActualizarProducto = 0;
  int llamadasObtenerCategorias = 0;

  Future<Producto> Function(ActualizarProductoInput input)?
  alActualizarProducto;

  @override
  Future<Producto> crearProducto(CrearProductoInput input) {
    llamadasCrearProducto++;

    throw UnimplementedError('Las pruebas de P20 no crean productos.');
  }

  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) {
    llamadasActualizarProducto++;

    final callback = alActualizarProducto;

    if (callback != null) {
      return callback(input);
    }

    return Future.value(
      Producto(
        id: input.id,
        titulo: input.titulo,
        precio: input.precio,
        categoria: input.categoria,
        imageUrl: input.imageUrl,
        descripcion: input.descripcion,
      ),
    );
  }

  @override
  Future<Producto> eliminarProducto(int productoId) {
    throw UnimplementedError('Las pruebas de P20 no eliminan productos.');
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    llamadasObtenerCategorias++;

    return const [
      'electronics',
      'jewelery',
      "men's clothing",
      "women's clothing",
    ];
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
    throw UnimplementedError('Las pruebas de P20 no inician sesión.');
  }
}
