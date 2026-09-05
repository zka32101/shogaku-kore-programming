import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/haptic_service.dart';

/// Animated sort/filter selection button
class SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SortButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPrimaryColor : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? kPrimaryColor : kTextSecondary,
          ),
        ),
      ),
    );
  }
}
