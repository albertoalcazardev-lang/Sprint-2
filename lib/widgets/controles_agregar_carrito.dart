import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/rol_usuario.dart';
import '../viewmodels/agregar_carrito_viewmodel.dart';
import 'aviso_producto_agregado.dart';
import 'selector_cantidad.dart';

/// US09/E1-E3 — Controles que se insertarán en el detalle existente de US05.
class ControlesAgregarCarrito extends StatelessWidget {
  final AgregarCarritoViewModel viewModel;

  const ControlesAgregarCarrito({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, child) {
        if (!viewModel.puedeMostrarControles) {
          return _construirEstadoSinControles();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.mensajeExito != null) ...[
              AvisoProductoAgregado(mensaje: viewModel.mensajeExito!),
              const SizedBox(height: 18),
            ],
            if (viewModel.mensajeError != null) ...[
              _AvisoErrorCarrito(mensaje: viewModel.mensajeError!),
              const SizedBox(height: 18),
            ],
            SelectorCantidad(
              cantidad: viewModel.cantidad,
              habilitado: !viewModel.agregando,
              onIncrementar: viewModel.incrementarCantidad,
              onDisminuir: viewModel.disminuirCantidad,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.puedeAgregar
                    ? () async {
                        await viewModel.agregarAlCarrito();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.exito,
                  foregroundColor: AppColors.blanco,
                  disabledBackgroundColor: AppColors.exito.withValues(
                    alpha: 0.55,
                  ),
                  disabledForegroundColor: AppColors.blanco,
                  elevation: 2,
                  shadowColor: AppColors.exito.withValues(alpha: 0.32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: viewModel.agregando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.blanco,
                            ),
                          ),
                          SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              'Agregando...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 21),
                          SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              'Agregar al carrito',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (viewModel.totalUnidades > 0) ...[
              const SizedBox(height: 12),
              Semantics(
                label:
                    '${viewModel.totalUnidades} '
                    'unidades en tu carrito',
                child: Text(
                  _textoTotalUnidades(viewModel.totalUnidades),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _construirEstadoSinControles() {
    if (viewModel.rolActual == RolUsuario.auditor) {
      return const _AvisoSoloLectura();
    }

    if (viewModel.mensajeError != null) {
      return _AvisoErrorCarrito(mensaje: viewModel.mensajeError!);
    }

    // Administrador conserva únicamente Editar y Eliminar.
    return const SizedBox.shrink();
  }

  String _textoTotalUnidades(int total) {
    if (total == 1) {
      return '1 unidad en tu carrito';
    }

    return '$total unidades en tu carrito';
  }
}

class _AvisoSoloLectura extends StatelessWidget {
  const _AvisoSoloLectura();

  @override
  Widget build(BuildContext context) {
    const mensaje = 'Solo lectura · Perfil Auditor';

    return Semantics(
      container: true,
      label: mensaje,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fondoCampo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bordeCampo),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: AppColors.textoSecundario,
              size: 21,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoErrorCarrito extends StatelessWidget {
  final String mensaje;

  const _AvisoErrorCarrito({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: mensaje,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fondoError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
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
}
