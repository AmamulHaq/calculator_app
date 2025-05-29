// trigonometric.dart
import 'dart:math';

class Trigonometric {
  static Map<String, dynamic> calculate(double degrees, String operation) {
    final radians = degrees * pi / 180;
    double result;
    String displayText;
    
    switch (operation) {
      case 'sin':
        result = sin(radians);
        displayText = 'sin(${degrees.toStringAsFixed(2)}°)';
        break;
      case 'cos':
        result = cos(radians);
        displayText = 'cos(${degrees.toStringAsFixed(2)}°)';
        break;
      case 'tan':
        result = tan(radians);
        displayText = 'tan(${degrees.toStringAsFixed(2)}°)';
        if (result.abs() > 1e10) {
          throw Exception('Undefined');
        }
        break;
      case 'cosec':
        if (sin(radians).abs() < 1e-10) throw Exception('Undefined');
        result = 1 / sin(radians);
        displayText = 'cosec(${degrees.toStringAsFixed(2)}°)';
        break;
      case 'sec':
        if (cos(radians).abs() < 1e-10) throw Exception('Undefined');
        result = 1 / cos(radians);
        displayText = 'sec(${degrees.toStringAsFixed(2)}°)';
        break;
      case 'cot':
        if (tan(radians).abs() < 1e-10) throw Exception('Undefined');
        result = 1 / tan(radians);
        displayText = 'cot(${degrees.toStringAsFixed(2)}°)';
        break;
      default:
        throw Exception('Invalid operation');
    }

    return {
      'result': result,
      'displayText': displayText,
    };
  }
}