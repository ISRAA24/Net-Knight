import 'package:flutter/material.dart';

Widget buildDataTable({
  required List<String> headers,
  required List<List<String>> rows,
  required List<int> flexes,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: List.generate(headers.length, (i) => 
                Expanded(
                  flex: flexes[i],
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(headers[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ),
            ),
          ),
          ...rows.map((row) => Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: List.generate(row.length, (i) => 
                Expanded(flex: flexes[i], child: Text(row[i])),
              ),
            ),
          )),
        ],
      ),
    ),
  );
}