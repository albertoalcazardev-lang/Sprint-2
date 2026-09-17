import '../models/usuario.dart';

abstract class UsuarioService {
  Future<List<Usuario>> obtenerUsuarios();
}