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

  const input = ActualizarProductoInput(
    id: 7,
    titulo: 'Mochila urbana actualizada',
    precio: 99.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila actualizada con compartimento para portátil.',
  );

  setUp(() {
    productService = FakeProductService();
    productRepository = ProductRepositoryImpl(productService);
  });

  test('delega una sola actualización y conserva el input', () async {
    await productRepository.actualizarProducto(input);

    expect(productService.llamadasActualizarProducto, 1);
    expect(productService.ultimoInputActualizacion, same(input));
  });

  test('convierte ProductoModel en Producto', () async {
    productService.alActualizarProducto = (_) async {
      return const ProductoModel(
        id: 7,
        titulo: 'Mochila urbana actualizada',
        precio: 99.95,
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila.jpg',
        descripcion: 'Mochila actualizada con compartimento para portátil.',
      );
    };

    final producto = await productRepository.actualizarProducto(input);

    expect(producto.id, 7);
    expect(producto.titulo, 'Mochila urbana actualizada');
    expect(producto.precio, 99.95);
    expect(producto.categoria, "men's clothing");
    expect(producto.imageUrl, 'https://ejemplo.com/mochila.jpg');
    expect(
      producto.descripcion,
      'Mochila actualizada con compartimento para portátil.',
    );
  });

  test('conserva un error técnico controlado', () async {
    productService.alActualizarProducto = (_) {
      return Future<ProductoModel>.error(const SinConexionProductoException());
    };

    expect(
      productRepository.actualizarProducto(input),
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
    productService.alActualizarProducto = (_) {
      return Future<ProductoModel>.error(
        StateError('Error técnico inesperado'),
      );
    };

    expect(
      productRepository.actualizarProducto(input),
      throwsA(
        isA<ProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No pudimos actualizar el producto. '
              'Inténtalo nuevamente.',
        ),
      ),
    );
  });
}

class FakeProductService implements ProductService {
  int llamadasCrearProducto = 0;
  int llamadasActualizarProducto = 0;
  int llamadasObtenerCategorias = 0;

  ActualizarProductoInput? ultimoInputActualizacion;

  Future<ProductoModel> Function(ActualizarProductoInput input)?
  alActualizarProducto;

  @override
  Future<ProductoModel> crearProducto(CrearProductoInput input) {
    llamadasCrearProducto++;

    throw UnimplementedError('Las pruebas del Repository no crean productos.');
  }

  @override
  Future<ProductoModel> actualizarProducto(ActualizarProductoInput input) {
    llamadasActualizarProducto++;
    ultimoInputActualizacion = input;

    final callback = alActualizarProducto;

    if (callback != null) {
      return callback(input);
    }

    return Future.value(
      ProductoModel(
        id: input.id,
        titulo: input.titulo,
        precio: input.precio,
        categoria: input.categoria,
        imageUrl: input.imageUrl,
        descripcion: input.descripcion,
      ),
    );
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    llamadasObtenerCategorias++;

    return const [
      'electronics',
      'jewelery',
      "men's clothing",
      "women's clothing",
    ];
  }
}
