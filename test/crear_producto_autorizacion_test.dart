import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/di/dependency_injection.dart';
import 'package:tienda_flutter/core/network/conectividad_service.dart';
import 'package:tienda_flutter/core/routes/app_router.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/viewmodels/crear_producto_viewmodel.dart';
import 'package:tienda_flutter/viewmodels/login_viewmodel.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeProductRepository productRepository;

  setUp(() async {
    await getIt.reset();

    authRepository = FakeAuthRepository();
    productRepository = FakeProductRepository();

    getIt.registerSingleton<AuthRepository>(authRepository);

    getIt.registerSingleton<ProductRepository>(productRepository);

    getIt.registerFactory<LoginViewModel>(
      () => LoginViewModel(authRepository, FakeConectividadService()),
    );

    getIt.registerFactory<CrearProductoViewModel>(
      () => CrearProductoViewModel(productRepository, authRepository),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('Administrador puede abrir la creación de producto', (
    tester,
  ) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-admin',
      idUsuario: 1,
      rol: RolUsuario.administrador,
    );

    await _abrirRuta(tester, AppRouter.rutaCrearProducto);

    expect(find.text('Nuevo producto'), findsOneWidget);
    expect(find.text('Guardar producto'), findsOneWidget);
    expect(find.text('ADMINISTRADOR'), findsOneWidget);
    expect(productRepository.llamadasObtenerCategorias, 1);
  });

  testWidgets('guardado exitoso muestra una confirmación visible', (
    tester,
  ) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-admin',
      idUsuario: 1,
      rol: RolUsuario.administrador,
    );

    await _abrirRuta(tester, AppRouter.rutaCrearProducto);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Audífonos Bluetooth Pro');
    await tester.enterText(campos.at(1), '49.99');
    await tester.enterText(campos.at(2), 'https://example.com/audifonos.png');
    await tester.enterText(
      campos.at(3),
      'Audífonos inalámbricos con batería de larga duración.',
    );

    final selectorCategoria = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(selectorCategoria);
    await tester.tap(selectorCategoria);
    await tester.pumpAndSettle();
    await tester.tap(find.text('electronics').last);
    await tester.pumpAndSettle();

    final guardar = find.text('Guardar producto');
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(productRepository.llamadasCrearProducto, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Producto creado (Simulación). ID generado: 21'),
      findsWidgets,
    );
  });

  testWidgets('Cliente es redirigido y no construye el formulario', (
    tester,
  ) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-cliente',
      idUsuario: 2,
      rol: RolUsuario.cliente,
    );

    await _abrirRuta(tester, AppRouter.rutaCrearProducto);

    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('No tienes acceso a esta sección.'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsNothing);
    expect(find.text('+ Nuevo'), findsNothing);
    expect(productRepository.llamadasObtenerCategorias, 0);
  });

  testWidgets('Auditor es redirigido y no construye el formulario', (
    tester,
  ) async {
    authRepository.sesion = const SesionUsuario(
      token: 'token-auditor',
      idUsuario: 3,
      rol: RolUsuario.auditor,
    );

    await _abrirRuta(tester, AppRouter.rutaCrearProducto);

    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('No tienes acceso a esta sección.'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsNothing);
    expect(find.text('+ Nuevo'), findsNothing);
    expect(productRepository.llamadasObtenerCategorias, 0);
  });

  testWidgets('Usuario sin sesión es enviado al login', (tester) async {
    authRepository.sesion = null;

    await _abrirRuta(tester, AppRouter.rutaCrearProducto);

    expect(find.text('Todo empieza por aquí.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsNothing);
    expect(productRepository.llamadasObtenerCategorias, 0);
  });
}

Future<void> _abrirRuta(WidgetTester tester, String ruta) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: AppRouter.router));

  AppRouter.router.go(ruta);

  await tester.pumpAndSettle();
}

class FakeConectividadService implements ConectividadService {
  @override
  Future<bool> hayConexion() async {
    return true;
  }
}

class FakeAuthRepository implements AuthRepository {
  SesionUsuario? sesion;

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
    throw UnimplementedError();
  }
}

class FakeProductRepository implements ProductRepository {
  int llamadasCrearProducto = 0;
  int llamadasObtenerCategorias = 0;

  @override
  Future<Producto> crearProducto(CrearProductoInput input) async {
    llamadasCrearProducto++;

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
      'Las pruebas de autorización de US06 no actualizan productos.',
    );
  }

  @override
  Future<Producto> eliminarProducto(int productoId) {
    throw UnimplementedError(
      'Las pruebas de autorización de US06 '
      'no eliminan productos.',
    );
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
