import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/constants/api_constants.dart';
import 'package:tienda_flutter/core/network/api_client.dart';
import 'package:tienda_flutter/models/actualizar_carrito_input.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/services/carrito_service_impl.dart';
import 'package:tienda_flutter/services/gestion_carrito_service.dart';

void main() {
  late ApiClient apiClient;
  late InterceptorGestionCarrito interceptor;
  late GestionCarritoService service;

  const producto = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 10.50,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila resistente.',
  );

  setUp(() {
    apiClient = ApiClient();
    interceptor = InterceptorGestionCarrito();
    apiClient.dio.interceptors.add(interceptor);
    service = CarritoServiceImpl(apiClient);
  });

  tearDown(() {
    apiClient.dio.close(force: true);
  });

  test('PUT usa /carts/{id} y envía el carrito completo', () async {
    interceptor.respuesta = {
      'id': 21,
      'userId': 4,
      'date': '2026-09-17',
      'products': [
        {'productId': 1, 'quantity': 3},
      ],
    };

    await service.actualizarCarrito(
      ActualizarCarritoInput(
        idCarrito: 21,
        idUsuario: 4,
        fecha: DateTime(2026, 9, 17),
        items: const [ItemCarrito(producto: producto, cantidad: 3)],
      ),
    );

    expect(interceptor.solicitud!.method, 'PUT');
    expect(interceptor.solicitud!.path, ApiConstants.cartById(21));

    final cuerpo = Map<String, dynamic>.from(
      interceptor.solicitud!.data as Map,
    );
    final productos = cuerpo['products'] as List<dynamic>;

    expect(cuerpo['userId'], 4);
    expect(cuerpo['date'], '2026-09-17');
    expect(productos, hasLength(1));
    expect(productos.single, {'productId': 1, 'quantity': 3});
  });

  test('DELETE usa /carts/{id} sin enviar un cuerpo', () async {
    interceptor.respuesta = {
      'id': 21,
      'userId': 4,
      'date': '2026-09-17',
      'products': [
        {'productId': 1, 'quantity': 1},
      ],
    };

    await service.eliminarCarrito(21);

    expect(interceptor.solicitud!.method, 'DELETE');
    expect(interceptor.solicitud!.path, ApiConstants.cartById(21));
    expect(interceptor.solicitud!.data, isNull);
  });

  test('DELETE acepta una respuesta vacía para un carrito simulado', () async {
    interceptor.respuesta = null;

    await service.eliminarCarrito(21);

    expect(interceptor.solicitud!.method, 'DELETE');
    expect(interceptor.solicitud!.path, ApiConstants.cartById(21));
  });

  test('DELETE rechaza una respuesta con otro identificador', () async {
    interceptor.respuesta = {'id': 99};

    await expectLater(service.eliminarCarrito(21), throwsA(isA<Exception>()));
  });
}

class InterceptorGestionCarrito extends Interceptor {
  RequestOptions? solicitud;
  Object? respuesta;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    solicitud = options;
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: respuesta,
      ),
    );
  }
}
