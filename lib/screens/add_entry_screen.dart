import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/overtime_entry.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class AddEntryScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const AddEntryScreen({super.key, required this.onSaved});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursCtrl = TextEditingController();
  final _tasksCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  final _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _tasksCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date must be after start date');
      return;
    }

    setState(() => _isSaving = true);

    final entry = OvertimeEntry(
      id: const Uuid().v4(),
      startDate: _startDate!,
      endDate: _endDate!,
      hours: double.parse(_hoursCtrl.text),
      tasks: _tasksCtrl.text.trim(),
      hourlyRate: _rateCtrl.text.isNotEmpty
          ? double.tryParse(_rateCtrl.text)
          : null,
      createdAt: DateTime.now(),
    );

    await StorageService.saveEntry(entry);
    setState(() => _isSaving = false);

    widget.onSaved();
    _resetForm();
    _showSuccess();
  }

  void _resetForm() {
    _hoursCtrl.clear();
    _tasksCtrl.clear();
    _rateCtrl.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Entry saved successfully!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Overtime Entry',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'Start Date',
                            value: _startDate != null
                                ? _dateFormat.format(_startDate!)
                                : null,
                            icon: Icons.calendar_today_outlined,
                            onTap: () => _pickDate(true),
                            hasError: _startDate == null && _isSaving,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DatePickerField(
                            label: 'End Date',
                            value: _endDate != null
                                ? _dateFormat.format(_endDate!)
                                : null,
                            icon: Icons.event_outlined,
                            onTap: () => _pickDate(false),
                            hasError: _endDate == null && _isSaving,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hours & Rate row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hoursCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Overtime Hours',
                              hintText: 'e.g. 8.5',
                              prefixIcon: Icon(Icons.access_time,
                                  color: AppTheme.primary, size: 20),
                              suffixText: 'hrs',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Invalid hours';
                              if (n > 744) return 'Too many hours';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Hourly Rate (Optional)',
                              hintText: 'e.g. 25.00',
                              prefixIcon: Icon(Icons.attach_money,
                                  color: AppTheme.success, size: 20),
                              suffixText: '\$',
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final n = double.tryParse(v);
                                if (n == null || n < 0) return 'Invalid rate';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tasks
                    TextFormField(
                      controller: _tasksCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Tasks Completed',
                        hintText:
                            'Describe what you accomplished during overtime...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 72),
                          child: Icon(Icons.task_alt_outlined,
                              color: AppTheme.accent, size: 20),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please describe the tasks';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Preview card (shows when hours & rate filled)
                    if (_hoursCtrl.text.isNotEmpty &&
                        _rateCtrl.text.isNotEmpty) ...[
                      _PreviewCard(
                        hours: double.tryParse(_hoursCtrl.text) ?? 0,
                        rate: double.tryParse(_rateCtrl.text) ?? 0,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasError;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? AppTheme.error : AppTheme.border,
            width: hasError ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: value != null ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: value != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final double hours;
  final double rate;
  final DateTime? startDate;
  final DateTime? endDate;

  const _PreviewCard({
    required this.hours,
    required this.rate,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final total = hours * rate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _previewStat('Hours', '${hours.toStringAsFixed(1)} hrs'),
          _divider(),
          _previewStat('Rate', '\$${rate.toStringAsFixed(2)}/hr'),
          _divider(),
          _previewStat('Total Pay', '\$${total.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _previewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
