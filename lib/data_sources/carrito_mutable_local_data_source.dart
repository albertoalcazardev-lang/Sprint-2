import '../models/carrito_snapshot.dart';
import '../models/producto.dart';

/// Operaciones locales de US10 separadas del contrato original de US09.
abstract class CarritoMutableLocalDataSource {
  Future<CarritoSnapshot> agregarOFusionarProductoConIdRemoto(
    int idUsuario,
    Producto producto,
    int cantidad,
    int idCarritoRemoto,
  );

  Future<CarritoSnapshot> actualizarCantidad(
    int idUsuario,
    int productoId,
    int nuevaCantidad,
  );

  Future<CarritoSnapshot> eliminarProducto(int idUsuario, int productoId);

  Future<void> guardarSnapshot(CarritoSnapshot carrito);
}
