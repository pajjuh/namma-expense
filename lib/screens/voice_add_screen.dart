import 'dart:async';
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
  String? _matchedCategoryName;
  double _matchScore = 0.0;

  bool _speechEnabled = false;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }
  
  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             _stopListening();
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (e) {
      _speechEnabled = false;
    }
    
    if (mounted) {
      setState(() {});
      // Automatically start listening once initialized
      if (_speechEnabled && !_isListening) {
        _listen();
      }
    }
  }

  void _stopListening() {
    _silenceTimer?.cancel();
    if (!mounted || !_isListening) return;
    
    setState(() => _isListening = false);
    _speech.stop();
    
    if (_text.isNotEmpty && 
        _text != 'Press the mic and say something...' && 
        _text != 'Listening...') {
      _parseText(_text);
    }
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      _stopListening();
    });
  }

  void _listen() async {
    if (!_isListening) {
      if (!_speechEnabled) {
        // Try to re-initialize if it failed previously
        _initSpeech();
        if (!_speechEnabled) return;
      }
      
      // Clear previous parsed data before starting new recording
      setState(() {
        _isListening = true;
        _text = "Listening...";
        _parsedAmount = null;
        _parsedNote = null;
        _parsedCategory = null;
        _matchedCategoryName = null;
        _matchScore = 0.0;
      });
      
      // Start the fail-safe timer immediately in case they don't say anything
      _startSilenceTimer();
      
      _speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            });
            // Reset the silence timer every time a new word is recognized
            _startSilenceTimer();
          }
        },
        listenFor: const Duration(seconds: 30),
      );
    } else {
      _stopListening();
    }
  }

  void _parseText(String input) {
    final lowerInput = input.toLowerCase().trim();
    
    // ── 1. EXTRACT AMOUNT ──
    // Strip currency words first, then find numbers
    String cleaned = lowerInput
        .replaceAll('rupees', '')
        .replaceAll('rupee', '')
        .replaceAll('bucks', '')
        .replaceAll('rs', '')
        .replaceAll('₹', '')
        .trim();
    
    double amount = 0.0;
    final amountRegex = RegExp(r'(\d+(\.\d+)?)');
    final match = amountRegex.firstMatch(cleaned);
    if (match != null) {
      amount = double.tryParse(match.group(0)!) ?? 0.0;
    }

    // ── 2. EXTRACT CONTEXT WORDS ──
    // Remove noise words + the matched amount to get the "meaning" part
    final noiseWords = {'spent', 'spend', 'paid', 'pay', 'gave', 'give', 'bought', 'buy', 'got', 'get', 'rupees', 'rupee', 'rs', 'bucks', 'about', 'around', 'like', 'some', 'the', 'a', 'an', 'i', 'my', 'me', 'and', 'with'};
    final splitWords = {'on', 'for', 'at', 'in', 'to', 'from'};
    
    // Get all words, remove amount digits and noise
    List<String> words = cleaned.split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) => !RegExp(r'^\d+\.?\d*$').hasMatch(w))   // remove pure numbers
        .where((w) => !noiseWords.contains(w.toLowerCase()))   // remove noise words
        .toList();
    
    // Split into category hint and note using prepositions
    // e.g. "groceries for tomato" → category hint: "groceries", note: "tomato"
    // e.g. "on food for samosa" → category hint: "food", note: "samosa"
    String categoryHint = '';
    String noteHint = '';
    
    int splitIdx = -1;
    for (int i = 0; i < words.length; i++) {
      if (splitWords.contains(words[i].toLowerCase())) {
        splitIdx = i;
      }
    }
    
    if (splitIdx >= 0 && splitIdx < words.length - 1) {
      // Words before the LAST split word = category context
      // Words after = note context
      // But we need to handle "spent 300 on groceries for tomato"
      // Find first split word for category, last for note
      int firstSplit = words.indexWhere((w) => splitWords.contains(w.toLowerCase()));
      int lastSplit = words.lastIndexWhere((w) => splitWords.contains(w.toLowerCase()));
      
      if (firstSplit == lastSplit) {
        // Only one preposition: everything after it is the subject
        List<String> afterSplit = words.sublist(firstSplit + 1);
        categoryHint = afterSplit.join(' ');
        noteHint = afterSplit.join(' ');
      } else {
        // Multiple prepositions: first group = category, last group = note
        categoryHint = words.sublist(firstSplit + 1, lastSplit).join(' ');
        noteHint = words.sublist(lastSplit + 1).join(' ');
      }
    } else {
      // No prepositions found, use all remaining words
      categoryHint = words.join(' ');
      noteHint = words.join(' ');
    }
    
    // ── 3. FUZZY CATEGORY MATCHING ──
    final categories = Provider.of<UserProvider>(context, listen: false).categories;
    
    // Common spoken word → category keyword aliases
    final Map<String, List<String>> aliases = {
      'food': ['food', 'lunch', 'dinner', 'breakfast', 'meal', 'eat', 'eating', 'snack', 'snacks', 'biryani', 'rice', 'dosa', 'idli', 'samosa', 'pizza', 'burger', 'chicken', 'roti', 'chapati', 'thali', 'mess'],
      'grocery': ['grocery', 'groceries', 'vegetables', 'veggies', 'fruits', 'tomato', 'onion', 'potato', 'milk', 'curd', 'egg', 'eggs', 'bread', 'atta', 'dal', 'oil', 'sugar', 'salt', 'kirana'],
      'transport': ['transport', 'auto', 'cab', 'uber', 'ola', 'bus', 'train', 'metro', 'rickshaw', 'ride', 'commute', 'travel', 'petrol', 'diesel'],
      'fuel': ['fuel', 'petrol', 'diesel', 'gas', 'cng'],
      'recharge': ['recharge', 'mobile', 'phone', 'airtel', 'jio', 'vi', 'bsnl', 'wifi', 'internet', 'data'],
      'entertainment': ['fun', 'entertainment', 'movie', 'movies', 'cinema', 'game', 'games', 'gaming', 'netflix', 'spotify', 'youtube', 'party', 'outing'],
      'shopping': ['shopping', 'clothes', 'shoes', 'shirt', 'pants', 'dress', 'fashion', 'amazon', 'flipkart', 'myntra', 'online'],
      'bills': ['bill', 'bills', 'electricity', 'electric', 'water', 'rent', 'wifi', 'broadband', 'gas', 'cylinder', 'emi'],
      'medical': ['medical', 'medicine', 'doctor', 'hospital', 'pharmacy', 'tablet', 'health', 'gym', 'clinic'],
      'books': ['books', 'book', 'stationery', 'pen', 'notebook', 'study', 'course', 'subscription'],
      'education': ['school', 'education', 'tuition', 'fees', 'college', 'class', 'coaching'],
    };
    
    String bestCatId = 'other';
    double bestScore = 0.0;
    String bestCatName = 'Other';
    
    final hintWords = categoryHint.toLowerCase().split(RegExp(r'\s+'));
    
    for (var cat in categories) {
      double score = 0.0;
      
      // Direct name match (highest priority)
      double nameScore = _similarity(categoryHint.toLowerCase(), cat.name.toLowerCase());
      if (nameScore > score) score = nameScore;
      
      // Check each hint word against category name
      for (var word in hintWords) {
        if (word.isEmpty) continue;
        double wordScore = _similarity(word, cat.name.toLowerCase());
        if (wordScore > score) score = wordScore;
        
        // Also check against category ID
        double idScore = _similarity(word, cat.id.toLowerCase());
        if (idScore > score) score = idScore;
      }
      
      // Check against aliases
      if (aliases.containsKey(cat.id)) {
        for (var alias in aliases[cat.id]!) {
          for (var word in hintWords) {
            if (word.isEmpty) continue;
            double aliasScore = _similarity(word, alias);
            if (aliasScore > score) score = aliasScore;
          }
          // Also check full hint
          double fullAliasScore = _similarity(categoryHint.toLowerCase(), alias);
          if (fullAliasScore > score) score = fullAliasScore;
        }
      }
      
      // Check if any alias words appear in the FULL input (fallback)
      if (aliases.containsKey(cat.id)) {
        for (var alias in aliases[cat.id]!) {
          if (lowerInput.contains(alias) && alias.length >= 3) {
            double containsScore = 0.7; // base score for keyword presence
            if (containsScore > score) score = containsScore;
          }
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestCatId = cat.id;
        bestCatName = cat.name;
      }
    }
    
    // Only accept match if score >= 0.5 (50%), otherwise fall back to 'other'
    if (bestScore < 0.5) {
      bestCatId = 'other';
      bestCatName = 'Other';
      bestScore = 0;
    }
    
    // ── 4. SMART NOTE ──
    // Use the note hint if we extracted one, otherwise capitalize the category hint
    String finalNote = noteHint.isNotEmpty ? _capitalize(noteHint) : _capitalize(categoryHint);
    if (finalNote.isEmpty) finalNote = 'Voice Entry';
    
    setState(() {
      _parsedAmount = amount;
      _parsedNote = finalNote;
      _parsedCategory = bestCatId;
      _matchedCategoryName = bestCatName;
      _matchScore = bestScore;
    });
  }

  /// Levenshtein-based similarity score (0.0 to 1.0)
  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;
    
    // Check if one contains the other
    if (a.contains(b) || b.contains(a)) {
      return 0.85 + (0.15 * (a.length < b.length ? a.length / b.length : b.length / a.length));
    }
    
    // Check if one starts with the other (e.g., "grocer" matches "grocery")
    if (a.startsWith(b) || b.startsWith(a)) {
      int shorter = a.length < b.length ? a.length : b.length;
      int longer = a.length > b.length ? a.length : b.length;
      return 0.7 + (0.3 * shorter / longer);
    }
    
    // Levenshtein distance
    final int n = a.length, m = b.length;
    List<List<int>> dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost].reduce((a, b) => a < b ? a : b);
      }
    }
    int maxLen = n > m ? n : m;
    return 1.0 - (dp[n][m] / maxLen);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    
    // Find matched category object for display
    Category? matchedCat;
    if (_parsedCategory != null) {
      try {
        matchedCat = categories.firstWhere((c) => c.id == _parsedCategory);
      } catch (_) {}
    }
    
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
                      'Say something like:\n"Spent 300 on groceries for tomato"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                      ),
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
                        SizedBox(height: screenHeight * 0.03),
                        const Divider(),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Parsed Expense', 
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        
                        // ── Amount Card ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.currency_rupee, size: screenWidth * 0.07, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                '$currency${_parsedAmount!.toStringAsFixed(_parsedAmount! == _parsedAmount!.toInt().toDouble() ? 0 : 2)}',
                                style: TextStyle(fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        
                        // ── Category Card ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: (matchedCat?.color ?? Colors.grey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: (matchedCat?.color ?? Colors.grey).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              if (matchedCat != null) ...[
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: matchedCat.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: FaIcon(matchedCat.icon, color: matchedCat.color, size: 18)),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _matchedCategoryName ?? 'Other',
                                      style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
                                    ),
                                    if (_matchScore > 0)
                                      Text(
                                        'Match: ${(_matchScore * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: _matchScore >= 0.8 ? Colors.green : (_matchScore >= 0.6 ? Colors.orange : Colors.red),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Dropdown to override category
                              DropdownButton<String>(
                                value: _parsedCategory,
                                underline: const SizedBox(),
                                icon: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary),
                                items: categories.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, style: TextStyle(fontSize: screenWidth * 0.035)),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final cat = categories.firstWhere((c) => c.id == val);
                                    setState(() {
                                      _parsedCategory = val;
                                      _matchedCategoryName = cat.name;
                                      _matchScore = 1.0; // Manual selection = 100%
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        
                        // ── Note Card ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sticky_note_2_outlined, size: 20, color: Colors.grey.shade600),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  _parsedNote ?? 'Voice Entry',
                                  style: TextStyle(fontSize: screenWidth * 0.038, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        
                        // ── Confirm Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _confirmTransaction,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirm & Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
