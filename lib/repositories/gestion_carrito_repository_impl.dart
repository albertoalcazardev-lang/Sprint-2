import 'dart:async';

import '../core/errors/carrito_exception.dart';
import '../data_sources/carrito_local_data_source.dart';
import '../data_sources/carrito_mutable_local_data_source.dart';
import '../models/actualizar_carrito_input.dart';
import '../models/carrito_snapshot.dart';
import '../services/gestion_carrito_service.dart';
import 'gestion_carrito_repository.dart';

class GestionCarritoRepositoryImpl implements GestionCarritoRepository {
  final GestionCarritoService gestionCarritoService;
  final CarritoLocalDataSource carritoLocalDataSource;
  final CarritoMutableLocalDataSource carritoMutableLocalDataSource;

  final Map<int, Future<void>> _operacionesPorUsuario = {};

  GestionCarritoRepositoryImpl(
    this.gestionCarritoService,
    this.carritoLocalDataSource,
    this.carritoMutableLocalDataSource,
  );

  @override
  Future<CarritoSnapshot> actualizarCantidad({
    required int idUsuario,
    required int productoId,
    required int nuevaCantidad,
    required DateTime fecha,
  }) {
    return _ejecutarSecuencialmente(idUsuario, () async {
      _validarIds(idUsuario: idUsuario, productoId: productoId);

      if (nuevaCantidad <= 0) {
        throw const DatosCarritoInvalidosException(
          'La cantidad debe ser mayor que cero.',
        );
      }

      final anterior = await carritoLocalDataSource.obtenerCarrito(idUsuario);
      final idCarrito = _obtenerIdCarrito(anterior);

      final actualizado = await carritoMutableLocalDataSource
          .actualizarCantidad(idUsuario, productoId, nuevaCantidad);

      try {
        await gestionCarritoService.actualizarCarrito(
          ActualizarCarritoInput(
            idCarrito: idCarrito,
            idUsuario: idUsuario,
            fecha: fecha,
            items: actualizado.items,
          ),
        );

        return actualizado;
      } catch (error, stackTrace) {
        await _revertir(anterior);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  @override
  Future<CarritoSnapshot> eliminarProducto({
    required int idUsuario,
    required int productoId,
  }) {
    return _ejecutarSecuencialmente(idUsuario, () async {
      _validarIds(idUsuario: idUsuario, productoId: productoId);

      final anterior = await carritoLocalDataSource.obtenerCarrito(idUsuario);
      final idCarrito = _obtenerIdCarrito(anterior);

      final actualizado = await carritoMutableLocalDataSource.eliminarProducto(
        idUsuario,
        productoId,
      );

      try {
        await gestionCarritoService.eliminarCarrito(idCarrito);
        return actualizado;
      } catch (error, stackTrace) {
        await _revertir(anterior);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  int _obtenerIdCarrito(CarritoSnapshot carrito) {
    final idCarrito = carrito.idCarritoRemoto;

    if (idCarrito == null || idCarrito <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar el carrito remoto.',
      );
    }

    return idCarrito;
  }

  Future<void> _revertir(CarritoSnapshot anterior) async {
    try {
      await carritoMutableLocalDataSource.guardarSnapshot(anterior);
    } catch (_) {
      throw const PersistenciaCarritoException(
        'No pudimos restaurar el carrito después del error.',
      );
    }
  }

  void _validarIds({required int idUsuario, required int productoId}) {
    if (idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }

    if (productoId <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }
  }

  Future<T> _ejecutarSecuencialmente<T>(
    int idUsuario,
    Future<T> Function() operacion,
  ) {
    final resultado = Completer<T>();
    final anterior = _operacionesPorUsuario[idUsuario] ?? Future<void>.value();

    late final Future<void> actual;
    actual = anterior.catchError((Object _) {}).then<void>((_) async {
      try {
        resultado.complete(await operacion());
      } catch (error, stackTrace) {
        resultado.completeError(error, stackTrace);
      }
    });

    _operacionesPorUsuario[idUsuario] = actual;
    actual.whenComplete(() {
      if (identical(_operacionesPorUsuario[idUsuario], actual)) {
        _operacionesPorUsuario.remove(idUsuario);
      }
    });

    return resultado.future;
  }
}
