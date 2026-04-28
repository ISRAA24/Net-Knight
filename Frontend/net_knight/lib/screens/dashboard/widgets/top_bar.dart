import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/nk_colors.dart';
import '../../../core/theme/nk_text_styles.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F2F2),
        border: Border(bottom: BorderSide(color: NKColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Statistics',
              style: NKTextStyles.heading.copyWith(fontSize: 22)),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.bell, size: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
