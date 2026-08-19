import 'package:flutter/material.dart';
import '../../app.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key, required this.controller});
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Image.asset('assets/brand/standin_logo.png', height: 28),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select how you want to track your attendance.',
                style: TextStyle(color: Color(0xFF667085), fontSize: 16),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                icon: Icons.school_rounded, 
                title: 'I am a student', 
                subtitle: 'Manage classes and credits',
                onTap: () => controller.start(AppRole.student),
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.business_center_rounded, 
                title: 'I am an employee', 
                subtitle: 'Track workdays and shifts',
                onTap: () => controller.start(AppRole.employee),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon, 
    required this.title, 
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon; 
  final String title; 
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) => Material(
    color: isPrimary ? navy : const Color(0xFFF6F7FB),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon, 
                color: isPrimary ? Colors.white : navy, 
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16,
                      color: isPrimary ? Colors.white : navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      fontSize: 13, 
                      color: isPrimary ? Colors.white70 : const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 16, 
              color: isPrimary ? Colors.white54 : navy.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    ),
  );
}
