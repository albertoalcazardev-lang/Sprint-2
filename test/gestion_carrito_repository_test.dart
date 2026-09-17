import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/data_sources/carrito_local_data_source.dart';
import 'package:tienda_flutter/data_sources/carrito_mutable_local_data_source.dart';
import 'package:tienda_flutter/models/actualizar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/producto_carrito_respuesta_model.dart';
import 'package:tienda_flutter/models/respuesta_carrito_model.dart';
import 'package:tienda_flutter/repositories/gestion_carrito_repository.dart';
import 'package:tienda_flutter/repositories/gestion_carrito_repository_impl.dart';
import 'package:tienda_flutter/services/gestion_carrito_service.dart';

void main() {
  const producto = Producto(
    id: 1,
    titulo: 'Mochila',
    precio: 20,
    categoria: 'bags',
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Descripción',
  );

  late FakeGestionService service;
  late FakeFuenteLocal fuente;
  late GestionCarritoRepository repository;

  setUp(() {
    final orden = <String>[];
    fuente = FakeFuenteLocal(
      CarritoSnapshot(
        idUsuario: 4,
        idCarritoRemoto: 21,
        items: const [ItemCarrito(producto: producto, cantidad: 2)],
      ),
      orden,
    );
    service = FakeGestionService(orden);
    repository = GestionCarritoRepositoryImpl(service, fuente, fuente);
  });

  test(
    'actualiza localmente y después envía PUT con todo el carrito',
    () async {
      final resultado = await repository.actualizarCantidad(
        idUsuario: 4,
        productoId: 1,
        nuevaCantidad: 3,
        fecha: DateTime(2026, 9, 17),
      );

      expect(fuente.orden, ['local-actualizar', 'remoto-put']);
      expect(resultado.buscarProducto(1)!.cantidad, 3);
      expect(service.ultimoInput!.idCarrito, 21);
      expect(service.ultimoInput!.items.single.cantidad, 3);
    },
  );

  test('un fallo del PUT restaura el snapshot anterior', () async {
    service.error = const SinConexionCarritoException();

    await expectLater(
      repository.actualizarCantidad(
        idUsuario: 4,
        productoId: 1,
        nuevaCantidad: 5,
        fecha: DateTime(2026, 9, 17),
      ),
      throwsA(isA<SinConexionCarritoException>()),
    );

    expect(fuente.carrito.buscarProducto(1)!.cantidad, 2);
    expect(fuente.orden, ['local-actualizar', 'remoto-put', 'rollback']);
  });

  test('eliminar usa DELETE y conserva el identificador remoto', () async {
    final resultado = await repository.eliminarProducto(
      idUsuario: 4,
      productoId: 1,
    );

    expect(fuente.orden, ['local-eliminar', 'remoto-delete']);
    expect(resultado.items, isEmpty);
    expect(resultado.idCarritoRemoto, 21);
    expect(service.ultimoIdEliminado, 21);
  });
}

class FakeGestionService implements GestionCarritoService {
  final List<String> orden;
  ActualizarCarritoInput? ultimoInput;
  int? ultimoIdEliminado;
  CarritoException? error;

  FakeGestionService(this.orden);

  @override
  Future<RespuestaCarritoModel> actualizarCarrito(
    ActualizarCarritoInput input,
  ) async {
    orden.add('remoto-put');
    ultimoInput = input;
    final fallo = error;
    if (fallo != null) throw fallo;
    return _respuesta(input.idCarrito, input.idUsuario, input.items);
  }

  @override
  Future<void> eliminarCarrito(int idCarrito) async {
    orden.add('remoto-delete');
    ultimoIdEliminado = idCarrito;
    final fallo = error;
    if (fallo != null) throw fallo;
  }

  RespuestaCarritoModel _respuesta(
    int id,
    int idUsuario,
    List<ItemCarrito> items,
  ) {
    return RespuestaCarritoModel(
      id: id,
      idUsuario: idUsuario,
      fecha: DateTime(2026, 9, 17),
      productos: items
          .map(
            (item) => ProductoCarritoRespuestaModel(
              productoId: item.producto.id,
              cantidad: item.cantidad,
            ),
          )
          .toList(),
    );
  }
}

class FakeFuenteLocal
    implements CarritoLocalDataSource, CarritoMutableLocalDataSource {
  CarritoSnapshot carrito;
  final List<String> orden;

  FakeFuenteLocal(this.carrito, this.orden);

  @override
  Future<CarritoSnapshot> actualizarCantidad(
    int idUsuario,
    int productoId,
    int nuevaCantidad,
  ) async {
    orden.add('local-actualizar');
    final items = carrito.items
        .map(
          (item) => item.producto.id == productoId
              ? item.copiarConCantidad(nuevaCantidad)
              : item,
        )
        .toList();
    carrito = carrito.copiarConItems(items);
    return carrito;
  }

  @override
  Future<CarritoSnapshot> eliminarProducto(
    int idUsuario,
    int productoId,
  ) async {
    orden.add('local-eliminar');
    carrito = carrito.copiarConItems(
      carrito.items.where((item) => item.producto.id != productoId),
    );
    return carrito;
  }

  @override
  Future<void> guardarSnapshot(CarritoSnapshot snapshot) async {
    orden.add('rollback');
    carrito = snapshot;
  }

  @override
  Future<CarritoSnapshot> obtenerCarrito(int idUsuario) async => carrito;

  @override
  Future<CarritoSnapshot> agregarOFusionarProducto(
    int idUsuario,
    Producto producto,
    int cantidad,
  ) => throw UnimplementedError();

  @override
  Future<CarritoSnapshot> agregarOFusionarProductoConIdRemoto(
    int idUsuario,
    Producto producto,
    int cantidad,
    int idCarritoRemoto,
  ) => throw UnimplementedError();

  @override
  Future<void> limpiarCarrito(int idUsuario) async {}

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) =>
      const Stream.empty();
}
