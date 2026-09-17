/// US07/E1 — Datos validados para actualizar un producto existente.
class ActualizarProductoInput {
  final int id;
  final String titulo;
  final double precio;
  final String categoria;
  final String imageUrl;
  final String descripcion;

  const ActualizarProductoInput({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.categoria,
    required this.imageUrl,
    required this.descripcion,
  });
}
