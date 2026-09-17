import '../core/errors/product_exception.dart';
import '../models/actualizar_producto_input.dart';
import '../models/crear_producto_input.dart';
import '../models/producto.dart';
import '../services/product_service.dart';
import '../services/product_query_service.dart';
import 'product_repository.dart';
import 'product_query_repository.dart';

class ProductRepositoryImpl
    implements ProductRepository, ProductQueryRepository {
  final ProductService productService;
  final Map<int, Producto> _productosActualizadosLocalmente = {};

  ProductRepositoryImpl(this.productService);

  @override
  Future<List<Producto>> obtenerProductos() async {
    try {
      final productos = await _queryService.obtenerProductos();
      return productos
          .map((producto) => _combinarConActualizacion(producto.toEntity()))
          .toList();
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException('No pudimos cargar el catálogo.');
    }
  }

  @override
  Future<Producto> obtenerProductoPorId(int productoId) async {
    try {
      final productoLocal = _productosActualizadosLocalmente[productoId];

      if (productoLocal != null) {
        return productoLocal;
      }

      return (await _queryService.obtenerProductoPorId(productoId)).toEntity();
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException('No se encontró el producto.');
    }
  }

  @override
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    try {
      final productos = await _queryService.obtenerProductosPorCategoria(
        categoria,
      );
      final resultado = productos
          .map((producto) => _combinarConActualizacion(producto.toEntity()))
          .where((producto) => producto.categoria == categoria)
          .toList();
      final idsIncluidos = resultado.map((producto) => producto.id).toSet();

      resultado.addAll(
        _productosActualizadosLocalmente.values.where(
          (producto) =>
              producto.categoria == categoria &&
              !idsIncluidos.contains(producto.id),
        ),
      );

      return resultado;
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException(
        'No pudimos cargar los productos de esta categoría.',
      );
    }
  }

  ProductQueryService get _queryService {
    final service = productService;

    if (service is! ProductQueryService) {
      throw const ProductoException(
        'El servicio no admite consultas de productos.',
      );
    }

    return service as ProductQueryService;
  }

  Producto _combinarConActualizacion(Producto productoRemoto) {
    return _productosActualizadosLocalmente[productoRemoto.id] ??
        productoRemoto;
  }

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

  /// US07/E1 — Delega el PUT y devuelve la entidad actualizada.
  @override
  Future<Producto> actualizarProducto(ActualizarProductoInput input) async {
    try {
      final productoModel = await productService.actualizarProducto(input);
      final productoActualizado = productoModel.toEntity();

      _productosActualizadosLocalmente[productoActualizado.id] =
          productoActualizado;

      return productoActualizado;
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException(
        'No pudimos actualizar el producto. '
        'Inténtalo nuevamente.',
      );
    }
  }

  /// US08/E1 — Delega el DELETE y devuelve el producto confirmado.
  @override
  Future<Producto> eliminarProducto(int productoId) async {
    try {
      final productoModel = await productService.eliminarProducto(productoId);

      return productoModel.toEntity();
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const ProductoException(
        'No pudimos eliminar el producto. '
        'Inténtalo nuevamente.',
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
