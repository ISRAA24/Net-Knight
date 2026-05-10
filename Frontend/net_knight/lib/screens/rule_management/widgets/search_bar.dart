import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/nk_colors.dart';

class RuleSearchBar extends StatelessWidget {
  const RuleSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.totalRules,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int totalRules;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search rules by name, ip, or action.....',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                prefixIcon: const Icon(LucideIcons.search,
                    size: 15, color: Colors.black54),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: NKColors.blue, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2965C5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '$totalRules Rules',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}