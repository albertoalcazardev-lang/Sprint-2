import 'item_carrito.dart';

/// US10/E2 — Cuerpo completo requerido por PUT /carts/{id}.
class ActualizarCarritoInput {
  final int idCarrito;
  final int idUsuario;
  final DateTime fecha;
  final List<ItemCarrito> items;

  ActualizarCarritoInput({
    required this.idCarrito,
    required this.idUsuario,
    required this.fecha,
    required List<ItemCarrito> items,
  }) : items = List<ItemCarrito>.unmodifiable(items);
}
