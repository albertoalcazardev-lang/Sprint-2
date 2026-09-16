import 'package:go_router/go_router.dart';

import '../../models/rol_usuario.dart';
import '../../repositories/auth_repository.dart';
import '../../views/base_view.dart';
import '../../views/crear_producto_view.dart';
import '../../views/cuenta_view.dart';
import '../../views/login_view.dart';
import '../di/dependency_injection.dart';
import 'ruta_por_rol.dart';

class AppRouter {
  AppRouter._();

  static const String rutaCrearProducto = '/products/new';

  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    /// US06/E3 — P32: protege la creación antes de construir el formulario.
    redirect: (context, state) async {
      final sesion = await getIt<AuthRepository>().obtenerSesion();
      final ubicacionActual = state.matchedLocation;

      final accesoDenegado =
          state.uri.queryParameters['accesoDenegado'] == 'true';

      if (sesion == null) {
        if (ubicacionActual != '/login') {
          return '/login';
        }

        return null;
      }

      final rutaCorrecta = RutaPorRol.obtener(sesion.rol);

      if (ubicacionActual == rutaCrearProducto &&
          sesion.rol != RolUsuario.administrador) {
        return '$rutaCorrecta?accesoDenegado=true';
      }

      if (ubicacionActual == '/login' || ubicacionActual == '/inicio') {
        if (accesoDenegado) {
          return '$rutaCorrecta?accesoDenegado=true';
        }

        return rutaCorrecta;
      }

      final esRutaDePerfil =
          ubicacionActual == '/administrador' ||
          ubicacionActual == '/auditor' ||
          ubicacionActual == '/cliente';

      if (esRutaDePerfil && ubicacionActual != rutaCorrecta) {
        if (accesoDenegado) {
          return '$rutaCorrecta?accesoDenegado=true';
        }

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
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeAccesoDenegado(state),
          );
        },
      ),
      GoRoute(
        path: '/administrador',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeAccesoDenegado(state),
          );
        },
      ),
      GoRoute(
        path: '/auditor',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeAccesoDenegado(state),
          );
        },
      ),
      GoRoute(
        path: '/cliente',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeAccesoDenegado(state),
          );
        },
      ),
      GoRoute(
        name: 'crearProducto',
        path: rutaCrearProducto,
        builder: (context, state) {
          return CrearProductoView(
            onVolver: () {
              context.go('/administrador');
            },
            onAccesoNoAutorizado: () {
              context.go('/inicio?accesoDenegado=true');
            },
          );
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
    ],
  );

  static String? _obtenerMensajeAccesoDenegado(GoRouterState state) {
    final accesoDenegado =
        state.uri.queryParameters['accesoDenegado'] == 'true';

    if (!accesoDenegado) {
      return null;
    }

    return 'No tienes acceso a esta sección.';
  }
}
