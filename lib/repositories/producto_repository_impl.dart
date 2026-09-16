import '../models/producto.dart';
import '../services/producto_service.dart';
import 'producto_repository.dart';

class ProductoRepositoryImpl implements ProductoRepository {
  final ProductoService productoService;

  ProductoRepositoryImpl(this.productoService);

  @override
  Future<List<Producto>> obtenerProductos() async {
    return await productoService.obtenerProductos();
  }
}
