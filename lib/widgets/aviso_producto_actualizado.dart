import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// US07/E1 — P21: confirmación de actualización simulada.
class AvisoProductoActualizado extends StatelessWidget {
  final String mensaje;

  const AvisoProductoActualizado({
    super.key,
    this.mensaje = 'Producto actualizado (Simulación)',
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
