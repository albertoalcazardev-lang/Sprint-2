/// US06/E1 — Datos necesarios para crear un producto.
class CrearProductoInput {
  final String titulo;
  final double precio;
  final String categoria;
  final String imageUrl;
  final String descripcion;

  const CrearProductoInput({
    required this.titulo,
    required this.precio,
    required this.categoria,
    required this.imageUrl,
    required this.descripcion,
  });
}
