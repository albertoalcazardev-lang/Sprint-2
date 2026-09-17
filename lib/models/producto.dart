class Producto {
  final int id;
  final String titulo;
  final double precio;
  final String categoria;
  final String imageUrl;
  final String descripcion;

  const Producto({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.categoria,
    required this.imageUrl,
    required this.descripcion,
  });
}
