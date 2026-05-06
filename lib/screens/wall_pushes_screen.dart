import 'package:flutter/material.dart';

class WallPushesScreen extends StatefulWidget {
  const WallPushesScreen({super.key});

  @override
  State<WallPushesScreen> createState() => _WallPushesScreenState();
}

class _WallPushesScreenState extends State<WallPushesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pushAnimation;
  bool _isPushing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pushAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startPush() {
    setState(() {
      _isPushing = true;
    });
    _animationController.repeat(reverse: true);
  }

  void _stopPush() {
    _animationController.stop();
    _animationController.reset();
    setState(() {
      _isPushing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Wall Pushes'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Find a wall and stand about 2 feet away from it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPushing
                        ? 'Push against the wall with your hands. Feel your strength!'
                        : 'Press "Start" when you\'re ready to begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Visual guide
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pushAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Wall representation
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey[600]!,
                                width: 4,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'WALL',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Person/hands pushing
                        Transform.translate(
                          offset: Offset(
                            -100 + (_pushAnimation.value * 30),
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Arms
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  Container(
                                    width: 60,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Hands
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Body
                              Container(
                                width: 60,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            // Control button
            Container(
              padding: const EdgeInsets.all(24),
              child: _isPushing
                  ? ElevatedButton.icon(
                      onPressed: _stopPush,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startPush,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Pushing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                    ),
            ),
            
            // Benefits text
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                'Feel your own strength. This exercise helps you reconnect with your physical body and provides immediate grounding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

