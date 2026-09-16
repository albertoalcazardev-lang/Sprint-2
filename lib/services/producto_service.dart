import '../models/producto.dart';

abstract class ProductoService {
  Future<List<Producto>> obtenerProductos();
}
