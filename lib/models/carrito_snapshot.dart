import 'item_carrito.dart';

/// US09/E1-E2 — Estado local completo del carrito de un usuario.
class CarritoSnapshot {
  final int idUsuario;
  final int? idCarritoRemoto;
  final List<ItemCarrito> items;

  CarritoSnapshot({
    required this.idUsuario,
    this.idCarritoRemoto,
    required List<ItemCarrito> items,
  }) : items = List<ItemCarrito>.unmodifiable(items) {
    if (idUsuario <= 0) {
      throw ArgumentError.value(
        idUsuario,
        'idUsuario',
        'El ID del usuario debe ser mayor que cero.',
      );
    }

    if (idCarritoRemoto != null && idCarritoRemoto! <= 0) {
      throw ArgumentError.value(
        idCarritoRemoto,
        'idCarritoRemoto',
        'El ID remoto del carrito debe ser mayor que cero.',
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

  bool get estaVacio => items.isEmpty;

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
    return CarritoSnapshot(
      idUsuario: idUsuario,
      idCarritoRemoto: idCarritoRemoto,
      items: nuevosItems.toList(),
    );
  }

  CarritoSnapshot copiarCon({
    int? idCarritoRemoto,
    Iterable<ItemCarrito>? items,
  }) {
    return CarritoSnapshot(
      idUsuario: idUsuario,
      idCarritoRemoto: idCarritoRemoto ?? this.idCarritoRemoto,
      items: (items ?? this.items).toList(),
    );
  }
}
