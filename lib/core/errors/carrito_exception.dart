class CarritoException implements Exception {
  final String mensaje;

  const CarritoException(this.mensaje);

  @override
  String toString() => mensaje;
}
