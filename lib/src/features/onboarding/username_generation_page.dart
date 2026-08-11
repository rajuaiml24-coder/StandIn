import 'package:flutter/material.dart';
import '../../app.dart';
import 'onboarding_controller.dart';

class UsernameGenerationPage extends StatelessWidget {
  const UsernameGenerationPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: navy),
        onPressed: controller.back,
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Identity',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We have generated a unique StandIn username for you.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 16),
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EBF1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.isCheckingUsername)
                      const CircularProgressIndicator(color: orange)
                    else
                      Text(
                        '@${controller.username ?? ""}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, color: Colors.blue, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Available & Unique',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: controller.isCheckingUsername 
                    ? null 
                    : controller.generateUsernameSuggestion,
                icon: const Icon(Icons.refresh_rounded, color: orange),
                label: const Text(
                  'Suggest another',
                  style: TextStyle(color: orange, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Username cannot be changed later.',
              style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: controller.isCheckingUsername ? null : controller.confirmUsername,
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Continue'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
