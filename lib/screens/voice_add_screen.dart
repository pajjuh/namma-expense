import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../helpers/constants.dart';

class VoiceAddScreen extends StatefulWidget {
  const VoiceAddScreen({super.key});

  @override
  State<VoiceAddScreen> createState() => _VoiceAddScreenState();
}

class _VoiceAddScreenState extends State<VoiceAddScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the mic and say something...';
  double _confidence = 1.0;
  
  // Parsed data
  double? _parsedAmount;
  String? _parsedNote;
  String? _parsedCategory;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_text.isNotEmpty && _text != 'Press the mic and say something...') {
               _parseText(_text);
            }
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _text = "Listening...";
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _parseText(String input) {
    // Regex for grabbing amount: looks for digits, maybe with currency words like "rupees"
    // Heuristic: "12 rupees for bhajiya"
    
    // 1. Extract Amount
    double amount = 0.0;
    final amountRegex = RegExp(r'(\d+(\.\d+)?)');
    final match = amountRegex.firstMatch(input);
    if (match != null) {
      amount = double.tryParse(match.group(0)!) ?? 0.0;
    }
    
    // 2. Extract Category & Note
    // Simple heuristic: if input contains "for", split there. 
    // "100 for fuel" -> amount=100, note="fuel"
    String note = '';
    String categoryId = 'other'; // default
    
    if (input.toLowerCase().contains(' for ')) {
      final parts = input.toLowerCase().split(' for ');
      if (parts.length > 1) {
        note = parts[1].trim();
      }
    } else {
        // Fallback: remove amount from string and use rest as note
        note = input.replaceAll(RegExp(r'\d+'), '').replaceAll('rupees', '').replaceAll('bucks', '').trim();
    }
    
    // 3. Category matching (very basic keyword matching)
    final categories = Provider.of<UserProvider>(context, listen: false).categories;
    for (var cat in categories) {
        if (note.toLowerCase().contains(cat.name.toLowerCase()) || 
            note.toLowerCase().contains(cat.id)) {
            categoryId = cat.id;
            break;
        }
    }

    setState(() {
      _parsedAmount = amount;
      _parsedNote = note.isEmpty ? 'Voice Entry' : note;
      _parsedCategory = categoryId;
    });
  }

  void _confirmTransaction() async {
    if (_parsedAmount == null || _parsedAmount! <= 0) return;

    final newTx = Transaction(
      title: _parsedNote ?? 'Voice Entry',
      amount: _parsedAmount!,
      date: DateTime.now(),
      categoryId: _parsedCategory ?? 'other',
      type: TransactionType.expense,
      mood: Mood.neutral,
      wallet: WalletType.upi,
    );

    await Provider.of<ExpenseProvider>(context, listen: false).addTransaction(newTx);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice Transaction Added! 🎙️')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final micButtonSize = screenWidth * 0.13;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Add 🎙️')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - screenWidth * 0.12),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Say something like:\n"50 rupees for Coffee"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    
                    // Microphone Button
                    GestureDetector(
                      onTapUp: (_) => _listen(),
                      child: AvatarGlow(
                        animate: _isListening,
                        glowColor: Theme.of(context).primaryColor,
                        duration: const Duration(milliseconds: 2000),
                        repeat: true,
                        child: CircleAvatar(
                          backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
                          radius: micButtonSize,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: micButtonSize * 0.8,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        _text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.055, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    if (_parsedAmount != null && _parsedAmount! > 0) ...[
                        SizedBox(height: screenHeight * 0.04),
                        const Divider(),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Parsed Expense', 
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle, 
                              color: Colors.green, 
                              size: screenWidth * 0.1,
                            ),
                            title: Text(
                              '₹${_parsedAmount!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Note: $_parsedNote'),
                            trailing: FilledButton(
                              onPressed: _confirmTransaction, 
                              child: const Text('Confirm'),
                            ),
                          ),
                        ),
                    ],
                    
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Simple AvatarGlow implementation if package not added, or replaced with simple animation container
class AvatarGlow extends StatelessWidget {
    final bool animate;
    final Color glowColor;
    final Duration duration;
    final bool repeat;
    final Widget child;
    
    const AvatarGlow({
        super.key, 
        required this.animate, 
        required this.glowColor, 
        this.duration = const Duration(milliseconds: 2000), 
        this.repeat = true, 
        required this.child
    });

    @override
    Widget build(BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        return Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: animate ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                    BoxShadow(
                        color: glowColor.withOpacity(0.5),
                        blurRadius: screenWidth * 0.05,
                        spreadRadius: screenWidth * 0.025,
                    )
                ]
            ) : null,
            child: child,
        );
    }
}
