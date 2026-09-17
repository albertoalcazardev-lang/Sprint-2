import 'producto.dart';

/// US09/E1-E2 — Datos necesarios para agregar un producto al carrito.
class AgregarCarritoInput {
  final int idUsuario;
  final Producto producto;
  final int cantidad;
  final DateTime fecha;

  const AgregarCarritoInput({
    required this.idUsuario,
    required this.producto,
    required this.cantidad,
    required this.fecha,
  });
}
