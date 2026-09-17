import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/product_exception.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto_model.dart';
import 'package:tienda_flutter/repositories/product_repository.dart';
import 'package:tienda_flutter/repositories/product_repository_impl.dart';
import 'package:tienda_flutter/services/product_service.dart';

void main() {
  late FakeProductService productService;
  late ProductRepository productRepository;

  setUp(() {
    productService = FakeProductService();
    productRepository = ProductRepositoryImpl(productService);
  });

  test('llama una vez al Service con el ID correcto', () async {
    await productRepository.eliminarProducto(7);

    expect(productService.llamadasEliminarProducto, 1);
    expect(productService.ultimoIdEliminado, 7);
  });

  test('convierte ProductoModel en Producto', () async {
    productService.alEliminarProducto = (_) async {
      return const ProductoModel(
        id: 7,
        titulo: 'Mochila urbana',
        precio: 109.95,
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila.jpg',
        descripcion: 'Mochila urbana con compartimento para portátil.',
      );
    };

    final producto = await productRepository.eliminarProducto(7);

    expect(producto.id, 7);
    expect(producto.titulo, 'Mochila urbana');
    expect(producto.precio, 109.95);
    expect(producto.categoria, "men's clothing");
    expect(producto.imageUrl, 'https://ejemplo.com/mochila.jpg');
    expect(
      producto.descripcion,
      'Mochila urbana con compartimento para portátil.',
    );
  });

  test('conserva un error técnico controlado', () async {
    productService.alEliminarProducto = (_) {
      return Future<ProductoModel>.error(const SinConexionProductoException());
    };

    expect(
      productRepository.eliminarProducto(7),
      throwsA(
        isA<SinConexionProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'Sin conexión. Revisa tu acceso a internet.',
        ),
      ),
    );
  });

  test('convierte un error desconocido en error recuperable', () async {
    productService.alEliminarProducto = (_) {
      return Future<ProductoModel>.error(StateError('Error inesperado'));
    };

    expect(
      productRepository.eliminarProducto(7),
      throwsA(
        isA<ProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No pudimos eliminar el producto. '
              'Inténtalo nuevamente.',
        ),
      ),
    );
  });
}

class FakeProductService implements ProductService {
  int llamadasEliminarProducto = 0;
  int? ultimoIdEliminado;

  Future<ProductoModel> Function(int productoId)? alEliminarProducto;

  @override
  Future<ProductoModel> eliminarProducto(int productoId) {
    llamadasEliminarProducto++;
    ultimoIdEliminado = productoId;

    final callback = alEliminarProducto;

    if (callback != null) {
      return callback(productoId);
    }

    return Future.value(
      const ProductoModel(
        id: 7,
        titulo: 'Mochila urbana',
        precio: 109.95,
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila.jpg',
        descripcion: 'Mochila urbana con compartimento para portátil.',
      ),
    );
  }

  @override
  Future<ProductoModel> crearProducto(CrearProductoInput input) {
    throw UnimplementedError('Las pruebas de eliminación no crean productos.');
  }

  @override
  Future<ProductoModel> actualizarProducto(ActualizarProductoInput input) {
    throw UnimplementedError(
      'Las pruebas de eliminación no actualizan productos.',
    );
  }

  @override
  Future<List<String>> obtenerCategorias() {
    throw UnimplementedError(
      'Las pruebas de eliminación no cargan categorías.',
    );
  }
}
