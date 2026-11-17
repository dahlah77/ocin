import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Chip(
        avatar: Icon(positive ? Icons.check_circle_outline : Icons.info_outline,
            size: 18, color: positive ? Colors.teal : Colors.amber),
        label: Text(label),
      ),
    );
  }
}
