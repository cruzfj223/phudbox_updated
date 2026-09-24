import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navButton(context, 0, Icons.home_rounded),
          _navButton(context, 1, Icons.receipt_long_rounded),
          _navButton(context, 2, Icons.power_settings_new_rounded),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, int index, IconData icon) {
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.accent.withValues(alpha: 0.15) : AppColors.navyBg,
          border: Border.all(color: active ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Icon(icon, size: 20, color: active ? AppColors.accent : AppColors.textMuted),
      ),
    );
  }
}
