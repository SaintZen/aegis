import 'package:flutter/material.dart';
import 'package:anxiety_anchor/models/exercise.dart';

class ExercisesListScreen extends StatelessWidget {
  const ExercisesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anxiety Exercises'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ExerciseData.exercises.length,
        itemBuilder: (context, index) {
          final exercise = ExerciseData.exercises[index];
          return _ExerciseCard(
            exercise: exercise,
            onTap: () {
              // Route to unified screen for all exercises
              Navigator.pushNamed(
                context,
                '/exercise-detail',
                arguments: exercise,
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      exercise.icon,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Text(
                      exercise.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                exercise.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              // Why in tab
              Text(
                exercise.whyInTab,
                style: TextStyle(
                  color: Colors.amber.withOpacity(0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

