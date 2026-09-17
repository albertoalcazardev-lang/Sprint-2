import 'package:flutter/foundation.dart';

import '../core/errors/carrito_exception.dart';
import '../models/carrito.dart';
import '../repositories/carrito_repository.dart';

class CarritosViewModel extends ChangeNotifier {
  final CarritoRepository carritoRepository;

  CarritosViewModel(this.carritoRepository);

  final List<Carrito> _carritos = [];
  bool _cargando = false;
  String? _mensajeError;

  List<Carrito> get carritos => List.unmodifiable(_carritos);
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;
  bool get tieneCarritos => _carritos.isNotEmpty;

  int get totalCarritos => _carritos.length;

  int get totalUsuarios => _carritos.map((carrito) => carrito.usuarioId).toSet().length;

  Future<void> cargarCarritos() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final carritosObtenidos = await carritoRepository.obtenerCarritos();

      carritosObtenidos.sort((a, b) => b.fecha.compareTo(a.fecha));

      _carritos
        ..clear()
        ..addAll(carritosObtenidos);
    } on CarritoException catch (error) {
      _mensajeError = error.mensaje;
    } catch (_) {
      _mensajeError = 'Ocurrió un error inesperado al cargar los carritos.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargarCarritos() {
    return cargarCarritos();
  }
}
