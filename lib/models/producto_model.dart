import 'producto.dart';

class ProductoModel {
  final int id;
  final String titulo;
  final double precio;
  final String categoria;
  final String imageUrl;
  final String descripcion;

  const ProductoModel({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.categoria,
    required this.imageUrl,
    required this.descripcion,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final precio = json['price'];

    if (id is! num || id.toInt() <= 0) {
      throw const FormatException(
        'La respuesta del servidor no contiene un ID válido.',
      );
    }

    if (precio is! num) {
      throw const FormatException(
        'La respuesta del servidor contiene un precio inválido.',
      );
    }

    return ProductoModel(
      id: id.toInt(),
      titulo: _leerTexto(json, 'title'),
      precio: precio.toDouble(),
      categoria: _leerTexto(json, 'category'),
      imageUrl: _leerTexto(json, 'image'),
      descripcion: _leerTexto(json, 'description'),
    );
  }

  Producto toEntity() {
    return Producto(
      id: id,
      titulo: titulo,
      precio: precio,
      categoria: categoria,
      imageUrl: imageUrl,
      descripcion: descripcion,
    );
  }

  static String _leerTexto(Map<String, dynamic> json, String clave) {
    final valor = json[clave];

    if (valor is! String || valor.trim().isEmpty) {
      throw FormatException(
        'La respuesta del servidor contiene un valor inválido para $clave.',
      );
    }

    return valor.trim();
  }
}
