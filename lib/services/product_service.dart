import '../models/crear_producto_input.dart';
import '../models/producto_model.dart';

abstract class ProductService {
  Future<ProductoModel> crearProducto(CrearProductoInput input);

  Future<List<String>> obtenerCategorias();
}
