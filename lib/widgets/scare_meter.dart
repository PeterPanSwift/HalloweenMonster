import 'package:flutter/material.dart';

/// 以骷髏數量顯示恐怖指數。
class ScareMeter extends StatelessWidget {
  const ScareMeter({super.key, required this.level, this.size = 14});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Opacity(
            opacity: i < level ? 1 : 0.22,
            child: Text('💀', style: TextStyle(fontSize: size, height: 1.2)),
          ),
      ],
    );
  }
}
