import 'package:flutter/material.dart';

class Senses54321Screen extends StatefulWidget {
  const Senses54321Screen({super.key});

  @override
  State<Senses54321Screen> createState() => _Senses54321ScreenState();
}

class _Senses54321ScreenState extends State<Senses54321Screen> {
  int _currentStep = 0;
  final List<String> _responses = ['', '', '', '', ''];
  
  final List<Map<String, dynamic>> _steps = [
    {
      'number': 5,
      'sense': 'See',
      'icon': Icons.visibility,
      'prompt': 'Name 5 things you can SEE around you',
      'hint': 'Look around and name 5 things you can see',
    },
    {
      'number': 4,
      'sense': 'Touch',
      'icon': Icons.touch_app,
      'prompt': 'Name 4 things you can TOUCH',
      'hint': 'Think of 4 things you can physically touch',
    },
    {
      'number': 3,
      'sense': 'Hear',
      'icon': Icons.hearing,
      'prompt': 'Name 3 things you can HEAR',
      'hint': 'Listen carefully and name 3 sounds',
    },
    {
      'number': 2,
      'sense': 'Smell',
      'icon': Icons.air,
      'prompt': 'Name 2 things you can SMELL',
      'hint': 'Take a deep breath and name 2 scents',
    },
    {
      'number': 1,
      'sense': 'Taste',
      'icon': Icons.restaurant,
      'prompt': 'Name 1 thing you can TASTE',
      'hint': 'Think of 1 thing you can taste right now',
    },
  ];

  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _textController.clear();
      });
    } else {
      _showCompletion();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _textController.text = _responses[_currentStep];
      });
    }
  }

  void _saveResponse() {
    _responses[_currentStep] = _textController.text;
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Grounding Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You\'ve successfully grounded yourself using all 5 senses. How are you feeling now?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('5-4-3-2-1 Senses'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  _steps.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Colors.amber
                            : Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Main content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large number
                      Text(
                        '${step['number']}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Icon
                      Icon(
                        step['icon'] as IconData,
                        color: Colors.amber,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      
                      // Sense name
                      Text(
                        step['sense'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Prompt
                      Text(
                        step['prompt'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Hint
                      Text(
                        step['hint'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Text input
                      TextField(
                        controller: _textController,
                        onChanged: (value) => _saveResponse(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your response here...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  
                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: Icon(_currentStep < _steps.length - 1
                        ? Icons.arrow_forward
                        : Icons.check),
                    label: Text(_currentStep < _steps.length - 1
                        ? 'Next'
                        : 'Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

