import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  const VirtualAquariumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AquariumScreen(),
    );
  }
}

// Fish class to store properties
class Fish {
  Offset position;
  double dx, dy; // Direction vectors
  Color color;
  double speed;

  Fish({
    required this.color,
    required this.speed,
    Offset? position,
  })  : position = position ?? Offset(150, 150),
        dx = (Random().nextDouble() - 0.5) * 2,
        dy = (Random().nextDouble() - 0.5) * 2;

  void changeDirection() {
    dx = (Random().nextDouble() - 0.5) * 2;
    dy = (Random().nextDouble() - 0.5) * 2;
  }
}

// Custom painter for fish shape
class FishPainter extends CustomPainter {
  final Color color;

  FishPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Fish body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 0), width: 20, height: 12),
      paint,
    );

    // Fish tail (triangle)
    final tailPath = Path()
      ..moveTo(10, 0)
      ..lineTo(20, -6)
      ..lineTo(20, 6)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Fish eye (small white circle with black dot)
    canvas.drawCircle(Offset(-5, -2), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(-5, -2), 1, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  State<AquariumScreen> createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Fish> fishList = [];
  double selectedSpeed = 1.0;
  Color selectedColor = Colors.blue;
  bool collisionEnabled = true;
  double fishScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _updateFishPositions();
        if (collisionEnabled) _checkCollisions();
        fishScale = fishList.isNotEmpty ? 1.0 : 1.0; // Reset scale after growth
      });
    });
  }

  void _updateFishPositions() {
    for (var fish in fishList) {
      fish.position = Offset(
        fish.position.dx + fish.dx * fish.speed,
        fish.position.dy + fish.dy * fish.speed,
      );

      // Bounce off edges
      if (fish.position.dx < 20 || fish.position.dx > 280) fish.dx = -fish.dx;
      if (fish.position.dy < 20 || fish.position.dy > 280) fish.dy = -fish.dy;
    }
  }

  void _checkCollisions() {
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        Fish fish1 = fishList[i];
        Fish fish2 = fishList[j];
        if ((fish1.position.dx - fish2.position.dx).abs() < 25 &&
            (fish1.position.dy - fish2.position.dy).abs() < 15) {
          fish1.changeDirection();
          fish2.changeDirection();
          fish1.color = Random().nextBool() ? Colors.blue : Colors.red;
          fish2.color = Random().nextBool() ? Colors.green : Colors.orange;
        }
      }
    }
  }

  void _addFish({bool animateScale = true}) {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
        if (animateScale) {
          fishScale = 1.5;
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => fishScale = 1.0);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              color: Colors.lightBlue[100],
            ),
            child: Stack(
              children: fishList
                  .map((fish) => Positioned(
                        left: fish.position.dx - 20,
                        top: fish.position.dy - 10,
                        child: Transform.scale(
                          scale: fishScale,
                          child: Transform.rotate(
                            angle: atan2(fish.dy, fish.dx),
                            child: CustomPaint(
                              painter: FishPainter(fish.color),
                              size: const Size(30, 20),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _addFish(),
                  child: const Text('Add Fish'),
                ),
                // Removed Save Settings button since there's no persistence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Speed:'),
                    Slider(
                      value: selectedSpeed,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (value) {
                        setState(() {
                          selectedSpeed = value;
                          for (var fish in fishList) {
                            fish.speed = value;
                          }
                        });
                      },
                    ),
                  ],
                ),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: [
                    DropdownMenuItem(value: Colors.blue, child: const Text('Blue')),
                    DropdownMenuItem(value: Colors.red, child: const Text('Red')),
                    DropdownMenuItem(value: Colors.green, child: const Text('Green')),
                    DropdownMenuItem(value: Colors.orange, child: const Text('Orange')),
                  ],
                  onChanged: (value) => setState(() => selectedColor = value!),
                ),
                SwitchListTile(
                  title: const Text('Collision Detection'),
                  value: collisionEnabled,
                  onChanged: (value) => setState(() => collisionEnabled = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}