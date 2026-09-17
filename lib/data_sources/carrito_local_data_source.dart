import '../models/carrito_snapshot.dart';
import '../models/producto.dart';

/// Estado local y persistente de los carritos separados por usuario.
abstract class CarritoLocalDataSource {
  Future<CarritoSnapshot> obtenerCarrito(int idUsuario);

  Future<CarritoSnapshot> agregarOFusionarProducto(
    int idUsuario,
    Producto producto,
    int cantidad,
  );

  Future<void> limpiarCarrito(int idUsuario);

  Stream<CarritoSnapshot> observarCarrito(int idUsuario);
}
