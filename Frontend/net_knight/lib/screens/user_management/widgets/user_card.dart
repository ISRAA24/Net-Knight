import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    this.onDelete,
  });

  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(199, 0, 0, 0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ─── Avatar ───────────────────────────
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              user.initials,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),

          // ─── Info ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${user.role} — last login: ${user.login}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // ─── Edit ─────────────────────────────
          IconButton(
            icon:
                const Icon(LucideIcons.pencil, color: Colors.white70, size: 18),
            onPressed: onEdit,
          ),

          if (onDelete != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2,
                  color: Colors.white70, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
