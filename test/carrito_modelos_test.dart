import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/producto_carrito_respuesta_model.dart';
import 'package:tienda_flutter/models/respuesta_carrito_model.dart';

void main() {
  const mochila = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila con compartimento para portátil.',
  );

  const audifonos = Producto(
    id: 2,
    titulo: 'Audífonos',
    precio: 25.50,
    categoria: 'electronics',
    imageUrl: 'https://ejemplo.com/audifonos.jpg',
    descripcion: 'Audífonos inalámbricos.',
  );

  test('AgregarCarritoInput conserva usuario, producto y cantidad', () {
    final fecha = DateTime(2026, 9, 17);

    final input = AgregarCarritoInput(
      idUsuario: 4,
      producto: mochila,
      cantidad: 3,
      fecha: fecha,
    );

    expect(input.idUsuario, 4);
    expect(input.producto, same(mochila));
    expect(input.cantidad, 3);
    expect(input.fecha, fecha);
  });

  test('ItemCarrito calcula el subtotal', () {
    const item = ItemCarrito(producto: mochila, cantidad: 3);

    expect(item.subtotal, closeTo(329.85, 0.001));
  });

  test('copiarConCantidad crea una instancia actualizada', () {
    const original = ItemCarrito(producto: mochila, cantidad: 2);

    final actualizado = original.copiarConCantidad(5);

    expect(original.cantidad, 2);
    expect(actualizado.cantidad, 5);
    expect(actualizado.producto, same(mochila));
    expect(actualizado, isNot(same(original)));
  });

  test('copiarConCantidad rechaza cero y negativos', () {
    const item = ItemCarrito(producto: mochila, cantidad: 1);

    expect(() => item.copiarConCantidad(0), throwsArgumentError);

    expect(() => item.copiarConCantidad(-2), throwsArgumentError);
  });

  test('CarritoSnapshot calcula unidades, productos y total', () {
    final carrito = CarritoSnapshot(
      idUsuario: 4,
      items: const [
        ItemCarrito(producto: mochila, cantidad: 2),
        ItemCarrito(producto: audifonos, cantidad: 3),
      ],
    );

    expect(carrito.totalUnidades, 5);
    expect(carrito.productosDistintos, 2);

    final totalEsperado = (109.95 * 2) + (25.50 * 3);

    expect(carrito.total, closeTo(totalEsperado, 0.001));
  });

  test('CarritoSnapshot busca productos exclusivamente por ID', () {
    final carrito = CarritoSnapshot(
      idUsuario: 4,
      items: const [ItemCarrito(producto: mochila, cantidad: 2)],
    );

    expect(carrito.buscarProducto(1), isNotNull);
    expect(carrito.buscarProducto(1)!.cantidad, 2);
    expect(carrito.buscarProducto(99), isNull);
  });

  test('CarritoSnapshot protege su lista contra modificaciones', () {
    final carrito = CarritoSnapshot(
      idUsuario: 4,
      items: const [ItemCarrito(producto: mochila, cantidad: 1)],
    );

    expect(
      () => carrito.items.add(
        const ItemCarrito(producto: audifonos, cantidad: 1),
      ),
      throwsUnsupportedError,
    );
  });

  test('CarritoSnapshot.vacio conserva el usuario', () {
    final carrito = CarritoSnapshot.vacio(7);

    expect(carrito.idUsuario, 7);
    expect(carrito.items, isEmpty);
    expect(carrito.totalUnidades, 0);
    expect(carrito.productosDistintos, 0);
    expect(carrito.total, 0);
  });

  test('ProductoCarritoRespuestaModel acepta enteros positivos', () {
    final producto = ProductoCarritoRespuestaModel.fromJson({
      'productId': 1,
      'quantity': 3,
    });

    expect(producto.productoId, 1);
    expect(producto.cantidad, 3);
  });

  test('ProductoCarritoRespuestaModel rechaza cantidad decimal', () {
    expect(
      () => ProductoCarritoRespuestaModel.fromJson({
        'productId': 1,
        'quantity': 2.5,
      }),
      throwsFormatException,
    );
  });

  test('RespuestaCarritoModel convierte una respuesta válida', () {
    final respuesta = RespuestaCarritoModel.fromJson({
      'id': 21,
      'userId': 4,
      'date': '2026-09-17',
      'products': [
        {'productId': 1, 'quantity': 2},
      ],
    });

    expect(respuesta.id, 21);
    expect(respuesta.idUsuario, 4);
    expect(respuesta.fecha, DateTime(2026, 9, 17));
    expect(respuesta.productos, hasLength(1));
    expect(respuesta.productos.single.productoId, 1);
    expect(respuesta.productos.single.cantidad, 2);
  });

  test('RespuestaCarritoModel rechaza una lista vacía', () {
    expect(
      () => RespuestaCarritoModel.fromJson({
        'id': 21,
        'userId': 4,
        'date': '2026-09-17',
        'products': [],
      }),
      throwsFormatException,
    );
  });

  test('RespuestaCarritoModel rechaza un userId inválido', () {
    expect(
      () => RespuestaCarritoModel.fromJson({
        'id': 21,
        'userId': 0,
        'date': '2026-09-17',
        'products': [
          {'productId': 1, 'quantity': 2},
        ],
      }),
      throwsFormatException,
    );
  });

  test('RespuestaCarritoModel rechaza una fecha inválida', () {
    expect(
      () => RespuestaCarritoModel.fromJson({
        'id': 21,
        'userId': 4,
        'date': 'fecha-invalida',
        'products': [
          {'productId': 1, 'quantity': 2},
        ],
      }),
      throwsFormatException,
    );
  });
}
