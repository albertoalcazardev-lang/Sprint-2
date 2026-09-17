import '../models/carrito.dart';
import '../services/historico_carrito_service.dart';
import 'historico_carrito_repository.dart';

class HistoricoCarritoRepositoryImpl implements HistoricoCarritoRepository {
  final HistoricoCarritoService historicoCarritoService;

  HistoricoCarritoRepositoryImpl(this.historicoCarritoService);

  @override
  Future<List<Carrito>> obtenerCarritos() {
    return historicoCarritoService.obtenerCarritos();
  }
}
