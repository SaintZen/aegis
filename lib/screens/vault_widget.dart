import 'package:flutter/material.dart';

class VaultWidget extends StatefulWidget {
  const VaultWidget({super.key});

  @override
  State<VaultWidget> createState() => _VaultWidgetState();
}

class _VaultWidgetState extends State<VaultWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController doorController;
  late Animation<double> doorRotation;

  final TextEditingController worryController = TextEditingController();
  bool locked = false;

  @override
  void initState() {
    super.initState();

    doorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    doorRotation = Tween<double>(begin: 0, end: -1.2).animate(
      CurvedAnimation(
        parent: doorController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    doorController.dispose();
    worryController.dispose();
    super.dispose();
  }

  Future<void> lockWorry() async {
    if (worryController.text.trim().isEmpty) return;

    await doorController.forward();

    setState(() {
      locked = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    worryController.clear();
    doorController.reverse();

    setState(() {
      locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a18),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'The Vault',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Drag a worry into the Vault and lock it away.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: doorController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: doorRotation.value,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/vault_door_thumbnail.png',
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                controller: worryController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write your worry here...",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xff141428),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ElevatedButton(
                onPressed: lockWorry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Text(
                  locked ? 'Locked' : 'Lock in the Vault',
                  style: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
