import 'package:flutter/material.dart';
import '../../app.dart';
import 'onboarding_controller.dart';

class PolicyPreviewPage extends StatelessWidget {
  const PolicyPreviewPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final org = controller.selectedOrganization!;
    final policy = controller.selectedPolicy!;

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
      body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)),
                      Text(org.branch ?? '', style: const TextStyle(color: Color(0xFF667085), fontSize: 16)),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ATTENDANCE POLICY', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
                          if (!org.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: orange)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _PolicyRow(label: 'Minimum Required', value: '${policy.minimumPercent.toStringAsFixed(0)}%'),
                            const Divider(height: 32),
                            _PolicyRow(label: 'Calculation Basis', value: policy.basis.name.toUpperCase()),
                            const Divider(height: 32),
                            _PolicyRow(label: 'Full Day', value: '${policy.fullUnit.toStringAsFixed(1)}h'),
                            const Divider(height: 32),
                            _PolicyRow(label: 'Half Day', value: '${policy.halfUnit.toStringAsFixed(1)}h'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(org.isVerified ? Icons.verified_user : Icons.info_outline, size: 16, color: org.isVerified ? Colors.blue : const Color(0xFF667085)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              org.isVerified 
                                  ? 'Official organization policy.' 
                                  : 'This is a draft policy. It will become official after verification.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: controller.followOrganization,
                          style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Follow Policy'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (org.isVerified)
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Report incorrect policy', style: TextStyle(color: Color(0xFF667085))),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF667085))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 18)),
    ],
  );
}
