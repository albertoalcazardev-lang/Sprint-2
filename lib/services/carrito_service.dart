import '../models/carrito.dart';

abstract class CarritoService {
  Future<List<Carrito>> obtenerCarritos();
}
