import 'package:flutter/material.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupSaturdayPage extends StatelessWidget {
  const PolicySetupSaturdayPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white, 
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: navy), onPressed: controller.back)
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
                    const Text('How does Saturday\nwork?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
                    const SizedBox(height: 12),
                    const Text('Choose the pattern that matches your organization.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
                    const SizedBox(height: 32),
                    _PatternTile(label: 'Every Saturday Off', value: SaturdayPattern.everyOff, controller: controller),
                    _PatternTile(label: 'Every Saturday Working', value: SaturdayPattern.everyWorking, controller: controller),
                    _PatternTile(label: '1st & 3rd Saturday Off', value: SaturdayPattern.firstThirdOff, controller: controller),
                    _PatternTile(label: '2nd & 4th Saturday Off', value: SaturdayPattern.secondFourthOff, controller: controller),
                    _PatternTile(label: '1st, 3rd & 5th Saturday Off', value: SaturdayPattern.firstThirdFifthOff, controller: controller),
                    _PatternTile(label: '2nd, 4th & 5th Saturday Off', value: SaturdayPattern.secondFourthFifthOff, controller: controller),
                    const Spacer(),
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

class _PatternTile extends StatelessWidget {
  const _PatternTile({required this.label, required this.value, required this.controller});
  final String label;
  final SaturdayPattern value;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      tileColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
      onTap: () => controller.selectSaturdayPattern(value),
    ),
  );
}
