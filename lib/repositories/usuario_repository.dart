import '../models/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> obtenerUsuarios();
}