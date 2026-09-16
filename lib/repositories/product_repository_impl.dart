import '../core/errors/product_exception.dart';
import '../models/crear_producto_input.dart';
import '../models/producto.dart';
import '../services/product_service.dart';
import 'product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductService productService;

  ProductRepositoryImpl(this.productService);

  @override
  Future<Producto> crearProducto(CrearProductoInput input) async {
    try {
      final productoModel = await productService.crearProducto(input);

      return productoModel.toEntity();
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException(
        'No pudimos crear el producto. Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    try {
      return await productService.obtenerCategorias();
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException('No pudimos cargar las categorías.');
    }
  }
}
