import '../models/carrito.dart';
import '../services/carrito_service.dart';
import 'carrito_repository.dart';

class CarritoRepositoryImpl implements CarritoRepository {
  final CarritoService carritoService;

  CarritoRepositoryImpl(this.carritoService);

  @override
  Future<List<Carrito>> obtenerCarritos() {
    return carritoService.obtenerCarritos();
  }
}
