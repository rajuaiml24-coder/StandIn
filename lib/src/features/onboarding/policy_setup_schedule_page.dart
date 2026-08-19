import 'package:flutter/material.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupSchedulePage extends StatefulWidget {
  const PolicySetupSchedulePage({super.key, required this.controller});
  final OnboardingController controller;
  @override
  State<PolicySetupSchedulePage> createState() => _PolicySetupSchedulePageState();
}

class _PolicySetupSchedulePageState extends State<PolicySetupSchedulePage> {
  final _hoursController = TextEditingController(text: '8');
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 90));

  @override
  Widget build(BuildContext context) {
    final bool needsHours = widget.controller.basis == CalculationBasis.hours || widget.controller.basis == CalculationBasis.periods;
    final bool needsDates = widget.controller.evaluationPeriod == EvaluationPeriod.semester || 
                            widget.controller.evaluationPeriod == EvaluationPeriod.academicYear || 
                            widget.controller.evaluationPeriod == EvaluationPeriod.custom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: navy), onPressed: widget.controller.back)
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Final details', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)),
                      const SizedBox(height: 12),
                      const Text('Just a few more things to get your tracking started.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
                      const SizedBox(height: 32),
                      if (needsHours) ...[
                        Text(widget.controller.basis == CalculationBasis.hours ? 'Daily working hours' : 'Classes per day', 
                          style: const TextStyle(fontWeight: FontWeight.w700, color: navy)
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            hintText: 'e.g. 8',
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (needsDates) ...[
                        const Text('Period dates', style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                        const SizedBox(height: 12),
                        _DateTile(label: 'Start Date', date: _start, onTap: () => _pickDate(true)),
                        const SizedBox(height: 12),
                        _DateTile(label: 'End Date', date: _end, onTap: () => _pickDate(false)),
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      if (widget.controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(widget.controller.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: FilledButton(
                          onPressed: widget.controller.isLoading ? null : () {
                            final val = double.tryParse(_hoursController.text) ?? 1.0;
                            widget.controller.completeSchedule(
                              fullUnit: val,
                              start: needsDates ? _start : null,
                              end: needsDates ? _end : null,
                            );
                          },
                          style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: widget.controller.isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Complete Setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: isStart ? _start : _end, 
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030)
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
    subtitle: Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navy)),
    trailing: const Icon(Icons.calendar_month, color: navy),
    onTap: onTap,
  );
}
