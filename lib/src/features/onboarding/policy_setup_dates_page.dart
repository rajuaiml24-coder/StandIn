import 'package:flutter/material.dart';
import '../../app.dart';
import 'onboarding_controller.dart';

class PolicySetupDatesPage extends StatefulWidget {
  const PolicySetupDatesPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<PolicySetupDatesPage> createState() => _PolicySetupDatesPageState();
}

class _PolicySetupDatesPageState extends State<PolicySetupDatesPage> {
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: navy), onPressed: widget.controller.back),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Academic Period', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 8),
            const Text('When does your semester start and end?', style: TextStyle(color: Color(0xFF667085), fontSize: 16)),
            const SizedBox(height: 40),
            _DateTile(
              label: 'Start Date', 
              date: _start, 
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setState(() => _start = d);
              }
            ),
            const SizedBox(height: 16),
            _DateTile(
              label: 'End Date', 
              date: _end, 
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _start?.add(const Duration(days: 90)) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setState(() => _end = d);
              }
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton(
                onPressed: (_start != null && _end != null) 
                    ? () => widget.controller.setDates(_start, _end)
                    : null,
                style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => widget.controller.setDates(null, null),
                child: const Text('Not sure / Add later', style: TextStyle(color: Color(0xFF667085))),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
          Text(
            date == null ? 'Select Date' : '${date!.day}/${date!.month}/${date!.year}',
            style: TextStyle(color: date == null ? Color(0xFF667085) : orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
