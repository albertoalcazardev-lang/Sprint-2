import '../models/agregar_carrito_input.dart';
import '../models/respuesta_carrito_model.dart';

/// Contrato remoto para las operaciones de carrito.
abstract class CarritoService {
  /// US09/E1-E2 — Envía POST /carts y devuelve la respuesta validada.
  Future<RespuestaCarritoModel> agregarProducto(AgregarCarritoInput input);
}
