import 'producto.dart';

/// US09/E1-E2 — Línea única de un producto dentro del carrito.
class ItemCarrito {
  final Producto producto;
  final int cantidad;

  const ItemCarrito({required this.producto, required this.cantidad})
    : assert(cantidad > 0);

  double get subtotal {
    return producto.precio * cantidad;
  }

  ItemCarrito copiarConCantidad(int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      throw ArgumentError.value(
        nuevaCantidad,
        'nuevaCantidad',
        'La cantidad debe ser mayor que cero.',
      );
    }

    return ItemCarrito(producto: producto, cantidad: nuevaCantidad);
  }
}
