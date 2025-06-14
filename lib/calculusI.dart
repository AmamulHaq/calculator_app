import 'package:flutter/material.dart';
import 'calculus.dart';

void main() => runApp(const CalculusApp());

class CalculusApp extends StatelessWidget {
  const CalculusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculus Calculator',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
          accentColor: Colors.amber,
          backgroundColor: Colors.grey[50],
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  String _selectedVariable = 'x';
  bool _showHelp = false;

  void _onButtonPressed(String text) {
    setState(() {
      if (text == 'C') {
        _expression = '';
        _result = '';
      } else if (text == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (text == '=') {
        _evaluateExpression();
      } else if (text == 'Diff') {
        _differentiateExpression();
      } else if (text == 'Int') {
        _integrateExpression();
      } else if (text == 'Help') {
        _showHelp = !_showHelp;
      } else {
        _expression += text;
      }
    });
  }

  void _evaluateExpression() {
    try {
      var tokens = tokenize(_expression);
      var postfix = infixToPostfix(tokens);
      var simplified = simplify(postfix);
      _result = tokensToString(simplified);
    } catch (e) {
      _result = 'Error: $e';
    }
  }

  void _differentiateExpression() {
    try {
      var tokens = tokenize(_expression);
      var postfix = infixToPostfix(tokens);
      var deriv = differentiate(postfix, _selectedVariable);
      var simp = simplify(deriv);
      _result = 'd/d$_selectedVariable = ${tokensToString(simp)}';
    } catch (e) {
      _result = 'Error: $e';
    }
  }

  void _integrateExpression() {
    try {
      var tokens = tokenize(_expression);
      var integral = integrateExpression(tokens, _selectedVariable);
      var integralPostfix = infixToPostfix(integral);
      var simplifiedIntegral = simplify(integralPostfix);
      _result = '∫ = ${tokensToString(simplifiedIntegral)} + C';
    } catch (e) {
      _result = 'Error: $e';
    }
  }

  void _selectVariable(String variable) {
    setState(() {
      _selectedVariable = variable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttonRows = [
      ['7', '8', '9', '+', '-'],
      ['4', '5', '6', '*', '/'],
      ['1', '2', '3', '(', ')'],
      ['0', '.', '^', '=', '⌫'],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculus Calculator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () => _onButtonPressed('Help'),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Variable selection
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['x', 'y', 'z'].map((varName) {
                return ChoiceChip(
                  label: Text(
                    varName,
                    style: TextStyle(
                      color: _selectedVariable == varName
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),
                  selected: _selectedVariable == varName,
                  onSelected: (_) => _selectVariable(varName),
                  selectedColor: const Color.fromARGB(255, 25, 118, 210),
                  backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),

          // Display area
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _expression.isEmpty ? 'Enter expression' : _expression,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (_showHelp) _buildHelpPanel(context),
                  ],
                ),
              ),
            ),
          ),

          // Calculator buttons
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...buttonRows.map((row) => Expanded(
                    child: Row(
                      children: row.map((btn) => _buildButton(context, btn)).toList(),
                    ),
                  )),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, 'C'),
                        _buildButton(context, 'x'),
                        _buildButton(context, 'y'),
                        _buildButton(context, 'z'),
                        _buildButton(context, 'Diff'),
                        _buildButton(context, 'Int'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    final isSpecial = ['C', '⌫', '='].contains(text);
    final isBlueSpecial = ['Diff', 'Int'].contains(text);
    final isVariable = ['x', 'y', 'z'].contains(text);
    final isSelected = isVariable && text == _selectedVariable;
    final isOperator = ['+', '-', '*', '/', '^', '(', ')'].contains(text);

    // Define the specified colors
    final blueColor = const Color.fromARGB(255, 33, 150, 243);   // (33,150,243,255)
    final amberColor = const Color.fromARGB(255, 255, 152, 0);   // (255,152,0,255)
    final greyColor = const Color.fromARGB(255, 158, 158, 158);  // (158,158,158,255)
    final selectedVariableColor = const Color.fromARGB(255, 25, 118, 210); // Darker blue for selected

    Color? buttonColor;
    Color? textColor;

    if (isSelected) {
      buttonColor = selectedVariableColor;
      textColor = Colors.white;
    } else if (isBlueSpecial) {
      buttonColor = blueColor;
      textColor = Colors.white;
    } else if (isVariable) {
      buttonColor = blueColor;
      textColor = Colors.white;
    } else if (isOperator) {
      buttonColor = amberColor;
      textColor = Colors.white;
    } else if (isSpecial) {
      buttonColor = greyColor;
      textColor = Colors.white;
    } else {
      buttonColor = Theme.of(context).colorScheme.surface;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12.0),
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help Guide:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Use buttons to build expressions\n'
            '• Select variable (x/y/z) for calculus operations\n'
            '• Diff: Differentiate expression\n'
            '• Int: Integrate expression\n'
            '• = : Simplify expression\n'
            '• C : Clear expression\n'
            '• ⌫ : Backspace',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}