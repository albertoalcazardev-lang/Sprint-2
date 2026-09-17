import 'dart:async';
import 'dart:convert';

import '../core/errors/carrito_exception.dart';
import '../core/storage/carrito_storage.dart';
import '../models/carrito_snapshot.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../models/producto_model.dart';
import 'carrito_local_data_source.dart';
import 'carrito_mutable_local_data_source.dart';

class CarritoLocalDataSourceImpl
    implements CarritoLocalDataSource, CarritoMutableLocalDataSource {
  final CarritoStorage carritoStorage;

  final Map<int, CarritoSnapshot> _cache = {};
  final Map<int, Future<void>> _operacionesPorUsuario = {};

  final StreamController<CarritoSnapshot> _cambiosController =
      StreamController<CarritoSnapshot>.broadcast();

  CarritoLocalDataSourceImpl(this.carritoStorage);

  @override
  Future<CarritoSnapshot> obtenerCarrito(int idUsuario) async {
    _validarIdUsuario(idUsuario);

    final operacionPendiente = _operacionesPorUsuario[idUsuario];

    if (operacionPendiente != null) {
      await operacionPendiente;
    }

    return _obtenerCarritoInterno(idUsuario);
  }

  @override
  Future<CarritoSnapshot> agregarOFusionarProducto(
    int idUsuario,
    Producto producto,
    int cantidad,
  ) {
    _validarIdUsuario(idUsuario);
    _validarProducto(producto);
    _validarCantidad(cantidad);

    return _agregarOFusionar(
      idUsuario,
      producto,
      cantidad,
      idCarritoRemoto: null,
    );
  }

  @override
  Future<CarritoSnapshot> agregarOFusionarProductoConIdRemoto(
    int idUsuario,
    Producto producto,
    int cantidad,
    int idCarritoRemoto,
  ) {
    _validarIdUsuario(idUsuario);
    _validarProducto(producto);
    _validarCantidad(cantidad);

    if (idCarritoRemoto <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar el carrito remoto.',
      );
    }

    return _agregarOFusionar(
      idUsuario,
      producto,
      cantidad,
      idCarritoRemoto: idCarritoRemoto,
    );
  }

  Future<CarritoSnapshot> _agregarOFusionar(
    int idUsuario,
    Producto producto,
    int cantidad, {
    required int? idCarritoRemoto,
  }) {
    return _ejecutarSecuencialmente(idUsuario, () async {
      final carritoActual = await _obtenerCarritoInterno(idUsuario);

      final itemsActualizados = carritoActual.items.toList();
      final indiceExistente = itemsActualizados.indexWhere(
        (item) => item.producto.id == producto.id,
      );

      if (indiceExistente >= 0) {
        final itemExistente = itemsActualizados[indiceExistente];

        itemsActualizados[indiceExistente] = itemExistente.copiarConCantidad(
          itemExistente.cantidad + cantidad,
        );
      } else {
        itemsActualizados.add(
          ItemCarrito(producto: producto, cantidad: cantidad),
        );
      }

      final carritoActualizado = CarritoSnapshot(
        idUsuario: idUsuario,
        idCarritoRemoto: idCarritoRemoto ?? carritoActual.idCarritoRemoto,
        items: itemsActualizados,
      );

      // Primero se persiste. Solo después se actualizan memoria y vistas.
      await _guardarCarrito(carritoActualizado);

      _cache[idUsuario] = carritoActualizado;
      _cambiosController.add(carritoActualizado);

      return carritoActualizado;
    });
  }

  @override
  Future<CarritoSnapshot> actualizarCantidad(
    int idUsuario,
    int productoId,
    int nuevaCantidad,
  ) {
    _validarIdUsuario(idUsuario);
    _validarCantidad(nuevaCantidad);

    if (productoId <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }

    return _ejecutarSecuencialmente(idUsuario, () async {
      final carritoActual = await _obtenerCarritoInterno(idUsuario);
      final items = carritoActual.items.toList();
      final indice = items.indexWhere((item) => item.producto.id == productoId);

      if (indice < 0) {
        throw const DatosCarritoInvalidosException(
          'El producto ya no está en el carrito.',
        );
      }

      items[indice] = items[indice].copiarConCantidad(nuevaCantidad);
      final actualizado = carritoActual.copiarConItems(items);
      await _publicarCarrito(actualizado);
      return actualizado;
    });
  }

  @override
  Future<CarritoSnapshot> eliminarProducto(int idUsuario, int productoId) {
    _validarIdUsuario(idUsuario);

    if (productoId <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }

    return _ejecutarSecuencialmente(idUsuario, () async {
      final carritoActual = await _obtenerCarritoInterno(idUsuario);
      final items = carritoActual.items
          .where((item) => item.producto.id != productoId)
          .toList();

      if (items.length == carritoActual.items.length) {
        throw const DatosCarritoInvalidosException(
          'El producto ya no está en el carrito.',
        );
      }

      final actualizado = carritoActual.copiarConItems(items);
      await _publicarCarrito(actualizado);
      return actualizado;
    });
  }

  @override
  Future<void> guardarSnapshot(CarritoSnapshot carrito) {
    _validarIdUsuario(carrito.idUsuario);

    return _ejecutarSecuencialmente(carrito.idUsuario, () async {
      await _publicarCarrito(carrito);
    });
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) {
    _validarIdUsuario(idUsuario);

    return _ejecutarSecuencialmente(idUsuario, () async {
      await carritoStorage.eliminarCarrito(idUsuario);

      final carritoVacio = CarritoSnapshot.vacio(idUsuario);

      _cache.remove(idUsuario);
      _cambiosController.add(carritoVacio);
    });
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    _validarIdUsuario(idUsuario);

    return _cambiosController.stream.where(
      (carrito) => carrito.idUsuario == idUsuario,
    );
  }

  Future<CarritoSnapshot> _obtenerCarritoInterno(int idUsuario) async {
    final carritoEnMemoria = _cache[idUsuario];

    if (carritoEnMemoria != null) {
      return carritoEnMemoria;
    }

    final carritoJson = await carritoStorage.obtenerCarrito(idUsuario);

    if (carritoJson == null) {
      final carritoVacio = CarritoSnapshot.vacio(idUsuario);
      _cache[idUsuario] = carritoVacio;

      return carritoVacio;
    }

    try {
      final carrito = _decodificarCarrito(idUsuario, carritoJson);

      _cache[idUsuario] = carrito;

      return carrito;
    } on CarritoException {
      rethrow;
    } on FormatException {
      return _recuperarCarritoCorrupto(idUsuario);
    } catch (_) {
      return _recuperarCarritoCorrupto(idUsuario);
    }
  }

  Future<CarritoSnapshot> _recuperarCarritoCorrupto(int idUsuario) async {
    await carritoStorage.eliminarCarrito(idUsuario);

    final carritoVacio = CarritoSnapshot.vacio(idUsuario);

    _cache[idUsuario] = carritoVacio;
    _cambiosController.add(carritoVacio);

    return carritoVacio;
  }

  Future<void> _guardarCarrito(CarritoSnapshot carrito) async {
    try {
      final carritoJson = jsonEncode({
        'userId': carrito.idUsuario,
        'remoteCartId': carrito.idCarritoRemoto,
        'items': carrito.items.map((item) {
          return {
            'product': {
              'id': item.producto.id,
              'title': item.producto.titulo,
              'price': item.producto.precio,
              'category': item.producto.categoria,
              'image': item.producto.imageUrl,
              'description': item.producto.descripcion,
            },
            'quantity': item.cantidad,
          };
        }).toList(),
      });

      await carritoStorage.guardarCarrito(carrito.idUsuario, carritoJson);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException();
    }
  }

  CarritoSnapshot _decodificarCarrito(
    int idUsuarioEsperado,
    String carritoJson,
  ) {
    if (carritoJson.trim().isEmpty) {
      throw const FormatException('El carrito almacenado está vacío.');
    }

    final datos = jsonDecode(carritoJson);

    if (datos is! Map) {
      throw const FormatException('El carrito almacenado no es válido.');
    }

    final json = Map<String, dynamic>.from(datos);

    final idUsuarioGuardado = _leerEnteroPositivo(
      json['userId'],
      nombreCampo: 'userId',
    );

    if (idUsuarioGuardado != idUsuarioEsperado) {
      throw const FormatException('El carrito pertenece a otro usuario.');
    }

    final idCarritoRemotoJson = json['remoteCartId'];
    final idCarritoRemoto = idCarritoRemotoJson == null
        ? null
        : _leerEnteroPositivo(idCarritoRemotoJson, nombreCampo: 'remoteCartId');

    final itemsJson = json['items'];

    if (itemsJson is! List) {
      throw const FormatException('El carrito no contiene una lista válida.');
    }

    final itemsPorProducto = <int, ItemCarrito>{};

    for (final itemJson in itemsJson) {
      if (itemJson is! Map) {
        throw const FormatException('El carrito contiene una línea inválida.');
      }

      final itemMap = Map<String, dynamic>.from(itemJson);
      final productoJson = itemMap['product'];

      if (productoJson is! Map) {
        throw const FormatException(
          'El carrito contiene un producto inválido.',
        );
      }

      final producto = ProductoModel.fromJson(
        Map<String, dynamic>.from(productoJson),
      ).toEntity();

      final cantidad = _leerEnteroPositivo(
        itemMap['quantity'],
        nombreCampo: 'quantity',
      );

      final itemExistente = itemsPorProducto[producto.id];

      if (itemExistente == null) {
        itemsPorProducto[producto.id] = ItemCarrito(
          producto: producto,
          cantidad: cantidad,
        );
      } else {
        itemsPorProducto[producto.id] = itemExistente.copiarConCantidad(
          itemExistente.cantidad + cantidad,
        );
      }
    }

    return CarritoSnapshot(
      idUsuario: idUsuarioGuardado,
      idCarritoRemoto: idCarritoRemoto,
      items: itemsPorProducto.values.toList(),
    );
  }

  Future<void> _publicarCarrito(CarritoSnapshot carrito) async {
    await _guardarCarrito(carrito);
    _cache[carrito.idUsuario] = carrito;
    _cambiosController.add(carrito);
  }

  int _leerEnteroPositivo(dynamic valor, {required String nombreCampo}) {
    if (valor is! num ||
        !valor.isFinite ||
        valor != valor.truncateToDouble() ||
        valor <= 0) {
      throw FormatException(
        'El carrito contiene un valor inválido para $nombreCampo.',
      );
    }

    return valor.toInt();
  }

  void _validarIdUsuario(int idUsuario) {
    if (idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }
  }

  void _validarProducto(Producto producto) {
    if (producto.id <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }
  }

  void _validarCantidad(int cantidad) {
    if (cantidad <= 0) {
      throw const DatosCarritoInvalidosException(
        'La cantidad debe ser mayor que cero.',
      );
    }
  }

  Future<T> _ejecutarSecuencialmente<T>(
    int idUsuario,
    Future<T> Function() operacion,
  ) {
    final resultado = Completer<T>();

    final operacionAnterior =
        _operacionesPorUsuario[idUsuario] ?? Future<void>.value();

    late final Future<void> operacionActual;

    operacionActual = operacionAnterior.catchError((Object _) {}).then<void>((
      _,
    ) async {
      try {
        final valor = await operacion();

        if (!resultado.isCompleted) {
          resultado.complete(valor);
        }
      } catch (error, stackTrace) {
        if (!resultado.isCompleted) {
          resultado.completeError(error, stackTrace);
        }
      }
    });

    _operacionesPorUsuario[idUsuario] = operacionActual;

    operacionActual.whenComplete(() {
      if (identical(_operacionesPorUsuario[idUsuario], operacionActual)) {
        _operacionesPorUsuario.remove(idUsuario);
      }
    });

    return resultado.future;
  }
}
