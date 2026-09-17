import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/di/dependency_injection.dart';
import '../viewmodels/carrito_viewmodel.dart';
import '../widgets/carrito_vacio.dart';
import '../widgets/resumen_carrito.dart';
import '../widgets/tarjeta_item_carrito.dart';

/// US10/E1-E4 — P11/P12: carrito personal y estado vacío.
class CarritoView extends StatefulWidget {
  final VoidCallback onExplorarCatalogo;
  final VoidCallback onIrACuenta;
  final VoidCallback onAccesoNoAutorizado;
  final CarritoViewModel? viewModel;

  const CarritoView({
    super.key,
    required this.onExplorarCatalogo,
    required this.onIrACuenta,
    required this.onAccesoNoAutorizado,
    this.viewModel,
  });

  @override
  State<CarritoView> createState() => _CarritoViewState();
}

class _CarritoViewState extends State<CarritoView> {
  late final CarritoViewModel _viewModel;
  late final bool _esPropietariaDelViewModel;
  bool _redireccionProgramada = false;

  @override
  void initState() {
    super.initState();
    _esPropietariaDelViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<CarritoViewModel>();
    _viewModel.addListener(_manejarCambio);
    _viewModel.inicializar();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_manejarCambio);

    if (_esPropietariaDelViewModel) {
      _viewModel.dispose();
    }

    super.dispose();
  }

  void _manejarCambio() {
    if (!mounted) {
      return;
    }

    if (_viewModel.accesoNoAutorizado && !_redireccionProgramada) {
      _redireccionProgramada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onAccesoNoAutorizado();
        }
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _construirEncabezado(),
                Expanded(child: _construirContenido()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _construirNavegacionInferior(),
    );
  }

  Widget _construirEncabezado() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al catálogo',
            onPressed: widget.onExplorarCatalogo,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textoPrincipal,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Mi carrito',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textoPrincipal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CLIENTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirContenido() {
    if (_viewModel.estaCargando || _viewModel.carrito == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primario),
      );
    }

    if (_viewModel.accesoNoAutorizado) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Revisa tus artículos antes de continuar.',
            style: TextStyle(fontSize: 14, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 16),
          if (_viewModel.mensajeError != null) ...[
            _AvisoCarrito(
              mensaje: _viewModel.mensajeError!,
              esError: true,
              onCerrar: _viewModel.limpiarAvisos,
            ),
            const SizedBox(height: 14),
          ],
          if (_viewModel.mensajeInformativo != null) ...[
            _AvisoCarrito(
              mensaje: _viewModel.mensajeInformativo!,
              esError: false,
              onCerrar: _viewModel.limpiarAvisos,
            ),
            const SizedBox(height: 14),
          ],
          if (_viewModel.estaVacio)
            CarritoVacio(onExplorarCatalogo: widget.onExplorarCatalogo)
          else ...[
            for (final item in _viewModel.items) ...[
              TarjetaItemCarrito(
                key: ValueKey('item-${item.producto.id}'),
                item: item,
                procesando: _viewModel.estaProcesando(item.producto.id),
                onIncrementar: () {
                  _viewModel.incrementar(item.producto.id);
                },
                onDisminuir: () {
                  _viewModel.disminuir(item.producto.id);
                },
                onEliminar: () {
                  _viewModel.eliminar(item.producto.id);
                },
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            ResumenCarrito(
              totalUnidades: _viewModel.totalUnidades,
              total: _viewModel.total,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              key: const ValueKey('proceder-pago'),
              onPressed: _viewModel.puedeProcederAlPago
                  ? _viewModel.mostrarAvisoPago
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primario,
                foregroundColor: AppColors.blanco,
                disabledBackgroundColor: AppColors.primarioDeshabilitado,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceder al pago',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirNavegacionInferior() {
    return NavigationBar(
      selectedIndex: 1,
      backgroundColor: AppColors.blanco,
      indicatorColor: const Color(0xFFDCEBFF),
      onDestinationSelected: (index) {
        if (index == 0) {
          widget.onExplorarCatalogo();
        } else if (index == 2) {
          widget.onIrACuenta();
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Catálogo',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart_rounded),
          label: 'Carrito',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Mi cuenta',
        ),
      ],
    );
  }
}

class _AvisoCarrito extends StatelessWidget {
  final String mensaje;
  final bool esError;
  final VoidCallback onCerrar;

  const _AvisoCarrito({
    required this.mensaje,
    required this.esError,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final color = esError ? AppColors.error : AppColors.exito;

    return Semantics(
      container: true,
      liveRegion: true,
      label: mensaje,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: esError ? AppColors.fondoError : AppColors.fondoExito,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              esError ? Icons.error_outline_rounded : Icons.info_outline,
              color: color,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar aviso',
              onPressed: onCerrar,
              icon: Icon(Icons.close_rounded, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
