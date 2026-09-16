/// US06/E2 — Validaciones reutilizables del formulario de producto.
class ProductoValidadores {
  ProductoValidadores._();

  static final RegExp _formatoPrecio = RegExp(r'^-?\d+(?:[.,]\d+)?$');

  static String? validarTitulo(String? valor) {
    final titulo = valor?.trim() ?? '';

    if (titulo.isEmpty) {
      return 'Completa el título.';
    }

    if (titulo.length < 3) {
      return 'El título debe tener al menos 3 caracteres.';
    }

    return null;
  }

  static String? validarPrecio(String? valor) {
    final precioTexto = valor?.trim() ?? '';

    if (precioTexto.isEmpty) {
      return 'Ingresa un precio.';
    }

    if (!_formatoPrecio.hasMatch(precioTexto)) {
      return 'Ingresa un precio numérico.';
    }

    final precio = double.tryParse(precioTexto.replaceAll(',', '.'));

    if (precio == null) {
      return 'Ingresa un precio numérico.';
    }

    if (precio <= 0) {
      return 'El precio debe ser mayor que cero.';
    }

    return null;
  }

  static double convertirPrecio(String valor) {
    return double.parse(valor.trim().replaceAll(',', '.'));
  }

  static String? validarCategoria(String? valor) {
    final categoria = valor?.trim() ?? '';

    if (categoria.isEmpty) {
      return 'Selecciona una categoría.';
    }

    return null;
  }

  static String? validarImageUrl(String? valor) {
    final imageUrl = valor?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return 'Ingresa la URL de la imagen.';
    }

    final uri = Uri.tryParse(imageUrl);
    final esquema = uri?.scheme.toLowerCase();

    final esUrlValida =
        uri != null &&
        uri.host.isNotEmpty &&
        (esquema == 'http' || esquema == 'https');

    if (!esUrlValida) {
      return 'Ingresa una URL válida.';
    }

    return null;
  }

  static String? validarDescripcion(String? valor) {
    final descripcion = valor?.trim() ?? '';

    if (descripcion.isEmpty) {
      return 'Completa la descripción.';
    }

    if (descripcion.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres.';
    }

    return null;
  }

  static bool esFormularioValido({
    required String titulo,
    required String precio,
    required String? categoria,
    required String imageUrl,
    required String descripcion,
  }) {
    return validarTitulo(titulo) == null &&
        validarPrecio(precio) == null &&
        validarCategoria(categoria) == null &&
        validarImageUrl(imageUrl) == null &&
        validarDescripcion(descripcion) == null;
  }
}
