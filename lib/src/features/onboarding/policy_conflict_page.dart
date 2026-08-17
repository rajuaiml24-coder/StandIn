import 'package:flutter/material.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicyConflictPage extends StatelessWidget {
  const PolicyConflictPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.info_outline, size: 80, color: orange),
          const SizedBox(height: 24),
          Text(
            'Policy found for ${controller.selectedOrganization?.name ?? "this organization"}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy),
          ),
          const SizedBox(height: 12),
          const Text(
            'We found an official policy. Would you like to use it or keep your personal tracking settings?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton(
              onPressed: controller.useOfficialPolicy,
              style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Use Official Policy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: controller.keepPersonalSettings,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: navy, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Keep My Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navy)),
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}
