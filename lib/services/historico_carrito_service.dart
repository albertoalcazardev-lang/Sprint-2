import '../models/carrito.dart';

abstract class HistoricoCarritoService {
  Future<List<Carrito>> obtenerCarritos();
}
