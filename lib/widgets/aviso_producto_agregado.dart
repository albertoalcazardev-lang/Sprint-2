import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// US09/E1-E2 — P10: confirmación visual del agregado al carrito.
class AvisoProductoAgregado extends StatelessWidget {
  static const String mensajePredeterminado = 'Producto añadido a tu carrito.';

  final String mensaje;

  const AvisoProductoAgregado({
    super.key,
    this.mensaje = mensajePredeterminado,
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
              Icons.shopping_cart_checkout_rounded,
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
