import 'package:flutter/material.dart';

/// A fun mini calculator bottom sheet.
/// Returns a double value when user taps "Add 💸" or null if dismissed.
class CalcBottomSheet extends StatefulWidget {
  final String initialValue;
  const CalcBottomSheet({super.key, this.initialValue = ''});

  @override
  State<CalcBottomSheet> createState() => _CalcBottomSheetState();

  /// Show the calculator and return the result
  static Future<double?> show(BuildContext context, {String initialValue = ''}) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalcBottomSheet(initialValue: initialValue),
    );
  }
}

class _CalcBottomSheetState extends State<CalcBottomSheet> {
  String _display = '0';
  String _expression = '';
  double _result = 0;
  String? _lastOp;
  bool _hasResult = false;

  // Funny messages that rotate based on the result
  final _funnyMessages = [
    'Oof. That hurts. 💀',
    'RIP Wallet 🪦',
    'Your savings left the chat 👋',
    'Bold. Very bold. 🫡',
    'Are you sure about this? 😬',
    'Math checks out. Wallet doesn\'t. 📉',
    'Calculator says yes. Bank says no. 🏦',
    'This better be worth it 🤞',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue.isNotEmpty) {
      final parsed = double.tryParse(widget.initialValue);
      if (parsed != null && parsed > 0) {
        _display = _formatNumber(parsed);
        _result = parsed;
      }
    }
  }

  String _formatNumber(double n) {
    if (n == n.toInt().toDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  void _onDigit(String digit) {
    setState(() {
      if (_hasResult) {
        _display = digit;
        _expression = '';
        _hasResult = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_hasResult) {
        _expression = '${_formatNumber(_result)} $op ';
        _display = '0';
        _lastOp = op;
        _hasResult = false;
      } else {
        final current = double.tryParse(_display) ?? 0;
        if (_lastOp != null && _expression.isNotEmpty) {
          _result = _calculate(_result, current, _lastOp!);
        } else {
          _result = current;
        }
        _expression = '${_formatNumber(_result)} $op ';
        _display = '0';
        _lastOp = op;
      }
    });
  }

  void _onEquals() {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      if (_lastOp != null) {
        _result = _calculate(_result, current, _lastOp!);
      } else {
        _result = current;
      }
      _display = _formatNumber(_result);
      _expression = '';
      _lastOp = null;
      _hasResult = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _result = 0;
      _lastOp = null;
      _hasResult = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  double _calculate(double a, double b, String op) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '×': return a * b;
      case '÷': return b != 0 ? a / b : 0;
      default: return b;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final btnColor = isDark ? const Color(0xFF252540) : Colors.grey.shade100;
    final opColor = const Color(0xFF5D5FEF);
    final textColor = isDark ? Colors.white : Colors.black87;

    final funnyMsg = _hasResult && _result > 0
        ? _funnyMessages[(_result.toInt()) % _funnyMessages.length]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Row(
                children: [
                  Icon(Icons.calculate, color: opColor, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Math 🧮',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _onClear,
                    child: Text('AC', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Expression line
              if (_expression.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _expression,
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                  ),
                ),

              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (funnyMsg != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        funnyMsg,
                        style: TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              // Keypad grid
              _buildKeypadRow([
                _CalcBtn('7', btnColor, textColor, () => _onDigit('7')),
                _CalcBtn('8', btnColor, textColor, () => _onDigit('8')),
                _CalcBtn('9', btnColor, textColor, () => _onDigit('9')),
                _CalcBtn('÷', opColor.withOpacity(0.15), opColor, () => _onOperator('÷')),
              ], screenWidth),
              const SizedBox(height: 8),
              _buildKeypadRow([
                _CalcBtn('4', btnColor, textColor, () => _onDigit('4')),
                _CalcBtn('5', btnColor, textColor, () => _onDigit('5')),
                _CalcBtn('6', btnColor, textColor, () => _onDigit('6')),
                _CalcBtn('×', opColor.withOpacity(0.15), opColor, () => _onOperator('×')),
              ], screenWidth),
              const SizedBox(height: 8),
              _buildKeypadRow([
                _CalcBtn('1', btnColor, textColor, () => _onDigit('1')),
                _CalcBtn('2', btnColor, textColor, () => _onDigit('2')),
                _CalcBtn('3', btnColor, textColor, () => _onDigit('3')),
                _CalcBtn('-', opColor.withOpacity(0.15), opColor, () => _onOperator('-')),
              ], screenWidth),
              const SizedBox(height: 8),
              _buildKeypadRow([
                _CalcBtn('.', btnColor, textColor, () => _onDigit('.')),
                _CalcBtn('0', btnColor, textColor, () => _onDigit('0')),
                _CalcBtn('⌫', btnColor, Colors.redAccent, _onBackspace),
                _CalcBtn('+', opColor.withOpacity(0.15), opColor, () => _onOperator('+')),
              ], screenWidth),
              const SizedBox(height: 12),

              // Bottom row: = and Add
              Row(
                children: [
                  // Equals button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onEquals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: opColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('=', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add to amount button
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // If no result yet, calculate first
                          if (!_hasResult && _lastOp != null) _onEquals();
                          final value = _hasResult ? _result : (double.tryParse(_display) ?? 0);
                          if (value > 0) {
                            Navigator.pop(context, value);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Add 💸', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<_CalcBtn> buttons, double screenWidth) {
    return Row(
      children: buttons.map((btn) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: btn.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btn.bgColor,
                  foregroundColor: btn.textColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(btn.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalcBtn {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;
  _CalcBtn(this.label, this.bgColor, this.textColor, this.onTap);
}
