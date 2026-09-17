import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tienda_flutter/core/di/dependency_injection.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/views/base_view.dart';

void main() {
  late GoRouter router;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(_ClienteAuthRepository());

    router = GoRouter(
      initialLocation: '/cliente',
      routes: [
        GoRoute(
          path: '/cliente',
          builder: (context, state) => const BaseView(),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Carrito de prueba'))),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
  });

  testWidgets('Regresar desde el carrito vuelve al catálogo', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mi carrito'));
    await tester.pumpAndSettle();

    expect(find.text('Carrito de prueba'), findsOneWidget);

    final atendido = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(atendido, isTrue);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Carrito de prueba'), findsNothing);
  });
}

class _ClienteAuthRepository implements AuthRepository {
  static const _sesion = SesionUsuario(
    token: 'token-cliente',
    idUsuario: 4,
    rol: RolUsuario.cliente,
  );

  @override
  Future<SesionUsuario?> obtenerSesion() async => _sesion;

  @override
  Future<void> cerrarSesion() async {}

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) async {
    return _sesion;
  }
}
