import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/producto.dart';
import '../viewmodels/eliminar_producto_viewmodel.dart';

/// US08/E1-E2 — Abre P22 y devuelve true solamente después del DELETE.
Future<bool> mostrarDialogoEliminarProducto({
  required BuildContext context,
  required Producto producto,
  required EliminarProductoViewModel viewModel,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.textoPrincipal.withValues(alpha: 0.40),
    builder: (dialogContext) {
      return DialogoEliminarProducto(producto: producto, viewModel: viewModel);
    },
  );

  return resultado ?? false;
}

class DialogoEliminarProducto extends StatefulWidget {
  final Producto producto;
  final EliminarProductoViewModel viewModel;

  const DialogoEliminarProducto({
    super.key,
    required this.producto,
    required this.viewModel,
  });

  @override
  State<DialogoEliminarProducto> createState() =>
      _DialogoEliminarProductoState();
}

class _DialogoEliminarProductoState extends State<DialogoEliminarProducto> {
  Future<void> _confirmarEliminacion() async {
    if (widget.viewModel.eliminando) {
      return;
    }

    final eliminado = await widget.viewModel.eliminarProducto(widget.producto);

    if (!mounted) {
      return;
    }

    if (widget.viewModel.accesoNoAutorizado) {
      Navigator.of(context).pop(false);
      return;
    }

    if (!eliminado) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _cancelar() {
    if (widget.viewModel.eliminando) {
      return;
    }

    widget.viewModel.limpiarError();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, child) {
        final eliminando = widget.viewModel.eliminando;

        return PopScope(
          canPop: !eliminando,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330D173B),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _construirIcono(),
                      const SizedBox(height: 18),
                      const Text(
                        '¿Eliminar este producto?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: 'Producto ${widget.producto.titulo}',
                        child: Text(
                          widget.producto.titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Producto #${widget.producto.id}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondoGeneral,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Text(
                          'Operación simulada. Fake Store API '
                          'no elimina el producto permanentemente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                      if (widget.viewModel.mensajeError != null) ...[
                        const SizedBox(height: 14),
                        _construirAvisoError(widget.viewModel.mensajeError!),
                      ],
                      const SizedBox(height: 22),
                      _construirBotones(eliminando),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirIcono() {
    return Semantics(
      label: 'Advertencia de eliminación',
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.fondoError,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 27,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _construirAvisoError(String mensaje) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: mensaje,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fondoError,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotones(bool eliminando) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usarColumna = constraints.maxWidth < 300;

        final cancelar = _construirBotonCancelar(eliminando);
        final eliminar = _construirBotonEliminar(eliminando);

        if (usarColumna) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [eliminar, const SizedBox(height: 12), cancelar],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelar),
            const SizedBox(width: 12),
            Expanded(child: eliminar),
          ],
        );
      },
    );
  }

  Widget _construirBotonCancelar(bool eliminando) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: eliminando ? null : _cancelar,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textoPrincipal,
          backgroundColor: AppColors.superficie,
          disabledForegroundColor: AppColors.textoSugerencia,
          side: const BorderSide(color: AppColors.bordeCampo),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Text(
          'Cancelar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _construirBotonEliminar(bool eliminando) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: eliminando ? null : _confirmarEliminacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.blanco,
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.55),
          disabledForegroundColor: AppColors.blanco,
          elevation: 2,
          shadowColor: AppColors.error.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: eliminando
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.blanco,
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Eliminando...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : const Text(
                'Eliminar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
