import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/constants/api_constants.dart';
import 'package:tienda_flutter/core/errors/product_exception.dart';
import 'package:tienda_flutter/core/network/api_client.dart';
import 'package:tienda_flutter/services/product_service.dart';
import 'package:tienda_flutter/services/product_service_impl.dart';

void main() {
  late ApiClient apiClient;
  late InterceptorEliminarProducto interceptor;
  late ProductService productService;

  setUp(() {
    apiClient = ApiClient();
    interceptor = InterceptorEliminarProducto();

    apiClient.dio.interceptors.add(interceptor);

    productService = ProductServiceImpl(apiClient);
  });

  tearDown(() {
    apiClient.dio.close(force: true);
  });

  test('utiliza DELETE products/{id} sin enviar cuerpo', () async {
    interceptor.datosRespuesta = _respuestaValida();

    await productService.eliminarProducto(7);

    final solicitud = interceptor.ultimaSolicitud;

    expect(solicitud, isNotNull);
    expect(solicitud!.method, 'DELETE');
    expect(solicitud.path, ApiConstants.productById(7));
    expect(solicitud.data, isNull);
  });

  test('convierte la respuesta en ProductoModel', () async {
    interceptor.datosRespuesta = _respuestaValida();

    final producto = await productService.eliminarProducto(7);

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

  test('rechaza un ID igual a cero sin ejecutar DELETE', () async {
    expect(
      productService.eliminarProducto(0),
      throwsA(
        isA<ProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No se encontró el producto que intentas eliminar.',
        ),
      ),
    );

    expect(interceptor.ultimaSolicitud, isNull);
  });

  test('rechaza un ID negativo sin ejecutar DELETE', () async {
    expect(
      productService.eliminarProducto(-1),
      throwsA(isA<ProductoException>()),
    );

    expect(interceptor.ultimaSolicitud, isNull);
  });

  test('rechaza una respuesta vacía', () async {
    interceptor.datosRespuesta = null;

    expect(
      productService.eliminarProducto(7),
      throwsA(isA<RespuestaProductoInvalidaException>()),
    );
  });

  test('rechaza una respuesta que no es un objeto JSON', () async {
    interceptor.datosRespuesta = const ['respuesta', 'inválida'];

    expect(
      productService.eliminarProducto(7),
      throwsA(isA<RespuestaProductoInvalidaException>()),
    );
  });

  test('rechaza una respuesta con un ID diferente', () async {
    interceptor.datosRespuesta = {..._respuestaValida(), 'id': 99};

    expect(
      productService.eliminarProducto(7),
      throwsA(
        isA<RespuestaProductoInvalidaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('no corresponde'),
        ),
      ),
    );
  });

  test('convierte HTTP 404 en producto no encontrado', () async {
    interceptor.codigoEstado = 404;
    interceptor.datosRespuesta = {'message': 'Product not found'};

    expect(
      productService.eliminarProducto(7),
      throwsA(
        isA<ProductoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No se encontró el producto que intentas eliminar.',
        ),
      ),
    );
  });
}

Map<String, dynamic> _respuestaValida() {
  return {
    'id': 7,
    'title': 'Mochila urbana',
    'price': 109.95,
    'category': "men's clothing",
    'image': 'https://ejemplo.com/mochila.jpg',
    'description': 'Mochila urbana con compartimento para portátil.',
  };
}

class InterceptorEliminarProducto extends Interceptor {
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
