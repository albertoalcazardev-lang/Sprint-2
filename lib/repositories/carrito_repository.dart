import '../models/agregar_carrito_input.dart';
import '../models/carrito_snapshot.dart';

/// Contrato principal del carrito personal.
abstract class CarritoRepository {
  /// Ejecuta primero el POST y después actualiza el carrito local.
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input);

  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario);

  Future<void> limpiarCarrito(int idUsuario);

  Stream<CarritoSnapshot> observarCarrito(int idUsuario);
}
