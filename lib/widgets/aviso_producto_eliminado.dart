import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/resultado_eliminacion_producto.dart';

/// US08/E1 — P23: confirmación visual de eliminación simulada.
class AvisoProductoEliminado extends StatelessWidget {
  final String mensaje;

  const AvisoProductoEliminado({
    super.key,
    this.mensaje = ResultadoEliminacionProducto.mensajeSimulacion,
  });

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
          color: AppColors.fondoExito,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.exito.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.exito,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.exito,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
