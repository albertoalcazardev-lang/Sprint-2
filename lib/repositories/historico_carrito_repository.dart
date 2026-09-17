import '../models/carrito.dart';

abstract class HistoricoCarritoRepository {
  Future<List<Carrito>> obtenerCarritos();
}
