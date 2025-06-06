import 'package:flutter/material.dart';
import 'dart:math';

class MatrixCalculator extends StatefulWidget {
  const MatrixCalculator({super.key});

  @override
  State<MatrixCalculator> createState() => _MatrixCalculatorState();
}

class _MatrixCalculatorState extends State<MatrixCalculator> {
  String _currentOperation = '';
  String _result = '';
  List<String> _history = [];
  final List<List<TextEditingController>> _matrixAControllers = [];
  final List<List<TextEditingController>> _matrixBControllers = [];
  int _rowsA = 2, _colsA = 2, _rowsB = 2, _colsB = 2;
  bool _showMatrixB = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _matrixAControllers.clear();
    _matrixBControllers.clear();

    for (int i = 0; i < _rowsA; i++) {
      _matrixAControllers.add([]);
      for (int j = 0; j < _colsA; j++) {
        _matrixAControllers[i].add(TextEditingController(text: '0'));
      }
    }

    for (int i = 0; i < _rowsB; i++) {
      _matrixBControllers.add([]);
      for (int j = 0; j < _colsB; j++) {
        _matrixBControllers[i].add(TextEditingController(text: '0'));
      }
    }
  }

  @override
  void dispose() {
    for (var row in _matrixAControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in _matrixBControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  List<List<double>> _getMatrixA() {
    return _matrixAControllers.map((row) =>
        row.map((c) => double.tryParse(c.text) ?? 0).toList()).toList();
  }

  List<List<double>> _getMatrixB() {
    return _matrixBControllers.map((row) =>
        row.map((c) => double.tryParse(c.text) ?? 0).toList()).toList();
  }

  String _matrixToString(List<List<double>> matrix) {
    return matrix.map((row) =>
        row.map((val) => val.toStringAsFixed(2)).join('\t')).join('\n');
  }

  void _addToHistory(String operation, String result) {
    setState(() {
      if (_history.length >= 5) _history.removeAt(0);
      _history.add('$operation: \n$result');
    });
  }

  void _clearMatrices() {
    setState(() {
      for (var row in _matrixAControllers) {
        for (var cell in row) {
          cell.text = '0';
        }
      }
      for (var row in _matrixBControllers) {
        for (var cell in row) {
          cell.text = '0';
        }
      }
      _result = '';
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _performAddition() {
    final matrixA = _getMatrixA();
    final matrixB = _getMatrixB();

    if (matrixA.length != matrixB.length || matrixA[0].length != matrixB[0].length) {
      setState(() => _result = 'Error: Matrices must be same size');
      return;
    }

    final result = List.generate(matrixA.length, (i) =>
        List.generate(matrixA[0].length, (j) => matrixA[i][j] + matrixB[i][j]));

    setState(() {
      _result = 'Result:\n${_matrixToString(result)}';
      _addToHistory('Addition', _result);
    });
  }

  void _performMultiplication() {
    final matrixA = _getMatrixA();
    final matrixB = _getMatrixB();

    if (matrixA[0].length != matrixB.length) {
      setState(() => _result = 'Error: Columns of A must match rows of B');
      return;
    }

    final result = List.generate(matrixA.length, (i) =>
        List.generate(matrixB[0].length, (j) {
          double sum = 0;
          for (int k = 0; k < matrixA[0].length; k++) {
            sum += matrixA[i][k] * matrixB[k][j];
          }
          return sum;
        }));

    setState(() {
      _result = 'Result:\n${_matrixToString(result)}';
      _addToHistory('Multiplication', _result);
    });
  }

  void _performDeterminant() {
    final matrix = _getMatrixA();
    if (matrix.length != matrix[0].length) {
      setState(() => _result = 'Error: Matrix must be square');
      return;
    }

    try {
      final det = _calculateDeterminant(matrix);
      setState(() {
        _result = 'Determinant: ${det.toStringAsFixed(2)}';
        _addToHistory('Determinant', _result);
      });
    } catch (e) {
      setState(() => _result = 'Error: ${e.toString()}');
    }
  }

  double _calculateDeterminant(List<List<double>> matrix) {
    if (matrix.length == 1) return matrix[0][0];
    if (matrix.length == 2) {
      return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
    }

    double det = 0;
    for (int i = 0; i < matrix.length; i++) {
      final minor = List.generate(matrix.length - 1, (k) =>
          List.generate(matrix.length - 1, (l) =>
              matrix[k + 1][l < i ? l : l + 1]));
      det += matrix[0][i] * pow(-1, i) * _calculateDeterminant(minor);
    }
    return det;
  }

  Widget _buildMatrixInput(String title, List<List<TextEditingController>> controllers) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.symmetric(
                inside: const BorderSide(color: Colors.grey),
                outside: const BorderSide(color: Colors.grey),
              ),
              columnWidths: Map.fromIterables(
                Iterable<int>.generate(controllers[0].length),
                Iterable<FixedColumnWidth>.generate(controllers[0].length, 
                  (index) => const FixedColumnWidth(56))
              ),
              children: controllers.map((row) =>
                  TableRow(
                    children: row.map((cell) =>
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TextField(
                            controller: cell,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        )
                    ).toList(),
                  )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMatrixSizeDialog(bool isMatrixA) async {
    final rowsController = TextEditingController(text: isMatrixA ? _rowsA.toString() : _rowsB.toString());
    final colsController = TextEditingController(text: isMatrixA ? _colsA.toString() : _colsB.toString());

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('${isMatrixA ? 'Matrix A' : 'Matrix B'} Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rowsController,
                        decoration: const InputDecoration(labelText: 'Rows'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: colsController,
                        decoration: const InputDecoration(labelText: 'Columns'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final rows = int.tryParse(rowsController.text) ??
                      (isMatrixA ? _rowsA : _rowsB);
                  final cols = int.tryParse(colsController.text) ??
                      (isMatrixA ? _colsA : _colsB);

                  if (rows > 0 && cols > 0) {
                    setState(() {
                      if (isMatrixA) {
                        _rowsA = rows;
                        _colsA = cols;
                      } else {
                        _rowsB = rows;
                        _colsB = cols;
                      }
                      _initializeControllers();
                      _showMatrixB = _currentOperation == 'Addition' || _currentOperation == 'Multiplication';
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Calculator'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildMatrixInput('Matrix A', _matrixAControllers),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Resize'),
                        onPressed: () => _showMatrixSizeDialog(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showMatrixB) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildMatrixInput('Matrix B', _matrixBControllers),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Resize'),
                          onPressed: () => _showMatrixSizeDialog(false),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOperationButton('Addition', Icons.add),
                _buildOperationButton('Multiplication', Icons.close),
                _buildOperationButton('Determinant', Icons.functions),
                _buildOperationButton('Transpose', Icons.swap_horiz),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearMatrices,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Matrices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Clear History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Result:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _result.split('\n').sublist(1).join('\n'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'RobotoMono',
                          color: Colors.blue
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._history.reversed.map((entry) =>
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        entry,
                        style: const TextStyle(fontSize: 14, fontFamily: 'RobotoMono'),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationButton(String operation, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(operation),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: _currentOperation == operation 
            ? Theme.of(context).primaryColor.withOpacity(0.9)
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _currentOperation = operation;
          _showMatrixB = operation == 'Addition' || operation == 'Multiplication';
        });
        
        if (operation == 'Addition') {
          _performAddition();
        } else if (operation == 'Multiplication') {
          _performMultiplication();
        } else if (operation == 'Determinant') {
          _performDeterminant();
        } else if (operation == 'Transpose') {
          final transposed = List.generate(_colsA, (i) =>
              List.generate(_rowsA, (j) => _getMatrixA()[j][i]));
          setState(() {
            _result = 'Result:\n${_matrixToString(transposed)}';
            _addToHistory('Transpose', _result);
          });
        }
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show Matrix B'),
              value: _showMatrixB,
              onChanged: (value) {
                setState(() => _showMatrixB = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}