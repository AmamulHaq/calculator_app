import 'package:flutter/material.dart';
import 'matrix.dart';
import 'truthtable.dart';
import 'dart:math';
import 'calculusI.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentScreenIndex = 0;

  final List<Widget> _screens = [
    const ScientificCalculator(),
    const MatrixCalculator(),
    const TruthTableScreen(),
    const CalculusApp(),
  ];

  final List<String> _titles = [
    'Scientific Calculator',
    'Matrix Calculator',
    'Truth Tables',
    'Calculus'
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentScreenIndex]),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Advanced Calculator',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('Scientific Calculator'),
                onTap: () {
                  setState(() => _currentScreenIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Matrix Calculator'),
                onTap: () {
                  setState(() => _currentScreenIndex = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Truth Tables'),
                onTap: () {
                  setState(() => _currentScreenIndex = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('Calculus'),
                onTap: () {
                  setState(() => _currentScreenIndex = 3);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: _screens[_currentScreenIndex],
      ),
    );
  }
}

class ScientificCalculator extends StatefulWidget {
  const ScientificCalculator({super.key});

  @override
  State<ScientificCalculator> createState() => _ScientificCalculatorState();
}

enum TokenType { number, operator, function, constant, parenthesis }

class Token {
  final TokenType type;
  final String value;
  final int? precedence;
  final bool isLeftAssociative;

  Token(this.type, this.value, {this.precedence, this.isLeftAssociative = true});
}

class _ScientificCalculatorState extends State<ScientificCalculator> {
  String _expression = '';
  String _result = '';
  final List<String> _history = [];

  final Map<String, int> _precedence = {
    '+': 1,
    '-': 1,
    '×': 2,
    '÷': 2,
    '^': 3,
    'u-': 4,
  };

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        _expression = '';
        _result = '';
        _history.clear();
      } else if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        _evaluateExpression();
      } else {
        // Handle special functions that need parentheses
        if (['sin', 'cos', 'tan', 'cosec', 'sec', 'cot', 'ln', 'log', '√x', 'e^x', 'P', 'C'].contains(value)) {
          _expression += '$value(';
        } else if (value == '!') {
          _expression += '!';
        } else {
          _expression += value;
        }
      }
    });
  }

  List<Token> _tokenize(String expression) {
    List<Token> tokens = [];
    int i = 0;
    while (i < expression.length) {
      final char = expression[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      // Numbers
      if (RegExp(r'\d|\.\d').hasMatch(char)) {
        String numStr = '';
        while (i < expression.length &&
            RegExp(r'[\d.]').hasMatch(expression[i])) {
          numStr += expression[i++];
        }
        tokens.add(Token(TokenType.number, numStr));
        continue;
      }

      // Constants
      if (char == 'π' || char == 'e') {
        tokens.add(Token(TokenType.constant, char));
        i++;
        continue;
      }

      // Unary minus
      if (char == '-' &&
          (tokens.isEmpty ||
              tokens.last.type == TokenType.operator ||
              tokens.last.value == '(')) {
        tokens.add(Token(TokenType.operator, 'u-', precedence: _precedence['u-']));
        i++;
        continue;
      }

      // Functions
      final funcs = [
        'sin', 'cos', 'tan', 'cosec', 'sec', 'cot', 'log', 'ln', '√x', 'e^x', 'P', 'C', '!'
      ];
      bool matched = false;
      for (var func in funcs) {
        if (expression.startsWith(func, i)) {
          // Handle function name mapping
          String tokenValue = func;
          if (func == '√x') tokenValue = '√';
          if (func == 'e^x') tokenValue = 'e^';
          
          tokens.add(Token(TokenType.function, tokenValue));
          i += func.length;
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // Operators
      if (_precedence.containsKey(char)) {
        tokens.add(Token(TokenType.operator, char, precedence: _precedence[char] ?? 0));
        i++;
        continue;
      }

      // Parenthesis and comma
      if (['(', ')', ','].contains(char)) {
        tokens.add(Token(TokenType.parenthesis, char));
        i++;
        continue;
      }

      i++; // skip unknown characters
    }
    return tokens;
  }

  List<Token> _shuntingYard(List<Token> tokens) {
    List<Token> output = [];
    List<Token> stack = [];

    for (var token in tokens) {
      switch (token.type) {
        case TokenType.number:
        case TokenType.constant:
          output.add(token);
          break;
        case TokenType.function:
          stack.add(token);
          break;
        case TokenType.operator:
          while (stack.isNotEmpty &&
              stack.last.type == TokenType.operator &&
              (token.precedence! < stack.last.precedence! ||
                  (token.precedence == stack.last.precedence &&
                      token.isLeftAssociative))) {
            output.add(stack.removeLast());
          }
          stack.add(token);
          break;
        case TokenType.parenthesis:
          if (token.value == '(') {
            stack.add(token);
          } else if (token.value == ')') {
            while (stack.isNotEmpty && stack.last.value != '(') {
              output.add(stack.removeLast());
            }
            if (stack.isEmpty) throw Exception('Mismatched parentheses');
            stack.removeLast(); // Remove '('
            if (stack.isNotEmpty && stack.last.type == TokenType.function) {
              output.add(stack.removeLast());
            }
          } else if (token.value == ',') {
            while (stack.isNotEmpty && stack.last.value != '(') {
              output.add(stack.removeLast());
            }
            if (stack.isEmpty) throw Exception('Comma outside function');
          }
          break;
      }
    }

    while (stack.isNotEmpty) {
      if (stack.last.value == '(') throw Exception('Mismatched parentheses');
      output.add(stack.removeLast());
    }

    return output;
  }

  double _evaluateRPN(List<Token> tokens) {
    final stack = <double>[];

    for (var token in tokens) {
      if (token.type == TokenType.number) {
        stack.add(double.parse(token.value));
      } else if (token.type == TokenType.constant) {
        stack.add(token.value == 'π' ? pi : e);
      } else if (token.type == TokenType.operator) {
        if (token.value == 'u-') {
          var x = stack.removeLast();
          stack.add(-x);
        } else {
          var b = stack.removeLast();
          var a = stack.removeLast();
          switch (token.value) {
            case '+':
              stack.add(a + b);
              break;
            case '-':
              stack.add(a - b);
              break;
            case '×':
              stack.add(a * b);
              break;
            case '÷':
              stack.add(a / b);
              break;
            case '^':
              stack.add(pow(a, b).toDouble());
              break;
          }
        }
      } else if (token.type == TokenType.function) {
        double x;
        double y = 0;
        
        // For functions that take two arguments (P and C)
        if (token.value == 'P' || token.value == 'C') {
          x = stack.removeLast();
          y = stack.removeLast();
        } else {
          x = stack.removeLast();
        }
        
        switch (token.value) {
          case 'sin':
            stack.add(sin(x * pi / 180));
            break;
          case 'cos':
            stack.add(cos(x * pi / 180));
            break;
          case 'tan':
            stack.add(tan(x * pi / 180));
            break;
          case 'cosec':
            stack.add(1 / sin(x * pi / 180));
            break;
          case 'sec':
            stack.add(1 / cos(x * pi / 180));
            break;
          case 'cot':
            stack.add(1 / tan(x * pi / 180));
            break;
          case 'log':
            stack.add(log(x) / ln10);
            break;
          case 'ln':
            stack.add(log(x));
            break;
          case '√':
            stack.add(sqrt(x));
            break;
          case 'e^':
            stack.add(exp(x));
            break;
          case '!':
            stack.add(_factorial(x));
            break;
          case 'P':
            stack.add(_permutation(y, x));
            break;
          case 'C':
            stack.add(_combination(y, x));
            break;
        }
      }
    }

    return stack.isEmpty ? 0 : stack.first;
  }

  double _factorial(double n) {
    if (n < 0 || n > 20 || n != n.truncate()) return double.nan;
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

  void _evaluateExpression() {
    try {
      if (_expression.isEmpty) return;
      
      final tokens = _tokenize(_expression);
      final rpn = _shuntingYard(tokens);
      final result = _evaluateRPN(rpn);
      final formatted = _formatResult(result);

      if (_history.length >= 4) _history.removeAt(0);
      _history.add('$_expression = $formatted');

      setState(() {
        _result = formatted;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
      });
    }
  }

  String _formatResult(double result) {
    if (result.isNaN || result.isInfinite) return 'Error';
    if (result.truncateToDouble() == result) return result.truncate().toString();

    final formatted = result
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return formatted.isEmpty ? '0' : formatted;
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize ?? minDimension * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Fixed history container with proper parenthesis
            Container(
              height: constraints.maxHeight * 0.2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.topRight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
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
            Container(
              height: constraints.maxHeight * 0.1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _expression,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Container(
              height: constraints.maxHeight * 0.1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('sin', color: Colors.purple),
                          _buildButton('cos', color: Colors.purple),
                          _buildButton('tan', color: Colors.purple),
                          _buildButton('√x', color: Colors.blue),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('cosec', color: Colors.purple),
                          _buildButton('sec', color: Colors.purple),
                          _buildButton('cot', color: Colors.purple),
                          _buildButton('e^x', color: Colors.blue),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('ln', color: Colors.blue),
                          _buildButton('log', color: Colors.blue),
                          _buildButton('!', color: Colors.blue),
                          _buildButton('÷', color: Colors.orange),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('AC', color: Colors.grey),
                          _buildButton('⌫', color: Colors.grey),
                          _buildButton('C', color: Colors.grey),
                          _buildButton('×', color: Colors.orange),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('7'),
                          _buildButton('8'),
                          _buildButton('9'),
                          _buildButton('-', color: Colors.orange),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('4'),
                          _buildButton('5'),
                          _buildButton('6'),
                          _buildButton('+', color: Colors.orange),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('1'),
                          _buildButton('2'),
                          _buildButton('3'),
                          _buildButton('^', color: Colors.blue),
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
    );
  }
}