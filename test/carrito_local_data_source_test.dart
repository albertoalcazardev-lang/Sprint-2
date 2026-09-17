import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/core/storage/carrito_storage.dart';
import 'package:tienda_flutter/data_sources/carrito_local_data_source.dart';
import 'package:tienda_flutter/data_sources/carrito_local_data_source_impl.dart';
import 'package:tienda_flutter/data_sources/carrito_mutable_local_data_source.dart';
import 'package:tienda_flutter/models/producto.dart';

void main() {
  late FakeCarritoStorage storage;
  late CarritoLocalDataSource dataSource;

  const mochila = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila con compartimento para portátil.',
  );

  const audifonos = Producto(
    id: 2,
    titulo: 'Audífonos',
    precio: 25.50,
    categoria: 'electronics',
    imageUrl: 'https://ejemplo.com/audifonos.jpg',
    descripcion: 'Audífonos inalámbricos.',
  );

  setUp(() {
    storage = FakeCarritoStorage();
    dataSource = CarritoLocalDataSourceImpl(storage);
  });

  test('un carrito inexistente se obtiene vacío', () async {
    final carrito = await dataSource.obtenerCarrito(4);

    expect(carrito.idUsuario, 4);
    expect(carrito.items, isEmpty);
    expect(carrito.totalUnidades, 0);
  });

  test('un producto nuevo crea una sola línea', () async {
    final carrito = await dataSource.agregarOFusionarProducto(4, mochila, 2);

    expect(carrito.items, hasLength(1));
    expect(carrito.items.single.producto.id, mochila.id);
    expect(carrito.items.single.cantidad, 2);
    expect(carrito.totalUnidades, 2);
    expect(storage.valores[4], isNotNull);
  });

  test('un producto repetido suma la cantidad', () async {
    await dataSource.agregarOFusionarProducto(4, mochila, 2);

    final carrito = await dataSource.agregarOFusionarProducto(4, mochila, 3);

    expect(carrito.items, hasLength(1));
    expect(carrito.items.single.producto.id, mochila.id);
    expect(carrito.items.single.cantidad, 5);
    expect(carrito.totalUnidades, 5);
  });

  test('la fusión compara exclusivamente el ID del producto', () async {
    const mismoIdConOtroTitulo = Producto(
      id: 1,
      titulo: 'Título modificado',
      precio: 999,
      categoria: 'otra categoría',
      imageUrl: 'https://ejemplo.com/otra.jpg',
      descripcion: 'Otra descripción.',
    );

    await dataSource.agregarOFusionarProducto(4, mochila, 1);

    final carrito = await dataSource.agregarOFusionarProducto(
      4,
      mismoIdConOtroTitulo,
      2,
    );

    expect(carrito.items, hasLength(1));
    expect(carrito.items.single.producto.id, 1);
    expect(carrito.items.single.cantidad, 3);
  });

  test('productos distintos crean líneas diferentes', () async {
    await dataSource.agregarOFusionarProducto(4, mochila, 2);

    final carrito = await dataSource.agregarOFusionarProducto(4, audifonos, 3);

    expect(carrito.items, hasLength(2));
    expect(carrito.totalUnidades, 5);
    expect(carrito.buscarProducto(1)!.cantidad, 2);
    expect(carrito.buscarProducto(2)!.cantidad, 3);
  });

  test('los carritos de usuarios diferentes no se mezclan', () async {
    await dataSource.agregarOFusionarProducto(4, mochila, 2);

    await dataSource.agregarOFusionarProducto(7, audifonos, 3);

    final carritoUsuario4 = await dataSource.obtenerCarrito(4);
    final carritoUsuario7 = await dataSource.obtenerCarrito(7);

    expect(carritoUsuario4.items, hasLength(1));
    expect(carritoUsuario4.buscarProducto(1), isNotNull);
    expect(carritoUsuario4.buscarProducto(2), isNull);

    expect(carritoUsuario7.items, hasLength(1));
    expect(carritoUsuario7.buscarProducto(1), isNull);
    expect(carritoUsuario7.buscarProducto(2), isNotNull);

    expect(storage.valores.keys, containsAll([4, 7]));
  });

  test('una nueva instancia recupera el carrito persistido', () async {
    await dataSource.agregarOFusionarProducto(4, mochila, 2);

    final nuevaInstancia = CarritoLocalDataSourceImpl(storage);

    final carritoRecuperado = await nuevaInstancia.obtenerCarrito(4);

    expect(carritoRecuperado.items, hasLength(1));
    expect(carritoRecuperado.items.single.producto.id, 1);
    expect(carritoRecuperado.items.single.cantidad, 2);
  });

  test('persiste y recupera el identificador remoto de US10', () async {
    final fuenteMutable = dataSource as CarritoMutableLocalDataSource;

    await fuenteMutable.agregarOFusionarProductoConIdRemoto(4, mochila, 2, 21);

    final nuevaInstancia = CarritoLocalDataSourceImpl(storage);
    final carritoRecuperado = await nuevaInstancia.obtenerCarrito(4);

    expect(carritoRecuperado.idCarritoRemoto, 21);
    expect(carritoRecuperado.items.single.cantidad, 2);
  });

  test('limpiar elimina únicamente el carrito solicitado', () async {
    await dataSource.agregarOFusionarProducto(4, mochila, 2);

    await dataSource.agregarOFusionarProducto(7, audifonos, 3);

    await dataSource.limpiarCarrito(4);

    final carritoUsuario4 = await dataSource.obtenerCarrito(4);
    final carritoUsuario7 = await dataSource.obtenerCarrito(7);

    expect(carritoUsuario4.items, isEmpty);
    expect(carritoUsuario7.items, hasLength(1));

    expect(storage.valores.containsKey(4), isFalse);
    expect(storage.valores.containsKey(7), isTrue);
    expect(storage.ultimoUsuarioEliminado, 4);
  });

  test('un JSON corrupto se elimina y recupera como carrito vacío', () async {
    storage.valores[4] = '{json-invalido';

    final carrito = await dataSource.obtenerCarrito(4);

    expect(carrito.idUsuario, 4);
    expect(carrito.items, isEmpty);
    expect(storage.valores.containsKey(4), isFalse);
    expect(storage.ultimoUsuarioEliminado, 4);
  });

  test('un fallo al guardar no modifica el carrito en memoria', () async {
    final carritoInicial = await dataSource.obtenerCarrito(4);

    expect(carritoInicial.items, isEmpty);

    storage.fallarAlGuardar = true;

    await expectLater(
      dataSource.agregarOFusionarProducto(4, mochila, 2),
      throwsA(isA<PersistenciaCarritoException>()),
    );

    storage.fallarAlGuardar = false;

    final carritoDespuesDelError = await dataSource.obtenerCarrito(4);

    expect(carritoDespuesDelError.items, isEmpty);
    expect(carritoDespuesDelError.totalUnidades, 0);
  });

  test('emite el carrito después de persistirlo', () async {
    final siguienteCambio = dataSource.observarCarrito(4).first;

    final carritoDevuelto = await dataSource.agregarOFusionarProducto(
      4,
      mochila,
      2,
    );

    final carritoEmitido = await siguienteCambio;

    expect(carritoEmitido.idUsuario, 4);
    expect(carritoEmitido.totalUnidades, 2);
    expect(carritoEmitido.totalUnidades, carritoDevuelto.totalUnidades);
  });

  test('agregados concurrentes conservan todas las cantidades', () async {
    await Future.wait([
      dataSource.agregarOFusionarProducto(4, mochila, 2),
      dataSource.agregarOFusionarProducto(4, mochila, 3),
    ]);

    final carrito = await dataSource.obtenerCarrito(4);

    expect(carrito.items, hasLength(1));
    expect(carrito.items.single.cantidad, 5);
  });
}

class FakeCarritoStorage implements CarritoStorage {
  final Map<int, String> valores = {};

  bool fallarAlObtener = false;
  bool fallarAlGuardar = false;
  bool fallarAlEliminar = false;

  int? ultimoUsuarioEliminado;

  @override
  Future<String?> obtenerCarrito(int idUsuario) async {
    if (fallarAlObtener) {
      throw const PersistenciaCarritoException('No se pudo leer el carrito.');
    }

    return valores[idUsuario];
  }

  @override
  Future<void> guardarCarrito(int idUsuario, String carritoJson) async {
    if (fallarAlGuardar) {
      throw const PersistenciaCarritoException();
    }

    valores[idUsuario] = carritoJson;
  }

  @override
  Future<void> eliminarCarrito(int idUsuario) async {
    if (fallarAlEliminar) {
      throw const PersistenciaCarritoException(
        'No se pudo eliminar el carrito.',
      );
    }

    ultimoUsuarioEliminado = idUsuario;
    valores.remove(idUsuario);
  }
}
