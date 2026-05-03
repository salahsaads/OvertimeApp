import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/overtime_entry.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../theme.dart';

class RecordsScreen extends StatefulWidget {
  final List<OvertimeEntry> entries;
  final VoidCallback onRefresh;

  const RecordsScreen({
    super.key,
    required this.entries,
    required this.onRefresh,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  bool _isExporting = false;
  final _dateFormat = DateFormat('yyyy/MM/dd');

  double get _totalHours => widget.entries.fold(0, (sum, e) => sum + e.hours);
  double get _totalPay => widget.entries.fold(0, (sum, e) => sum + e.totalPay);

  Future<void> _exportPdf() async {
    if (widget.entries.isEmpty) {
      _showSnack('No records to export', AppTheme.warning);
      return;
    }
    setState(() => _isExporting = true);
    try {
      final fileName = await PdfService.generatePdf(widget.entries);
      setState(() => _isExporting = false);
      if (!mounted) return;
      _showSnack('PDF downloaded: $fileName', AppTheme.success);
    } catch (e) {
      setState(() => _isExporting = false);
      _showSnack('Export failed: $e', AppTheme.error);
    }
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await _showConfirmDialog(
      'Delete Entry', 'Are you sure you want to delete this record?', 'Delete', AppTheme.error);
    if (confirmed == true) {
      await StorageService.deleteEntry(id);
      widget.onRefresh();
    }
  }

  Future<void> _deleteAll() async {
    if (widget.entries.isEmpty) return;
    final confirmed = await _showConfirmDialog(
      'Delete All Records',
      'This will permanently delete all ${widget.entries.length} records.',
      'Delete All', AppTheme.error);
    if (confirmed == true) {
      await StorageService.deleteAll();
      widget.onRefresh();
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message, String actionLabel, Color actionColor) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(width: 4, height: 28,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              const Text('Overtime Records',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportPdf,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: widget.entries.isEmpty ? null : _deleteAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Delete All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats
          if (widget.entries.isNotEmpty) ...[
            Row(children: [
              _StatCard(label: 'Total Records', value: '${widget.entries.length}',
                  icon: Icons.list_alt_outlined, color: AppTheme.primary),
              const SizedBox(width: 12),
              _StatCard(label: 'Total Hours', value: '${_totalHours.toStringAsFixed(1)} hrs',
                  icon: Icons.access_time, color: AppTheme.accent),
              if (_totalPay > 0) ...[
                const SizedBox(width: 12),
                _StatCard(label: 'Total Pay', value: '\$${_totalPay.toStringAsFixed(2)}',
                    icon: Icons.attach_money, color: AppTheme.success),
              ],
            ]),
            const SizedBox(height: 20),
          ],

          // Table header
          if (widget.entries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: const Row(children: [
                Expanded(flex: 2, child: _TableHeaderCell('Start Date')),
                Expanded(flex: 2, child: _TableHeaderCell('End Date')),
                Expanded(flex: 1, child: _TableHeaderCell('Hours')),
                Expanded(flex: 3, child: _TableHeaderCell('Tasks')),
                Expanded(flex: 1, child: _TableHeaderCell('Pay')),
                SizedBox(width: 80, child: _TableHeaderCell('Actions')),
              ]),
            ),

          // List
          Expanded(
            child: widget.entries.isEmpty
                ? _EmptyState()
                : Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
                    child: ListView.separated(
                      itemCount: widget.entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                      itemBuilder: (ctx, i) => _EntryRow(
                        entry: widget.entries[i],
                        isEven: i % 2 == 0,
                        dateFormat: _dateFormat,
                        onDelete: () => _deleteEntry(widget.entries[i].id),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13));
}

class _EntryRow extends StatefulWidget {
  final OvertimeEntry entry;
  final bool isEven;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  const _EntryRow({required this.entry, required this.isEven, required this.dateFormat, required this.onDelete});
  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? AppTheme.primary.withOpacity(0.04) : widget.isEven ? AppTheme.cardBg : AppTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(flex: 2, child: Text(widget.dateFormat.format(widget.entry.startDate), style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(widget.dateFormat.format(widget.entry.endDate), style: const TextStyle(fontSize: 13))),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('${widget.entry.hours.toStringAsFixed(1)} h',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.center),
          )),
          Expanded(flex: 3, child: Text(widget.entry.tasks,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: widget.entry.totalPay > 0
              ? Text('\$${widget.entry.totalPay.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13))
              : const Text('—', style: TextStyle(color: AppTheme.textSecondary))),
          SizedBox(width: 80, child: IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error, tooltip: 'Delete',
            style: IconButton.styleFrom(hoverColor: AppTheme.error.withOpacity(0.1)),
          )),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.hourglass_empty_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
      const SizedBox(height: 16),
      const Text('No overtime records yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      const Text('Add your first entry using the form',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    ]),
  );
}
