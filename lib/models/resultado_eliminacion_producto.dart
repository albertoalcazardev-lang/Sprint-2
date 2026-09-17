/// US08/E1 — Resultado que P16 devuelve al catálogo después del DELETE.
class ResultadoEliminacionProducto {
  static const String mensajeSimulacion =
      'Producto eliminado (Simulación). '
      'Al recargar puede reaparecer.';

  final int productoId;
  final String mensaje;

  const ResultadoEliminacionProducto({
    required this.productoId,
    this.mensaje = mensajeSimulacion,
  });
}
