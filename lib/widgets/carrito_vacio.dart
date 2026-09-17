import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CarritoVacio extends StatelessWidget {
  final VoidCallback onExplorarCatalogo;

  const CarritoVacio({super.key, required this.onExplorarCatalogo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.fondoCampo,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 43,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu carrito está vacío',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explora el catálogo y añade los artículos que quieras comprar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onExplorarCatalogo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primario,
                foregroundColor: AppColors.blanco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Explorar catálogo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
