import 'package:dio/dio.dart';

import '../core/errors/auth_exception.dart';
import '../core/network/api_client.dart';
import '../models/respuesta_login.dart';
import '../models/solicitud_login.dart';
import '../models/usuario_autenticacion.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  final ApiClient apiClient;

  AuthServiceImpl(this.apiClient);

  @override
  Future<RespuestaLogin> iniciarSesion(SolicitudLogin solicitud) async {
    try {
      final response = await apiClient.dio.post(
        'auth/login',
        data: solicitud.toJson(),
      );

      return RespuestaLogin.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw _convertirError(error);
    }
  }

  @override
  Future<List<UsuarioAutenticacion>> obtenerUsuarios() async {
    try {
      final response = await apiClient.dio.get('users');

      final datos = response.data as List<dynamic>;

      return datos
          .map(
            (usuario) => UsuarioAutenticacion.fromJson(
              Map<String, dynamic>.from(usuario),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _convertirError(error);
    }
  }

  Exception _convertirError(DioException error) {
    if (error.response?.statusCode == 401) {
      return const CredencialesInvalidasException();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const SinConexionException();
    }

    return const AutenticacionException(
      'No fue posible completar la autenticación.',
    );
  }
}
