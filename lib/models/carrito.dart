import 'producto_carrito.dart';

class Carrito {
  final int id;
  final int usuarioId;
  final DateTime fecha;
  final List<ProductoCarrito> productos;

  const Carrito({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.productos,
  });

  int get totalArticulos => productos.fold(
    0,
    (total, producto) => total + producto.cantidad,
  );

  int get totalProductosDiferentes => productos.length;

  factory Carrito.fromJson(Map<String, dynamic> json) {
    final productosJson = json['products'] as List<dynamic>? ?? const [];

    return Carrito(
      id: (json['id'] as num).toInt(),
      usuarioId: (json['userId'] as num).toInt(),
      fecha: DateTime.parse(json['date'].toString()).toLocal(),
      productos: productosJson
          .map(
            (producto) => ProductoCarrito.fromJson(
              Map<String, dynamic>.from(producto as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
