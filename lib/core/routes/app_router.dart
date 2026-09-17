import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/producto.dart';
import '../../models/rol_usuario.dart';
import '../../repositories/auth_repository.dart';
import '../../views/base_view.dart';
import '../../views/carrito_view.dart';
import '../../views/carritos_view.dart';
import '../../views/crear_producto_view.dart';
import '../../views/cuenta_view.dart';
import '../../views/detalle_producto_view.dart';
import '../../views/editar_producto_view.dart';
import '../../views/login_view.dart';
import '../../views/usuarios_view.dart';
import '../di/dependency_injection.dart';
import 'ruta_por_rol.dart';

class AppRouter {
  AppRouter._();

  static const String rutaCrearProducto = '/products/new';
  static const String rutaEditarProducto = '/products/:id/edit';
  static const String rutaCarrito = '/cart';

  static final RegExp _patronRutaEdicion = RegExp(r'^/products/[^/]+/edit$');

  static String rutaEditarProductoPara(int id) {
    return '/products/$id/edit';
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    /// US06/E3 y US07/E3 — Protege las operaciones administrativas.
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

      final esRutaAdministrativa =
          ubicacionActual == rutaCrearProducto ||
          _patronRutaEdicion.hasMatch(ubicacionActual) ||
          ubicacionActual == '/usuarios' ||
          ubicacionActual == '/carritos';

      if (esRutaAdministrativa && sesion.rol != RolUsuario.administrador) {
        return '$rutaCorrecta?accesoDenegado=true';
      }

      if (ubicacionActual == rutaCarrito && sesion.rol != RolUsuario.cliente) {
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
            mensajeAccesoDenegado: _obtenerMensajeCatalogo(state),
            mensajeInformativo: _obtenerMensajeInformativo(state),
          );
        },
      ),
      GoRoute(
        path: '/administrador',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeCatalogo(state),
            mensajeInformativo: _obtenerMensajeInformativo(state),
          );
        },
      ),
      GoRoute(
        path: '/auditor',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeCatalogo(state),
            mensajeInformativo: _obtenerMensajeInformativo(state),
          );
        },
      ),
      GoRoute(
        path: '/cliente',
        builder: (context, state) {
          return BaseView(
            mensajeAccesoDenegado: _obtenerMensajeCatalogo(state),
            mensajeInformativo: _obtenerMensajeInformativo(state),
          );
        },
      ),
      GoRoute(
        name: 'detalleProducto',
        path: '/detalle-producto/:id',
        redirect: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null || id <= 0
              ? '/inicio?productoNoDisponible=true'
              : null;
        },
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra;

          return DetalleProductoView(
            viewModel: getIt(),
            agregarCarritoViewModel: getIt(),
            eliminarProductoViewModel: getIt(),
            authRepository: getIt<AuthRepository>(),
            productoId: id,
            productoInicial: extra is Producto ? extra : null,
          );
        },
      ),
      GoRoute(
        name: 'crearProducto',
        path: rutaCrearProducto,
        builder: (context, state) {
          return CrearProductoView(
            onVolver: () {
              _volverORuta(context, '/administrador');
            },
            onAccesoNoAutorizado: () {
              context.go('/inicio?accesoDenegado=true');
            },
          );
        },
      ),

      /// US07/E1-E3 — P20 y protección de navegación.
      GoRoute(
        name: 'editarProducto',
        path: rutaEditarProducto,
        redirect: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          final producto = state.extra;

          final productoValido =
              id != null && id > 0 && producto is Producto && producto.id == id;

          if (!productoValido) {
            return '/administrador?productoNoDisponible=true';
          }

          return null;
        },
        builder: (context, state) {
          final producto = state.extra;

          if (producto is! Producto) {
            return const BaseView(
              mensajeAccesoDenegado:
                  'No se encontró el producto que intentas editar.',
            );
          }

          return EditarProductoView(
            producto: producto,
            onVolver: () {
              _volverORuta(context, '/administrador');
            },
            onProductoActualizado: (productoActualizado) {
              if (context.canPop()) {
                context.pop(productoActualizado);
                return;
              }

              context.go('/administrador');
            },
            onAccesoNoAutorizado: () {
              context.go('/inicio?accesoDenegado=true');
            },
          );
        },
      ),
      GoRoute(
        name: 'usuarios',
        path: '/usuarios',
        builder: (context, state) {
          return const UsuariosView();
        },
      ),
      GoRoute(
        name: 'carritosGlobales',
        path: '/carritos',
        builder: (context, state) {
          return const CarritosView();
        },
      ),
      GoRoute(
        name: 'carrito',
        path: rutaCarrito,
        builder: (context, state) {
          return CarritoView(
            onExplorarCatalogo: () {
              _volverORuta(context, '/cliente');
            },
            onIrACuenta: () {
              context.push('/cuenta');
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

  static String? _obtenerMensajeCatalogo(GoRouterState state) {
    final accesoDenegado =
        state.uri.queryParameters['accesoDenegado'] == 'true';

    if (accesoDenegado) {
      return 'No tienes acceso a esta sección.';
    }

    final productoNoDisponible =
        state.uri.queryParameters['productoNoDisponible'] == 'true';

    if (productoNoDisponible) {
      return 'No se encontró el producto que intentas editar.';
    }

    return null;
  }

  static void _volverORuta(BuildContext context, String rutaAlternativa) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(rutaAlternativa);
  }

  static String? _obtenerMensajeInformativo(GoRouterState state) {
    if (state.uri.queryParameters['productoEliminado'] == 'true') {
      return 'Producto eliminado (Simulación). Al recargar puede reaparecer.';
    }

    return null;
  }
}
