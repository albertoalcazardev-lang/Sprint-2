import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConectividadService {
  Future<bool> hayConexion();
}

class ConectividadServiceImpl implements ConectividadService {
  final Connectivity connectivity;

  ConectividadServiceImpl(this.connectivity);

  @override
  Future<bool> hayConexion() async {
    final resultados = await connectivity.checkConnectivity();

    return resultados.any((resultado) => resultado != ConnectivityResult.none);
  }
}
