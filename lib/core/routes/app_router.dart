import 'package:go_router/go_router.dart';

import '../../models/rol_usuario.dart';
import '../../repositories/auth_repository.dart';
import '../../views/base_view.dart';
import '../../views/cuenta_view.dart';
import '../../views/login_view.dart';
import '../../views/usuarios_view.dart';
import '../di/dependency_injection.dart';
import 'ruta_por_rol.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    redirect: (context, state) async {
      final sesion = await getIt<AuthRepository>().obtenerSesion();

      final ubicacionActual = state.matchedLocation;

      // Si no existe una sesión, solo permitimos estar en /login.
      if (sesion == null) {
        if (ubicacionActual != '/login') {
          return '/login';
        }

        return null;
      }

      // Obtiene la página principal correspondiente al rol actual.
      final rutaCorrecta = RutaPorRol.obtener(sesion.rol);

      // US11:
      // Solo el administrador puede acceder al listado de usuarios.
      if (ubicacionActual == '/usuarios' &&
          sesion.rol != RolUsuario.administrador) {
        return rutaCorrecta;
      }

      // Si ya inició sesión, no debe regresar al login
      // ni permanecer en la ruta temporal /inicio.
      if (ubicacionActual == '/login' ||
          ubicacionActual == '/inicio') {
        return rutaCorrecta;
      }

      // Evita que un usuario entre manualmente
      // a la pantalla principal de otro rol.
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

      // US11 - Listar todos los usuarios registrados.
      GoRoute(
        path: '/usuarios',
        builder: (context, state) {
          return const UsuariosView();
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
}