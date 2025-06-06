import 'package:flutter/material.dart';

class TruthTableScreen extends StatefulWidget {
  const TruthTableScreen({super.key});

  @override
  State<TruthTableScreen> createState() => _TruthTableScreenState();
}

class _TruthTableScreenState extends State<TruthTableScreen> {
  int? selectedGate;
  int inputA = 0;
  int inputB = 0;
  bool showTruthTable = false;

  final Map<int, Map<String, dynamic>> gates = {
    1: {
      'name': 'AND',
      'function': (a, b) => a & b,
      'truthTable': [
        ['0', '0', '0'],
        ['0', '1', '0'],
        ['1', '0', '0'],
        ['1', '1', '1'],
      ],
    },
    2: {
      'name': 'OR',
      'function': (a, b) => a | b,
      'truthTable': [
        ['0', '0', '0'],
        ['0', '1', '1'],
        ['1', '0', '1'],
        ['1', '1', '1'],
      ],
    },
    3: {
      'name': 'NAND',
      'function': (a, b) => ~(a & b) & 1,
      'truthTable': [
        ['0', '0', '1'],
        ['0', '1', '1'],
        ['1', '0', '1'],
        ['1', '1', '0'],
      ],
    },
    4: {
      'name': 'NOR',
      'function': (a, b) => ~(a | b) & 1,
      'truthTable': [
        ['0', '0', '1'],
        ['0', '1', '0'],
        ['1', '0', '0'],
        ['1', '1', '0'],
      ],
    },
    5: {
      'name': 'XOR',
      'function': (a, b) => a ^ b,
      'truthTable': [
        ['0', '0', '0'],
        ['0', '1', '1'],
        ['1', '0', '1'],
        ['1', '1', '0'],
      ],
    },
    6: {
      'name': 'XNOR',
      'function': (a, b) => ~(a ^ b) & 1,
      'truthTable': [
        ['0', '0', '1'],
        ['0', '1', '0'],
        ['1', '0', '0'],
        ['1', '1', '1'],
      ],
    },
    7: {
      'name': 'NOT',
      'function': (a, b) => [~a & 1, ~b & 1],
      'truthTable': [
        ['0', '-', '1', '-'],
        ['1', '-', '0', '-'],
        ['-', '0', '-', '1'],
        ['-', '1', '-', '0'],
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logic Truth Tables'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a Logic Gate:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gates.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value['name']),
                  selected: selectedGate == entry.key,
                  onSelected: (selected) {
                    setState(() {
                      selectedGate = selected ? entry.key : null;
                      showTruthTable = false;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (selectedGate != null) ...[
              const Text(
                'Set Input Values:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InputToggle(
                    label: 'Input A',
                    value: inputA,
                    onChanged: (value) => setState(() => inputA = value),
                  ),
                  if (selectedGate != 7)
                    InputToggle(
                      label: 'Input B',
                      value: inputB,
                      onChanged: (value) => setState(() => inputB = value),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final result = gates[selectedGate]!['function'](inputA, inputB);
                  showResultDialog(context, result);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Calculate Output',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => showTruthTable = !showTruthTable),
                style: ElevatedButton.styleFrom(
                  backgroundColor: showTruthTable
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  showTruthTable ? 'Hide Truth Table' : 'Show Truth Table',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (showTruthTable && selectedGate != null) ...[
                const SizedBox(height: 24),
                TruthTableWidget(
                  gateName: gates[selectedGate]!['name'],
                  truthTable: gates[selectedGate]!['truthTable'],
                  isNotGate: selectedGate == 7,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void showResultDialog(BuildContext context, dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${gates[selectedGate]!['name']} Gate Result'),
        content: selectedGate == 7
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOT A: ${result[0]}'),
                  const SizedBox(height: 8),
                  Text('NOT B: ${result[1]}'),
                ],
              )
            : Text('Output: $result'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class InputToggle extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const InputToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [value == 0, value == 1],
          onPressed: (index) => onChanged(index),
          borderRadius: BorderRadius.circular(8),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('0 (FALSE)'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('1 (TRUE)'),
            ),
          ],
        ),
      ],
    );
  }
}

class TruthTableWidget extends StatelessWidget {
  final String gateName;
  final List<List<String>> truthTable;
  final bool isNotGate;

  const TruthTableWidget({
    super.key,
    required this.gateName,
    required this.truthTable,
    this.isNotGate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '$gateName Truth Table',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: const FixedColumnWidth(80),
                1: const FixedColumnWidth(80),
                2: const FixedColumnWidth(80),
                if (isNotGate) 3: const FixedColumnWidth(80),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('A')),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('B')),
                    ),
                    if (isNotGate)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: Text('¬A')),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: Text('Out')),
                      ),
                    if (isNotGate)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: Text('¬B')),
                      ),
                  ],
                ),
                ...truthTable.map(
                  (row) => TableRow(
                    children: row
                        .map(
                          (cell) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text(cell)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}