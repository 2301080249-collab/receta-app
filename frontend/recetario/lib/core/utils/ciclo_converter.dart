/// Utilidad para convertir entre números y ciclos romanos
class CicloConverter {
  // Mapa de conversión
  static const Map<int, String> _numeroARomano = {
    1: 'I',
    2: 'II',
    3: 'III',
    4: 'IV',
    5: 'V',
    6: 'VI',
    7: 'VII',
    8: 'VIII',
    9: 'IX',
    10: 'X',
  };

  static const Map<String, int> _romanoANumero = {
    'I': 1,
    'II': 2,
    'III': 3,
    'IV': 4,
    'V': 5,
    'VI': 6,
    'VII': 7,
    'VIII': 8,
    'IX': 9,
    'X': 10,
  };

  /// Convierte un número (1-10) o string numérico a romano (I-X)
  /// Si el valor está fuera de rango, retorna 'I' por defecto
  static String toRoman(dynamic ciclo) {
    int valor = 1;

    if (ciclo is int) {
      valor = ciclo;
    } else if (ciclo is String) {
      // Intenta parsear si ya es romano
      if (_romanoANumero.containsKey(ciclo)) {
        return ciclo; // Ya es romano, lo retorna tal cual
      }
      valor = int.tryParse(ciclo) ?? 1;
    }

    // Valida rango
    if (valor < 1 || valor > 10) {
      valor = 1;
    }

    return _numeroARomano[valor]!;
  }

  /// Convierte un ciclo romano (I-X) a número (1-10)
  /// Si no es válido, retorna 1
  static int toNumber(String romano) {
    return _romanoANumero[romano.toUpperCase()] ?? 1;
  }

  /// Obtiene todos los ciclos en formato romano
  static List<String> getAllRomanCycles() {
    return _numeroARomano.values.toList();
  }

  /// Obtiene todos los ciclos en formato numérico
  static List<int> getAllNumberCycles() {
    return _numeroARomano.keys.toList();
  }

  /// Valida si un string es un ciclo romano válido
  static bool isValidRoman(String ciclo) {
    return _romanoANumero.containsKey(ciclo.toUpperCase());
  }

  /// Formatea el ciclo para mostrar: "Ciclo I", "Ciclo II", etc.
  static String formatDisplay(dynamic ciclo) {
    return 'Ciclo ${toRoman(ciclo)}';
  }
}