import 'package:flutter/material.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupBasisPage extends StatelessWidget {
  const PolicySetupBasisPage({super.key, required this.controller});
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What does attendance\nmean for you?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
              const SizedBox(height: 12),
              const Text('Choose how you want StandIn to count your attendance.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
              const SizedBox(height: 32),
              _BasisCard(
                title: 'Hours',
                subtitle: 'Track actual time spent (e.g. 8h per day)',
                icon: Icons.timer_outlined,
                onTap: () => controller.selectBasis(CalculationBasis.hours),
              ),
              const SizedBox(height: 16),
              _BasisCard(
                title: 'Days',
                subtitle: 'Simple present or absent tracking',
                icon: Icons.calendar_today_outlined,
                onTap: () => controller.selectBasis(CalculationBasis.days),
              ),
              const SizedBox(height: 16),
              _BasisCard(
                title: 'Classes / Periods',
                subtitle: 'Count individual sessions or lecture units',
                icon: Icons.school_outlined,
                onTap: () => controller.selectBasis(CalculationBasis.periods),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BasisCard extends StatelessWidget {
  const _BasisCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: navy)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    ),
  );
}
