import '../models/actualizar_carrito_input.dart';
import '../models/respuesta_carrito_model.dart';

/// Contrato remoto exclusivo para modificar el carrito en US10.
abstract class GestionCarritoService {
  Future<RespuestaCarritoModel> actualizarCarrito(ActualizarCarritoInput input);

  Future<RespuestaCarritoModel> eliminarCarrito(int idCarrito);
}
