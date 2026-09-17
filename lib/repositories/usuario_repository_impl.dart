import '../models/usuario.dart';
import '../services/usuario_service.dart';
import 'usuario_repository.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioService usuarioService;

  UsuarioRepositoryImpl(this.usuarioService);

  @override
  Future<List<Usuario>> obtenerUsuarios() {
    return usuarioService.obtenerUsuarios();
  }
}