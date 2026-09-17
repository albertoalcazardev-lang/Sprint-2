/// US09/E1-E2 — Producto confirmado por la respuesta de POST /carts.
class ProductoCarritoRespuestaModel {
  final int productoId;
  final int cantidad;

  const ProductoCarritoRespuestaModel({
    required this.productoId,
    required this.cantidad,
  });

  factory ProductoCarritoRespuestaModel.fromJson(Map<String, dynamic> json) {
    final productoId = _leerEnteroPositivo(
      json['productId'],
      nombreCampo: 'productId',
    );

    final cantidad = _leerEnteroPositivo(
      json['quantity'],
      nombreCampo: 'quantity',
    );

    return ProductoCarritoRespuestaModel(
      productoId: productoId,
      cantidad: cantidad,
    );
  }

  static int _leerEnteroPositivo(dynamic valor, {required String nombreCampo}) {
    if (valor is! num ||
        !valor.isFinite ||
        valor != valor.truncateToDouble() ||
        valor <= 0) {
      throw FormatException(
        'La respuesta contiene un valor inválido para $nombreCampo.',
      );
    }

    return valor.toInt();
  }
}
