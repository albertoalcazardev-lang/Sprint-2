import '../models/crear_producto_input.dart';
import '../models/producto.dart';

abstract class ProductRepository {
  Future<Producto> crearProducto(CrearProductoInput input);

  Future<List<String>> obtenerCategorias();
}
