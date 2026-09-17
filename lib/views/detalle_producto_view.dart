import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../models/producto.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/agregar_carrito_viewmodel.dart';
import '../viewmodels/detalle_producto_viewmodel.dart';
import '../viewmodels/eliminar_producto_viewmodel.dart';
import '../widgets/aviso_producto_actualizado.dart';
import '../widgets/controles_agregar_carrito.dart';
import '../widgets/dialogo_eliminar_producto.dart';

/// US05 con integración de US07, US08 y US09.
class DetalleProductoView extends StatefulWidget {
  final DetalleProductoViewModel viewModel;
  final AgregarCarritoViewModel agregarCarritoViewModel;
  final EliminarProductoViewModel eliminarProductoViewModel;
  final AuthRepository authRepository;
  final int productoId;
  final Producto? productoInicial;

  const DetalleProductoView({
    super.key,
    required this.viewModel,
    required this.agregarCarritoViewModel,
    required this.eliminarProductoViewModel,
    required this.authRepository,
    required this.productoId,
    this.productoInicial,
  });

  @override
  State<DetalleProductoView> createState() => _DetalleProductoViewState();
}

class _DetalleProductoViewState extends State<DetalleProductoView> {
  RolUsuario? _rol;
  int? _productoInicializadoEnCarrito;
  bool _mostrarAvisoActualizado = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_actualizarPantalla);
    _cargarRol();
    widget.viewModel.inicializar(
      productoId: widget.productoId,
      productoInicial: widget.productoInicial,
    );
    _inicializarCarritoSiCorresponde();
  }

  @override
  void didUpdateWidget(covariant DetalleProductoView oldWidget) {
    super.didUpdateWidget(oldWidget);

    var reinicializarCarrito = false;

    if (!identical(oldWidget.viewModel, widget.viewModel)) {
      final productoActual =
          oldWidget.viewModel.producto ??
          oldWidget.productoInicial ??
          widget.productoInicial;

      oldWidget.viewModel.removeListener(_actualizarPantalla);
      oldWidget.viewModel.dispose();

      widget.viewModel.addListener(_actualizarPantalla);
      widget.viewModel.inicializar(
        productoId: widget.productoId,
        productoInicial: productoActual,
      );
      reinicializarCarrito = true;
    }

    if (!identical(
      oldWidget.agregarCarritoViewModel,
      widget.agregarCarritoViewModel,
    )) {
      oldWidget.agregarCarritoViewModel.dispose();
      reinicializarCarrito = true;
    }

    if (!identical(
      oldWidget.eliminarProductoViewModel,
      widget.eliminarProductoViewModel,
    )) {
      oldWidget.eliminarProductoViewModel.dispose();
    }

    if (!identical(oldWidget.authRepository, widget.authRepository)) {
      _cargarRol();
    }

    if (reinicializarCarrito) {
      _productoInicializadoEnCarrito = null;
      _inicializarCarritoSiCorresponde();
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_actualizarPantalla);
    widget.viewModel.dispose();
    widget.agregarCarritoViewModel.dispose();
    widget.eliminarProductoViewModel.dispose();
    super.dispose();
  }

  Future<void> _cargarRol() async {
    final sesion = await widget.authRepository.obtenerSesion();

    if (!mounted) return;

    setState(() {
      _rol = sesion?.rol;
    });
  }

  void _actualizarPantalla() {
    if (!mounted) return;

    _inicializarCarritoSiCorresponde();
    setState(() {});
  }

  void _inicializarCarritoSiCorresponde() {
    final producto = widget.viewModel.producto;

    if (producto == null || _productoInicializadoEnCarrito == producto.id) {
      return;
    }

    _productoInicializadoEnCarrito = producto.id;
    widget.agregarCarritoViewModel.inicializar(producto);
  }

  Future<void> _editarProducto(Producto producto) async {
    final actualizado = await context.push<Producto>(
      '/products/${producto.id}/edit',
      extra: producto,
    );

    if (!mounted || actualizado == null) return;

    widget.viewModel.aplicarProductoActualizado(actualizado);
    setState(() {
      _mostrarAvisoActualizado = true;
    });
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final eliminado = await mostrarDialogoEliminarProducto(
      context: context,
      producto: producto,
      viewModel: widget.eliminarProductoViewModel,
    );

    if (!mounted) return;

    if (widget.eliminarProductoViewModel.accesoNoAutorizado) {
      context.go('/inicio?accesoDenegado=true');
      return;
    }

    if (eliminado) {
      context.go('/administrador?productoEliminado=true');
    }
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/inicio');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _construirContenido(viewModel),
          ),
        ),
      ),
    );
  }

  Widget _construirContenido(DetalleProductoViewModel viewModel) {
    if (viewModel.estaCargando && viewModel.producto == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primario),
      );
    }

    final producto = viewModel.producto;

    if (producto == null) {
      return _EstadoErrorDetalle(
        mensaje: viewModel.mensajeError ?? 'Producto no disponible.',
        onVolver: _volver,
        onReintentar: () => viewModel.cargarProducto(widget.productoId),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _volver,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              label: const Text('Volver al catálogo'),
            ),
          ),
          if (_mostrarAvisoActualizado) ...[
            const AvisoProductoActualizado(),
            const SizedBox(height: 16),
          ],
          Container(
            height: 240,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.network(
              producto.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: AppColors.textoSecundario,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            producto.categoria,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.titulo,
            style: const TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${producto.precio.toStringAsFixed(2)} USD',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.descripcion,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 24),
          if (_rol == RolUsuario.administrador)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _editarProducto(producto),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar producto'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primario,
                      foregroundColor: AppColors.blanco,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _eliminarProducto(producto),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            )
          else
            ControlesAgregarCarrito(viewModel: widget.agregarCarritoViewModel),
        ],
      ),
    );
  }
}

class _EstadoErrorDetalle extends StatelessWidget {
  final String mensaje;
  final VoidCallback onVolver;
  final VoidCallback onReintentar;

  const _EstadoErrorDetalle({
    required this.mensaje,
    required this.onVolver,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 62,
              color: AppColors.textoSecundario,
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
            TextButton(onPressed: onVolver, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
