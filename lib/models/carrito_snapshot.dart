import 'item_carrito.dart';

/// US09/E1-E2 — Estado local completo del carrito de un usuario.
class CarritoSnapshot {
  final int idUsuario;
  final List<ItemCarrito> items;

  CarritoSnapshot({required this.idUsuario, required List<ItemCarrito> items})
    : items = List<ItemCarrito>.unmodifiable(items) {
    if (idUsuario <= 0) {
      throw ArgumentError.value(
        idUsuario,
        'idUsuario',
        'El ID del usuario debe ser mayor que cero.',
      );
    }
  }

  factory CarritoSnapshot.vacio(int idUsuario) {
    return CarritoSnapshot(idUsuario: idUsuario, items: const []);
  }

  int get totalUnidades {
    return items.fold<int>(0, (total, item) => total + item.cantidad);
  }

  int get productosDistintos {
    return items.length;
  }

  double get total {
    return items.fold<double>(
      0,
      (acumulado, item) => acumulado + item.subtotal,
    );
  }

  ItemCarrito? buscarProducto(int productoId) {
    for (final item in items) {
      if (item.producto.id == productoId) {
        return item;
      }
    }

    return null;
  }

  CarritoSnapshot copiarConItems(Iterable<ItemCarrito> nuevosItems) {
    return CarritoSnapshot(idUsuario: idUsuario, items: nuevosItems.toList());
  }
}
