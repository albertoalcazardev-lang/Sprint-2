/// Error controlado del flujo de carrito.
class CarritoException implements Exception {
  final String mensaje;

  const CarritoException(this.mensaje);

  @override
  String toString() => mensaje;
}

class SinConexionCarritoException extends CarritoException {
  const SinConexionCarritoException()
    : super('Sin conexión. Revisa tu acceso a internet.');
}

class TiempoEsperaCarritoException extends CarritoException {
  const TiempoEsperaCarritoException()
    : super('La solicitud tardó demasiado. Inténtalo nuevamente.');
}

class RespuestaCarritoInvalidaException extends CarritoException {
  const RespuestaCarritoInvalidaException([
    super.mensaje = 'La respuesta del servidor no es válida.',
  ]);
}

class DatosCarritoInvalidosException extends CarritoException {
  const DatosCarritoInvalidosException(super.mensaje);
}

class PersistenciaCarritoException extends CarritoException {
  const PersistenciaCarritoException([
    super.mensaje =
        'No pudimos guardar el carrito localmente. '
        'Inténtalo nuevamente.',
  ]);
}
