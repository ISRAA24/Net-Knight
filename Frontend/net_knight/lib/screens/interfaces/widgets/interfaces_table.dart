import 'package:flutter/material.dart';
import '../models/interface_model.dart';

const _kConnected = Color(0xFF22C55E);
const _kDisconnected = Color(0xFFEF4444);
const _kDark = Color(0xFF1D242B);

class InterfacesTable extends StatelessWidget {
  const InterfacesTable({
    super.key,
    required this.interfaces,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InterfaceModel> interfaces;
  final ValueChanged<InterfaceModel> onEdit;
  final ValueChanged<InterfaceModel> onDelete;

  static const _columnWidths = {
    0: FlexColumnWidth(2.5),
    1: FlexColumnWidth(3.5),
    2: FlexColumnWidth(2.5),
    3: FlexColumnWidth(3.5),
    4: FlexColumnWidth(2.0),
  };

  @override
  Widget build(BuildContext context) {
    if (interfaces.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No interfaces', style: TextStyle(color: Colors.black38)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDark, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Table(
          columnWidths: _columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder.symmetric(
            inside: BorderSide(color: Color(0xFFF0F0F0)),
          ),
          children: [
            _buildHeaderRow(),
            ...interfaces.map(_buildDataRow),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
      children: [
        _HeaderCell('Logical Name'),
        _HeaderCell('Real Interface Name'),
        _HeaderCell('Status'),
        _HeaderCell('IP Address'),
        _HeaderCell('Actions', align: TextAlign.center),
      ],
    );
  }

  TableRow _buildDataRow(InterfaceModel item) {
    final statusColor =
        item.status == 'connected' ? _kConnected : _kDisconnected;
    return TableRow(
      children: [
        _DataCell(item.logicalName),
        _DataCell(item.realName, color: const Color(0xFF4B5563)),
        _DataCell(item.status, color: statusColor),
        _DataCell(item.ip),
        _ActionsCell(
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(text,
          textAlign: align,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: _kDark)),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(text,
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? _kDark)),
    );
  }
}

class _ActionsCell extends StatelessWidget {
  const _ActionsCell({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconAction(icon: Icons.edit, onTap: onEdit),
          const SizedBox(width: 8),
          _IconAction(icon: Icons.delete, onTap: onDelete),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: _kDark),
      ),
    );
  }
}
