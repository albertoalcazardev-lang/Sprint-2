import 'package:dio/dio.dart';

import '../core/errors/usuario_exception.dart';
import '../core/network/api_client.dart';
import '../models/usuario.dart';
import 'usuario_service.dart';

class UsuarioServiceImpl implements UsuarioService {
  final ApiClient apiClient;

  UsuarioServiceImpl(this.apiClient);

  @override
  Future<List<Usuario>> obtenerUsuarios() async {
    try {
      final response = await apiClient.dio.get('users');

      final datos = response.data as List<dynamic>;

      return datos
          .map(
            (usuario) => Usuario.fromJson(
              Map<String, dynamic>.from(usuario),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _convertirError(error);
    }
  }

  UsuarioException _convertirError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const UsuarioException(
        'Sin conexión. Revisa tu acceso a internet.',
      );
    }

    return const UsuarioException(
      'No fue posible obtener la lista de usuarios.',
    );
  }
}