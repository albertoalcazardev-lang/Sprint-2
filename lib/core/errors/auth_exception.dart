class CredencialesInvalidasException implements Exception {
  const CredencialesInvalidasException();
}

class SinConexionException implements Exception {
  const SinConexionException();
}

class AutenticacionException implements Exception {
  final String mensaje;

  const AutenticacionException(this.mensaje);
}
