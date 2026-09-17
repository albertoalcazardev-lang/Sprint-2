import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/models/crear_producto_input.dart';
import 'package:tienda_flutter/models/producto_model.dart';
import 'package:tienda_flutter/repositories/product_repository_impl.dart';
import 'package:tienda_flutter/services/product_query_service.dart';
import 'package:tienda_flutter/services/product_service.dart';

void main() {
  late _FakeProductService service;
  late ProductRepositoryImpl repository;

  setUp(() {
    service = _FakeProductService();
    repository = ProductRepositoryImpl(service);
  });

  test('convierte el catálogo consultado a entidades Producto', () async {
    final productos = await repository.obtenerProductos();

    expect(service.consultasCatalogo, 1);
    expect(productos, hasLength(1));
    expect(productos.single.id, 7);
    expect(productos.single.titulo, 'Producto integrado');
  });

  test('consulta un producto por el identificador solicitado', () async {
    final producto = await repository.obtenerProductoPorId(7);

    expect(service.ultimoProductoId, 7);
    expect(producto.precio, 49.90);
  });

  test('conserva la categoría API al consultar el filtro', () async {
    final productos = await repository.obtenerProductosPorCategoria(
      "men's clothing",
    );

    expect(service.ultimaCategoria, "men's clothing");
    expect(productos.single.categoria, "men's clothing");
  });
}

class _FakeProductService implements ProductService, ProductQueryService {
  static const _producto = ProductoModel(
    id: 7,
    titulo: 'Producto integrado',
    precio: 49.90,
    categoria: "men's clothing",
    imageUrl: 'https://example.com/producto.png',
    descripcion: 'Producto usado para comprobar la integración.',
  );

  int consultasCatalogo = 0;
  int? ultimoProductoId;
  String? ultimaCategoria;

  @override
  Future<List<ProductoModel>> obtenerProductos() async {
    consultasCatalogo++;
    return const [_producto];
  }

  @override
  Future<ProductoModel> obtenerProductoPorId(int productoId) async {
    ultimoProductoId = productoId;
    return _producto;
  }

  @override
  Future<List<ProductoModel>> obtenerProductosPorCategoria(
    String categoria,
  ) async {
    ultimaCategoria = categoria;
    return const [_producto];
  }

  @override
  Future<List<String>> obtenerCategorias() async => const ["men's clothing"];

  @override
  Future<ProductoModel> crearProducto(CrearProductoInput input) {
    throw UnimplementedError();
  }

  @override
  Future<ProductoModel> actualizarProducto(ActualizarProductoInput input) {
    throw UnimplementedError();
  }

  @override
  Future<ProductoModel> eliminarProducto(int productoId) {
    throw UnimplementedError();
  }
}
