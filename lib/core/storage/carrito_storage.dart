/// Almacenamiento local no sensible para carritos separados por usuario.
abstract class CarritoStorage {
  Future<String?> obtenerCarrito(int idUsuario);

  Future<void> guardarCarrito(int idUsuario, String carritoJson);

  Future<void> eliminarCarrito(int idUsuario);
}
