import 'producto_carrito_respuesta_model.dart';

/// US09/E1-E2 — Respuesta validada de POST /carts.
class RespuestaCarritoModel {
  final int id;
  final int idUsuario;
  final DateTime fecha;
  final List<ProductoCarritoRespuestaModel> productos;

  RespuestaCarritoModel({
    required this.id,
    required this.idUsuario,
    required this.fecha,
    required List<ProductoCarritoRespuestaModel> productos,
  }) : productos = List<ProductoCarritoRespuestaModel>.unmodifiable(productos);

  factory RespuestaCarritoModel.fromJson(Map<String, dynamic> json) {
    final id = _leerEnteroPositivo(json['id'], nombreCampo: 'id');

    final idUsuario = _leerEnteroPositivo(
      json['userId'],
      nombreCampo: 'userId',
    );

    final fecha = _leerFecha(json['date']);

    final productosJson = json['products'];

    if (productosJson is! List || productosJson.isEmpty) {
      throw const FormatException(
        'La respuesta del servidor no contiene productos válidos.',
      );
    }

    final productos = productosJson.map((productoJson) {
      if (productoJson is! Map) {
        throw const FormatException(
          'La respuesta contiene un producto inválido.',
        );
      }

      return ProductoCarritoRespuestaModel.fromJson(
        Map<String, dynamic>.from(productoJson),
      );
    }).toList();

    return RespuestaCarritoModel(
      id: id,
      idUsuario: idUsuario,
      fecha: fecha,
      productos: productos,
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

  static DateTime _leerFecha(dynamic valor) {
    if (valor is! String || valor.trim().isEmpty) {
      throw const FormatException(
        'La respuesta del servidor no contiene una fecha válida.',
      );
    }

    final fecha = DateTime.tryParse(valor.trim());

    if (fecha == null) {
      throw const FormatException(
        'La respuesta del servidor contiene una fecha inválida.',
      );
    }

    return fecha;
  }
}
