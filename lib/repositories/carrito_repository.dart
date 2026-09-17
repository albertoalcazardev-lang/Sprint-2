import '../models/carrito.dart';

abstract class CarritoRepository {
  Future<List<Carrito>> obtenerCarritos();
}
