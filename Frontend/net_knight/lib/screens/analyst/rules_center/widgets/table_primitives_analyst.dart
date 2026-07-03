import 'package:flutter/material.dart';

// ─── Horizontal Divider (header) ─────────────────────────────
class THDAnalyst extends StatelessWidget {
  const THDAnalyst({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: Colors.black);
}

// ─── Vertical Divider (rows) ──────────────────────────────────
class VDAnalyst extends StatelessWidget {
  const VDAnalyst({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: Colors.black);
}

// ─── Table Header Cell ────────────────────────────────────────
class THAnalyst extends StatelessWidget {
  const THAnalyst(this.text, {super.key, required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
      );
}

// ─── Table Data Cell (text) ───────────────────────────────────
class TDAnalyst extends StatelessWidget {
  const TDAnalyst(
    this.text, {
    super.key,
    required this.flex,
    this.size = 15,
    this.color,
    this.bold = false,
  });

  final String text;
  final int flex;
  final double size;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ),
      );
}

// ─── Table Data Cell (widget) ─────────────────────────────────
class TDWidgetAnalyst extends StatelessWidget {
  const TDWidgetAnalyst({super.key, required this.flex, required this.child});
  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: child,
        ),
      );
}

// ─── Read-only Toggle ─────────────────────────────────────────
class ReadOnlyToggleAnalyst extends StatelessWidget {
  const ReadOnlyToggleAnalyst({super.key, required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.scale(
        scale: 0.9,
        child: Switch(
          value: enabled,
          onChanged: null,
          activeColor: Colors.white,
          activeTrackColor: Colors.black,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color.fromARGB(60, 0, 0, 0),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }
}