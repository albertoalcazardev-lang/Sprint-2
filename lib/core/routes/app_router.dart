import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../repositories/auth_repository.dart';
import '../../viewmodels/detalle_producto_viewmodel.dart';
import '../../views/base_view.dart';
import '../../views/cuenta_view.dart';
import '../../views/detalle_producto_view.dart';
import '../../views/login_view.dart';
import '../di/dependency_injection.dart';
import 'ruta_por_rol.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final sesion = await getIt<AuthRepository>().obtenerSesion();

      final ubicacionActual = state.matchedLocation;

      if (sesion == null) {
        if (ubicacionActual != '/login') {
          return '/login';
        }

        return null;
      }

      final rutaCorrecta = RutaPorRol.obtener(sesion.rol);

      if (ubicacionActual == '/login' || ubicacionActual == '/inicio') {
        return rutaCorrecta;
      }

      final esRutaDePerfil =
          ubicacionActual == '/administrador' ||
          ubicacionActual == '/auditor' ||
          ubicacionActual == '/cliente';

      if (esRutaDePerfil && ubicacionActual != rutaCorrecta) {
        return rutaCorrecta;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final sesionCerrada =
              state.uri.queryParameters['sesionCerrada'] == 'true';

          return LoginView(
            mensajeInformativo: sesionCerrada
                ? 'Sesión cerrada. Tu información local se ha eliminado.'
                : null,
            onLoginExitoso: () {
              context.go('/inicio');
            },
          );
        },
      ),

      GoRoute(
        path: '/inicio',
        builder: (context, state) {
          return const BaseView();
        },
      ),

      GoRoute(
        path: '/administrador',
        builder: (context, state) {
          return const BaseView();
        },
      ),

      GoRoute(
        path: '/auditor',
        builder: (context, state) {
          return const BaseView();
        },
      ),

      GoRoute(
        path: '/cliente',
        builder: (context, state) {
          return const BaseView();
        },
      ),

      GoRoute(
        path: '/cuenta',
        builder: (context, state) {
          return CuentaView(
            onSesionCerrada: () {
              context.go('/login?sesionCerrada=true');
            },
          );
        },
      ),

      // =========================
      // DETALLE DE PRODUCTO - US05
      // =========================
      GoRoute(
        path: '/detalle-producto/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Producto no disponible')),
            );
          }

          return DetalleProductoView(
            viewModel: getIt<DetalleProductoViewModel>(),
            authRepository: getIt<AuthRepository>(),
            productoId: id,
          );
        },
      ),
    ],
  );
}
