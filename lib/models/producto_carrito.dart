class ProductoCarrito {
  final int productoId;
  final int cantidad;

  const ProductoCarrito({
    required this.productoId,
    required this.cantidad,
  });

  factory ProductoCarrito.fromJson(Map<String, dynamic> json) {
    return ProductoCarrito(
      productoId: (json['productId'] as num).toInt(),
      cantidad: (json['quantity'] as num).toInt(),
    );
  }
}
