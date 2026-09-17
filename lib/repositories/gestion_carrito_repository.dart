import '../models/carrito_snapshot.dart';

/// Acciones de modificación y eliminación de US10.
abstract class GestionCarritoRepository {
  Future<CarritoSnapshot> actualizarCantidad({
    required int idUsuario,
    required int productoId,
    required int nuevaCantidad,
    required DateTime fecha,
  });

  Future<CarritoSnapshot> eliminarProducto({
    required int idUsuario,
    required int productoId,
  });
}
