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
        primarySwatch: Colors.blue,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () => _onButtonPressed('Help'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Variable selection
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['x', 'y', 'z'].map((varName) {
                return ChoiceChip(
                  label: Text(varName),
                  selected: _selectedVariable == varName,
                  onSelected: (_) => _selectVariable(varName),
                  selectedColor: Colors.blue[200],
                );
              }).toList(),
            ),
          ),

          // Display area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _expression.isEmpty ? 'Enter expression' : _expression,
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (_showHelp) _buildHelpPanel(),
                  ],
                ),
              ),
            ),
          ),

          // Calculator buttons
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ...buttonRows.map((row) => Expanded(
                      child: Row(
                        children: row.map((btn) => _buildButton(btn)).toList(),
                      ),
                    )),
                Expanded(
                  child: Row(
                    children: [
                      _buildButton('C'),
                      _buildButton('x'),
                      _buildButton('y'),
                      _buildButton('z'),
                      _buildButton('Diff'),
                      _buildButton('Int'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    final isSpecial = ['C', '⌫', '=', 'Diff', 'Int'].contains(text);
    final isVariable = ['x', 'y', 'z'].contains(text);
    final isSelected = isVariable && text == _selectedVariable;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16.0),
            backgroundColor: isSelected
                ? Colors.orange
                : isSpecial
                    ? Colors.blue[700]
                    : Colors.blue[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpPanel() {
    return const Padding(
      padding: EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Help Guide:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('• Use buttons to build expressions'),
          Text('• Select variable (x/y/z) for calculus operations'),
          Text('• Diff: Differentiate expression'),
          Text('• Int: Integrate expression'),
          Text('• = : Simplify expression'),
          Text('• C : Clear expression'),
          Text('• ⌫ : Backspace'),
        ],
      ),
    );
  }
}