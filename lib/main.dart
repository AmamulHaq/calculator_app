import 'package:flutter/material.dart';
import 'dart:math';
//main function
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scientific Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _operation = '';
  double _firstNumber = 0;
  bool _waitingForSecondNumber = false;
  List<String> _history = [];

  String _formatResult(double result) {
    if (result.isNaN || result.isInfinite) return 'Error';
    if (result.truncateToDouble() == result) return result.truncate().toString();
    
    final formatted = result.toStringAsFixed(6)
      .replaceAll(RegExp(r'0*$'), '')
      .replaceAll(RegExp(r'\.$'), '');
    return formatted.isEmpty ? '0' : formatted;
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        _display = '0';
        _operation = '';
        _firstNumber = 0;
        _waitingForSecondNumber = false;
      } else if (buttonText == '%' || buttonText == '!') {
        try {
          final value = double.parse(_display);
          double result = buttonText == '%' ? value / 100 : _factorial(value);
          final formatted = _formatResult(result);
          
          if (_history.length >= 4) _history.removeAt(0); // Remove oldest entry
          _history.add('$value$buttonText = $formatted');
          
          _display = formatted;
        } catch (e) {
          _display = 'Error';
        }
      } else if (buttonText == '=') {
        if (_operation.isEmpty) return;
        
        try {
          final secondNumber = double.parse(_display);
          double result = 0;
          String expression = '';

          switch (_operation) {
            case '+':
              result = _firstNumber + secondNumber;
              expression = '${_formatResult(_firstNumber)} + ${_formatResult(secondNumber)}';
              break;
            case '-':
              result = _firstNumber - secondNumber;
              expression = '${_formatResult(_firstNumber)} - ${_formatResult(secondNumber)}';
              break;
            case '×':
              result = _firstNumber * secondNumber;
              expression = '${_formatResult(_firstNumber)} × ${_formatResult(secondNumber)}';
              break;
            case '÷':
              if (secondNumber == 0) throw Exception('Division by zero');
              result = _firstNumber / secondNumber;
              expression = '${_formatResult(_firstNumber)} ÷ ${_formatResult(secondNumber)}';
              break;
            case '^':
              result = pow(_firstNumber, secondNumber).toDouble();
              expression = '${_formatResult(_firstNumber)} ^ ${_formatResult(secondNumber)}';
              break;
            case '√':
              if (_firstNumber == 0) throw Exception('Root undefined');
              result = pow(secondNumber, 1 / _firstNumber).toDouble();
              expression = '${_formatResult(_firstNumber)}√${_formatResult(secondNumber)}';
              break;
            case 'P':
              result = _permutation(_firstNumber, secondNumber);
              expression = 'P(${_firstNumber.truncate()}, ${secondNumber.truncate()})';
              break;
            case 'C':
              result = _combination(_firstNumber, secondNumber);
              expression = 'C(${_firstNumber.truncate()}, ${secondNumber.truncate()})';
              break;
          }

          final formatted = _formatResult(result);
          if (_history.length >= 4) _history.removeAt(0); // Remove oldest entry
          _history.add('$expression = $formatted');
          
          _display = formatted;
          _operation = '';
          _waitingForSecondNumber = false;
        } catch (e) {
          _display = 'Error';
        }
      } else if (['+', '-', '×', '÷', '^', '√', 'P', 'C'].contains(buttonText)) {
        _firstNumber = double.parse(_display);
        _operation = buttonText;
        _waitingForSecondNumber = true;
        _display = '0';
      } else {
        if (_display == '0' || _waitingForSecondNumber || _display == 'Error') {
          _display = buttonText;
          _waitingForSecondNumber = false;
        } else if (buttonText == '.' && !_display.contains('.')) {
          _display += buttonText;
        } else if (buttonText != '.') {
          _display += buttonText;
        }
      }
    });
  }

  double _factorial(double n) {
    if (n < 0 || n > 20) return double.nan; // Limit to prevent overflow
    if (n < 2) return 1;
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  double _permutation(double n, double r) {
    if (n < 0 || r < 0 || r > n || n != n.truncate() || r != r.truncate()) {
      return double.nan;
    }
    return _factorial(n) / _factorial(n - r);
  }

  double _combination(double n, double r) {
    if (n < 0 || r < 0 || r > n || n != n.truncate() || r != r.truncate()) {
      return double.nan;
    }
    return _factorial(n) / (_factorial(r) * _factorial(n - r));
  }

  Widget _buildButton(String text, {Color? color, double? fontSize, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minDimension = min(constraints.maxWidth, constraints.maxHeight);
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Theme.of(context).colorScheme.surface,
                foregroundColor: color != null ? Colors.white : Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(minDimension * 0.2),
                ),
                padding: EdgeInsets.all(minDimension * 0.15),
              ),
              onPressed: () => _onButtonPressed(text),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? minDimension * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Calculator'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // History Display - Most recent at bottom
              Container(
                height: constraints.maxHeight * 0.2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: ListView.builder(
                  reverse: false,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        _history[index],
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Main Display
              Container(
                height: constraints.maxHeight * 0.15,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignment: Alignment.bottomRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Buttons Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('AC', color: Colors.grey),
                            _buildButton('!', color: Colors.blue),
                            _buildButton('^', color: Colors.blue),
                            _buildButton('√', color: Colors.blue),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('P', color: Colors.blue),
                            _buildButton('C', color: Colors.blue),
                            _buildButton('%', color: Colors.grey),
                            _buildButton('÷', color: Colors.orange),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('7'),
                            _buildButton('8'),
                            _buildButton('9'),
                            _buildButton('×', color: Colors.orange),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('4'),
                            _buildButton('5'),
                            _buildButton('6'),
                            _buildButton('-', color: Colors.orange),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('1'),
                            _buildButton('2'),
                            _buildButton('3'),
                            _buildButton('+', color: Colors.orange),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildButton('0', flex: 2),
                            _buildButton('.'),
                            _buildButton('=', color: Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}