import 'package:flutter/material.dart';
import '../../app.dart';
import 'onboarding_controller.dart';

class PolicyMissingPage extends StatelessWidget {
  const PolicyMissingPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final org = controller.selectedOrganization!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navy),
          onPressed: controller.back,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 64, color: orange),
            const SizedBox(height: 24),
            Text(
              'Official rules not configured yet for ${org.name}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy),
            ),
            const SizedBox(height: 16),
            const Text(
              'This organization hasn\'t published their official attendance rules yet. You can still follow them and set up your own personal tracking rules.',
              style: TextStyle(fontSize: 16, color: Color(0xFF667085), height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton(
                onPressed: controller.followWithPersonalSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Set My Own Rules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: OutlinedButton(
                onPressed: controller.back,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: navy, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Choose Another Organization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navy)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
