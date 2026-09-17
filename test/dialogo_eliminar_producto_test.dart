import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:tienda_flutter/viewmodels/eliminar_producto_viewmodel.dart';
import 'package:tienda_flutter/widgets/dialogo_eliminar_producto.dart';

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

  testWidgets('abrir P22 muestra el producto y no ejecuta la eliminación', (
    tester,
  ) async {
    bool? resultadoDialogo;

    await _abrirDialogo(
      tester,
      producto: producto,
      viewModel: viewModel,
      alCerrar: (resultado) {
        resultadoDialogo = resultado;
      },
    );

    expect(find.text('¿Eliminar este producto?'), findsOneWidget);
    expect(find.text('Mochila urbana'), findsOneWidget);
    expect(find.text('Producto #7'), findsOneWidget);

    expect(productRepository.llamadasEliminarProducto, 0);
    expect(resultadoDialogo, isNull);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(resultadoDialogo, isFalse);
  });

  testWidgets('Cancelar cierra P22 y no llama al Repository', (tester) async {
    bool? resultadoDialogo;

    await _abrirDialogo(
      tester,
      producto: producto,
      viewModel: viewModel,
      alCerrar: (resultado) {
        resultadoDialogo = resultado;
      },
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar este producto?'), findsNothing);
    expect(resultadoDialogo, isFalse);
    expect(productRepository.llamadasEliminarProducto, 0);
  });

  testWidgets('confirmar elimina una sola vez y cierra P22 con true', (
    tester,
  ) async {
    bool? resultadoDialogo;

    await _abrirDialogo(
      tester,
      producto: producto,
      viewModel: viewModel,
      alCerrar: (resultado) {
        resultadoDialogo = resultado;
      },
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(productRepository.llamadasEliminarProducto, 1);
    expect(productRepository.ultimoIdEliminado, producto.id);
    expect(resultadoDialogo, isTrue);
    expect(find.text('¿Eliminar este producto?'), findsNothing);
  });

  testWidgets(
    'durante la eliminación deshabilita botones y evita doble envío',
    (tester) async {
      final respuestaPendiente = Completer<Producto>();

      productRepository.alEliminarProducto = (_) {
        return respuestaPendiente.future;
      };

      bool? resultadoDialogo;

      await _abrirDialogo(
        tester,
        producto: producto,
        viewModel: viewModel,
        alCerrar: (resultado) {
          resultadoDialogo = resultado;
        },
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));

      // No usamos pumpAndSettle porque el indicador de progreso
      // continúa animándose mientras el Future está pendiente.
      await tester.pump();
      await tester.pump();

      expect(productRepository.llamadasEliminarProducto, 1);
      expect(viewModel.eliminando, isTrue);
      expect(find.text('Eliminando...'), findsOneWidget);

      final botonCancelar = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );

      final botonEliminar = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(botonCancelar.onPressed, isNull);
      expect(botonEliminar.onPressed, isNull);

      // Intentar tocar el botón deshabilitado no crea otra petición.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      expect(productRepository.llamadasEliminarProducto, 1);
      expect(resultadoDialogo, isNull);

      respuestaPendiente.complete(producto);
      await tester.pumpAndSettle();

      expect(productRepository.llamadasEliminarProducto, 1);
      expect(resultadoDialogo, isTrue);
      expect(viewModel.eliminando, isFalse);
    },
  );

  testWidgets('un error conserva P22 abierto y permite reintentar', (
    tester,
  ) async {
    productRepository.alEliminarProducto = (_) {
      return Future<Producto>.error(
        const ProductoException(
          'No pudimos eliminar el producto. '
          'Inténtalo nuevamente.',
        ),
      );
    };

    bool? resultadoDialogo;

    await _abrirDialogo(
      tester,
      producto: producto,
      viewModel: viewModel,
      alCerrar: (resultado) {
        resultadoDialogo = resultado;
      },
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(productRepository.llamadasEliminarProducto, 1);
    expect(resultadoDialogo, isNull);

    expect(find.text('¿Eliminar este producto?'), findsOneWidget);
    expect(
      find.text(
        'No pudimos eliminar el producto. '
        'Inténtalo nuevamente.',
      ),
      findsOneWidget,
    );

    final botonEliminar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Eliminar'),
    );

    expect(botonEliminar.onPressed, isNotNull);

    // El segundo intento será exitoso.
    productRepository.alEliminarProducto = null;

    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(productRepository.llamadasEliminarProducto, 2);
    expect(resultadoDialogo, isTrue);
    expect(find.text('¿Eliminar este producto?'), findsNothing);
  });

  testWidgets('un Cliente no alcanza el Repository desde P22', (tester) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    bool? resultadoDialogo;

    await _abrirDialogo(
      tester,
      producto: producto,
      viewModel: viewModel,
      alCerrar: (resultado) {
        resultadoDialogo = resultado;
      },
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(productRepository.llamadasEliminarProducto, 0);
    expect(viewModel.accesoNoAutorizado, isTrue);
    expect(resultadoDialogo, isFalse);
    expect(find.text('¿Eliminar este producto?'), findsNothing);
  });
}

Future<void> _abrirDialogo(
  WidgetTester tester, {
  required Producto producto,
  required EliminarProductoViewModel viewModel,
  required ValueChanged<bool> alCerrar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () async {
                  final resultado = await mostrarDialogoEliminarProducto(
                    context: context,
                    producto: producto,
                    viewModel: viewModel,
                  );

                  alCerrar(resultado);
                },
                child: const Text('Abrir confirmación'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir confirmación'));
  await tester.pumpAndSettle();
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
    throw UnimplementedError('Las pruebas del diálogo no crean productos.');
  }

  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) {
    throw UnimplementedError(
      'Las pruebas del diálogo no actualizan productos.',
    );
  }

  @override
  Future<List<String>> obtenerCategorias() {
    throw UnimplementedError('Las pruebas del diálogo no cargan categorías.');
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
    throw UnimplementedError('Las pruebas del diálogo no inician sesión.');
  }
}
