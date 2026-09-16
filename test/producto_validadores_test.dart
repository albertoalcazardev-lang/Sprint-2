import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/validators/producto_validadores.dart';

void main() {
  group('ProductoValidadores.validarTitulo', () {
    test('rechaza un título vacío', () {
      expect(ProductoValidadores.validarTitulo('   '), 'Completa el título.');
    });

    test('rechaza un título menor de tres caracteres', () {
      expect(
        ProductoValidadores.validarTitulo('ab'),
        'El título debe tener al menos 3 caracteres.',
      );
    });

    test('acepta un título válido eliminando espacios externos', () {
      expect(ProductoValidadores.validarTitulo('  Mochila urbana  '), isNull);
    });
  });

  group('ProductoValidadores.validarPrecio', () {
    test('rechaza un precio vacío', () {
      expect(ProductoValidadores.validarPrecio(''), 'Ingresa un precio.');
    });

    test('rechaza un precio con letras', () {
      expect(
        ProductoValidadores.validarPrecio('10abc'),
        'Ingresa un precio numérico.',
      );
    });

    test('rechaza un precio con más de un separador decimal', () {
      expect(
        ProductoValidadores.validarPrecio('10.5.2'),
        'Ingresa un precio numérico.',
      );
    });

    test('rechaza un precio igual a cero', () {
      expect(
        ProductoValidadores.validarPrecio('0'),
        'El precio debe ser mayor que cero.',
      );
    });

    test('rechaza un precio negativo', () {
      expect(
        ProductoValidadores.validarPrecio('-15.50'),
        'El precio debe ser mayor que cero.',
      );
    });

    test('acepta un precio con punto decimal', () {
      expect(ProductoValidadores.validarPrecio('109.95'), isNull);
    });

    test('acepta un precio con coma decimal', () {
      expect(ProductoValidadores.validarPrecio('109,95'), isNull);
    });

    test('convierte la coma decimal a double', () {
      expect(ProductoValidadores.convertirPrecio('109,95'), 109.95);
    });
  });

  group('ProductoValidadores.validarCategoria', () {
    test('rechaza una categoría nula', () {
      expect(
        ProductoValidadores.validarCategoria(null),
        'Selecciona una categoría.',
      );
    });

    test('rechaza una categoría vacía', () {
      expect(
        ProductoValidadores.validarCategoria('   '),
        'Selecciona una categoría.',
      );
    });

    test('acepta una categoría válida', () {
      expect(ProductoValidadores.validarCategoria("men's clothing"), isNull);
    });
  });

  group('ProductoValidadores.validarImageUrl', () {
    test('rechaza una URL vacía', () {
      expect(
        ProductoValidadores.validarImageUrl(''),
        'Ingresa la URL de la imagen.',
      );
    });

    test('rechaza una URL sin protocolo', () {
      expect(
        ProductoValidadores.validarImageUrl('ejemplo.com/imagen.jpg'),
        'Ingresa una URL válida.',
      );
    });

    test('rechaza un protocolo diferente de HTTP o HTTPS', () {
      expect(
        ProductoValidadores.validarImageUrl('ftp://ejemplo.com/imagen.jpg'),
        'Ingresa una URL válida.',
      );
    });

    test('acepta una URL HTTP absoluta', () {
      expect(
        ProductoValidadores.validarImageUrl('http://ejemplo.com/imagen.jpg'),
        isNull,
      );
    });

    test('acepta una URL HTTPS absoluta', () {
      expect(
        ProductoValidadores.validarImageUrl('https://ejemplo.com/imagen.jpg'),
        isNull,
      );
    });
  });

  group('ProductoValidadores.validarDescripcion', () {
    test('rechaza una descripción vacía', () {
      expect(
        ProductoValidadores.validarDescripcion(''),
        'Completa la descripción.',
      );
    });

    test('rechaza una descripción menor de diez caracteres', () {
      expect(
        ProductoValidadores.validarDescripcion('Producto'),
        'La descripción debe tener al menos 10 caracteres.',
      );
    });

    test('acepta una descripción válida', () {
      expect(
        ProductoValidadores.validarDescripcion(
          'Mochila urbana con espacio para portátil.',
        ),
        isNull,
      );
    });
  });

  group('ProductoValidadores.esFormularioValido', () {
    test('acepta un formulario completamente válido', () {
      final resultado = ProductoValidadores.esFormularioValido(
        titulo: 'Mochila urbana',
        precio: '109.95',
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila.jpg',
        descripcion: 'Mochila urbana con espacio para portátil.',
      );

      expect(resultado, isTrue);
    });

    test('rechaza el formulario si cualquier campo es inválido', () {
      final resultado = ProductoValidadores.esFormularioValido(
        titulo: 'Mochila urbana',
        precio: '0',
        categoria: "men's clothing",
        imageUrl: 'https://ejemplo.com/mochila.jpg',
        descripcion: 'Mochila urbana con espacio para portátil.',
      );

      expect(resultado, isFalse);
    });
  });
}
