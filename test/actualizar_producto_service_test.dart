import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/constants/api_constants.dart';
import 'package:tienda_flutter/core/errors/product_exception.dart';
import 'package:tienda_flutter/core/network/api_client.dart';
import 'package:tienda_flutter/models/actualizar_producto_input.dart';
import 'package:tienda_flutter/services/product_service.dart';
import 'package:tienda_flutter/services/product_service_impl.dart';

void main() {
  late ApiClient apiClient;
  late InterceptorProductoPrueba interceptor;
  late ProductService productService;

  const input = ActualizarProductoInput(
    id: 7,
    titulo: '  Mochila urbana  ',
    precio: 99.95,
    categoria: "  men's clothing  ",
    imageUrl: '  https://ejemplo.com/mochila.jpg  ',
    descripcion: '  Mochila actualizada con compartimento para portátil.  ',
  );

  setUp(() {
    apiClient = ApiClient();
    interceptor = InterceptorProductoPrueba();

    apiClient.dio.interceptors.add(interceptor);

    productService = ProductServiceImpl(apiClient);
  });

  tearDown(() {
    apiClient.dio.close(force: true);
  });

  test('utiliza PUT products/{id} con el cuerpo correcto', () async {
    interceptor.datosRespuesta = {
      'id': 7,
      'title': 'Mochila urbana',
      'price': 99.95,
      'category': "men's clothing",
      'image': 'https://ejemplo.com/mochila.jpg',
      'description': 'Mochila actualizada con compartimento para portátil.',
    };

    await productService.actualizarProducto(input);

    final solicitud = interceptor.ultimaSolicitud;
    final cuerpo = solicitud?.data as Map<String, dynamic>;

    expect(solicitud, isNotNull);
    expect(solicitud!.method, 'PUT');
    expect(solicitud.path, ApiConstants.productById(input.id));

    expect(cuerpo['title'], 'Mochila urbana');
    expect(cuerpo['price'], 99.95);
    expect(cuerpo['price'], isA<double>());
    expect(cuerpo['category'], "men's clothing");
    expect(cuerpo['image'], 'https://ejemplo.com/mochila.jpg');
    expect(
      cuerpo['description'],
      'Mochila actualizada con compartimento para portátil.',
    );
  });

  test('convierte la respuesta en ProductoModel', () async {
    interceptor.datosRespuesta = {
      'id': 7,
      'title': 'Mochila urbana',
      'price': 99.95,
      'category': "men's clothing",
      'image': 'https://ejemplo.com/mochila.jpg',
      'description': 'Mochila actualizada con compartimento para portátil.',
    };

    final producto = await productService.actualizarProducto(input);

    expect(producto.id, 7);
    expect(producto.titulo, 'Mochila urbana');
    expect(producto.precio, 99.95);
    expect(producto.categoria, "men's clothing");
    expect(producto.imageUrl, 'https://ejemplo.com/mochila.jpg');
    expect(
      producto.descripcion,
      'Mochila actualizada con compartimento para portátil.',
    );
  });

  test(
    'conserva la imagen original si la respuesta no contiene image',
    () async {
      interceptor.datosRespuesta = {
        'id': 7,
        'title': 'Mochila urbana',
        'price': 99.95,
        'category': "men's clothing",
        'description': 'Mochila actualizada con compartimento para portátil.',
      };

      final producto = await productService.actualizarProducto(input);

      expect(producto.imageUrl, 'https://ejemplo.com/mochila.jpg');
    },
  );

  test('conserva la imagen original si image llega vacío', () async {
    interceptor.datosRespuesta = {
      'id': 7,
      'title': 'Mochila urbana',
      'price': 99.95,
      'category': "men's clothing",
      'image': '   ',
      'description': 'Mochila actualizada con compartimento para portátil.',
    };

    final producto = await productService.actualizarProducto(input);

    expect(producto.imageUrl, 'https://ejemplo.com/mochila.jpg');
  });

  test('rechaza una respuesta con un ID diferente', () async {
    interceptor.datosRespuesta = {
      'id': 99,
      'title': 'Mochila urbana',
      'price': 99.95,
      'category': "men's clothing",
      'image': 'https://ejemplo.com/mochila.jpg',
      'description': 'Mochila actualizada con compartimento para portátil.',
    };

    expect(
      productService.actualizarProducto(input),
      throwsA(
        isA<RespuestaProductoInvalidaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('no corresponde'),
        ),
      ),
    );
  });

  test('rechaza una respuesta que no es un objeto JSON', () async {
    interceptor.datosRespuesta = const ['respuesta', 'inválida'];

    expect(
      productService.actualizarProducto(input),
      throwsA(isA<RespuestaProductoInvalidaException>()),
    );
  });

  test('convierte HTTP 404 en producto no encontrado', () async {
    interceptor.codigoEstado = 404;
    interceptor.datosRespuesta = {'message': 'Product not found'};

    expect(
      productService.actualizarProducto(input),
      throwsA(
        isA<ProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No se encontró el producto que intentas editar.',
        ),
      ),
    );
  });
}

class InterceptorProductoPrueba extends Interceptor {
  RequestOptions? ultimaSolicitud;
  Object? datosRespuesta;
  int codigoEstado = 200;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    ultimaSolicitud = options;

    final respuesta = Response<dynamic>(
      requestOptions: options,
      data: datosRespuesta,
      statusCode: codigoEstado,
    );

    if (codigoEstado >= 400) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: respuesta,
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.resolve(respuesta);
  }
}
