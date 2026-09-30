import 'package:flutter/material.dart';

// Helper widget to enforce consistent spacing and typography
// for the various data points in the inspection panel
class NeedRow extends StatelessWidget {
  final String label;
  final double value;

  const NeedRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            // Formats the raw double into a clean one-decimal string
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
