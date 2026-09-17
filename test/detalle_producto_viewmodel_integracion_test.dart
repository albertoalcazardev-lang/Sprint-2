import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/repositories/product_query_repository.dart';
import 'package:tienda_flutter/viewmodels/detalle_producto_viewmodel.dart';

void main() {
  late _FakeProductQueryRepository repository;
  late DetalleProductoViewModel viewModel;

  setUp(() {
    repository = _FakeProductQueryRepository();
    viewModel = DetalleProductoViewModel(repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('usa el producto seleccionado sin repetir el GET', () async {
    await viewModel.inicializar(productoId: 3, productoInicial: _original);

    expect(repository.consultasPorId, 0);
    expect(viewModel.producto, same(_original));
  });

  test('una ruta directa consulta el producto una sola vez', () async {
    await viewModel.inicializar(productoId: 3);

    expect(repository.consultasPorId, 1);
    expect(repository.ultimoId, 3);
    expect(viewModel.producto?.id, 3);
  });

  test('aplica el resultado del PUT sin ejecutar un GET posterior', () async {
    await viewModel.inicializar(productoId: 3, productoInicial: _original);

    const actualizado = Producto(
      id: 3,
      titulo: 'Título actualizado',
      precio: 75,
      categoria: 'electronics',
      imageUrl: 'https://example.com/original.png',
      descripcion: 'Descripción actualizada',
    );

    viewModel.aplicarProductoActualizado(actualizado);

    expect(repository.consultasPorId, 0);
    expect(viewModel.producto, same(actualizado));
  });
}

const _original = Producto(
  id: 3,
  titulo: 'Producto original',
  precio: 50,
  categoria: 'electronics',
  imageUrl: 'https://example.com/original.png',
  descripcion: 'Descripción original',
);

class _FakeProductQueryRepository implements ProductQueryRepository {
  int consultasPorId = 0;
  int? ultimoId;

  @override
  Future<Producto> obtenerProductoPorId(int productoId) async {
    consultasPorId++;
    ultimoId = productoId;
    return _original;
  }

  @override
  Future<List<String>> obtenerCategorias() async => const ['electronics'];

  @override
  Future<List<Producto>> obtenerProductos() async => const [_original];

  @override
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    return const [_original];
  }
}
