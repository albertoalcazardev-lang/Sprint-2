class ProductoException implements Exception {
  final String mensaje;

  const ProductoException(this.mensaje);

  @override
  String toString() => mensaje;
}

class SinConexionProductoException extends ProductoException {
  const SinConexionProductoException()
    : super('Sin conexión. Revisa tu acceso a internet.');
}

class TiempoEsperaProductoException extends ProductoException {
  const TiempoEsperaProductoException()
    : super('La solicitud tardó demasiado. Inténtalo nuevamente.');
}

class RespuestaProductoInvalidaException extends ProductoException {
  const RespuestaProductoInvalidaException([
    super.mensaje = 'La respuesta del servidor no es válida.',
  ]);
}
