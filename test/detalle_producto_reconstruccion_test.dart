import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';
import 'package:tienda_flutter/models/sesion_usuario.dart';
import 'package:tienda_flutter/models/solicitud_login.dart';
import 'package:tienda_flutter/repositories/auth_repository.dart';
import 'package:tienda_flutter/repositories/carrito_repository.dart';
import 'package:tienda_flutter/repositories/product_query_repository.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/viewmodels/agregar_carrito_viewmodel.dart';
import 'package:tienda_flutter/viewmodels/detalle_producto_viewmodel.dart';
import 'package:tienda_flutter/viewmodels/eliminar_producto_viewmodel.dart';
import 'package:tienda_flutter/views/detalle_producto_view.dart';

void main() {
  testWidgets(
    'conserva el producto cuando GoRouter reconstruye la ruta de detalle',
    (tester) async {
      final repository = _ProductQueryRepositoryFake();
      final authRepository = _AuthRepositoryAdministrador();

      await tester.pumpWidget(
        MaterialApp(
          home: _construirDetalle(
            repository: repository,
            authRepository: authRepository,
            productoInicial: _producto,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_producto.titulo), findsOneWidget);
      expect(repository.consultasPorId, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: _construirDetalle(
            repository: repository,
            authRepository: authRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_producto.titulo), findsOneWidget);
      expect(find.text('Producto no disponible.'), findsNothing);
      expect(repository.consultasPorId, 0);
    },
  );
}

DetalleProductoView _construirDetalle({
  required ProductQueryRepository repository,
  required AuthRepository authRepository,
  Producto? productoInicial,
}) {
  return DetalleProductoView(
    viewModel: DetalleProductoViewModel(repository),
    agregarCarritoViewModel: AgregarCarritoViewModel(
      _CarritoRepositoryFake(),
      authRepository,
    ),
    eliminarProductoViewModel: EliminarProductoViewModel(
      _ProductRepositoryFake(),
      authRepository,
    ),
    authRepository: authRepository,
    productoId: _producto.id,
    productoInicial: productoInicial,
  );
}

const _producto = Producto(
  id: 1,
  titulo: 'Producto conservado',
  precio: 109.95,
  categoria: "men's clothing",
  imageUrl: 'https://example.com/producto.png',
  descripcion: 'Descripción original del producto.',
);

class _ProductQueryRepositoryFake implements ProductQueryRepository {
  int consultasPorId = 0;

  @override
  Future<Producto> obtenerProductoPorId(int productoId) async {
    consultasPorId++;
    return _producto;
  }

  @override
  Future<List<String>> obtenerCategorias() async => const [];

  @override
  Future<List<Producto>> obtenerProductos() async => const [_producto];

  @override
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    return const [_producto];
  }
}

class _AuthRepositoryAdministrador implements AuthRepository {
  static const _sesion = SesionUsuario(
    token: 'token-administrador',
    idUsuario: 1,
    rol: RolUsuario.administrador,
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

class _CarritoRepositoryFake implements CarritoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProductRepositoryFake implements ProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
