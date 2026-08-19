import 'package:flutter/material.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicyConflictPage extends StatelessWidget {
  const PolicyConflictPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),
                    const Icon(Icons.info_outline, size: 80, color: orange),
                    const SizedBox(height: 24),
                    Text(
                      'Attendance Rules found for ${controller.selectedOrganization?.name ?? "this organization"}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We found official rules. Would you like to use them or keep your personal settings?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    if (controller.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(controller.error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: controller.isLoading ? null : controller.useOfficialPolicy,
                        style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: controller.isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Use Official Rules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: OutlinedButton(
                        onPressed: controller.isLoading ? null : controller.keepPersonalSettings,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: navy, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Keep My Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navy)),
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
