import 'package:flutter/material.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupPeriodPage extends StatelessWidget {
  const PolicySetupPeriodPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: controller.back)),
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How often should we\nevaluate your attendance?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
          const SizedBox(height: 12),
          const Text('This defines your tracking period.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _PeriodTile(label: 'Monthly', value: EvaluationPeriod.monthly, controller: controller),
                _PeriodTile(label: 'Quarterly', value: EvaluationPeriod.quarterly, controller: controller),
                if (controller.role == AppRole.student) ...[
                  _PeriodTile(label: 'Semester', value: EvaluationPeriod.semester, controller: controller),
                  _PeriodTile(label: 'Academic Year', value: EvaluationPeriod.academicYear, controller: controller),
                ],
                _PeriodTile(label: 'Custom Range', value: EvaluationPeriod.custom, controller: controller),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.label, required this.value, required this.controller});
  final String label;
  final EvaluationPeriod value;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      tileColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
      onTap: () => controller.selectPeriod(value),
    ),
  );
}
