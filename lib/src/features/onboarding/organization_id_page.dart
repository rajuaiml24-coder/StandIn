import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app.dart';
import '../../domain/attendance.dart';
import '../../domain/validators.dart';
import 'onboarding_controller.dart';

class OrganizationIdPage extends StatefulWidget {
  const OrganizationIdPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<OrganizationIdPage> createState() => _OrganizationIdPageState();
}

class _OrganizationIdPageState extends State<OrganizationIdPage> {
  final _idController = TextEditingController();
  ValidationResult _idValidation = const ValidationResult(null);

  @override
  void initState() {
    super.initState();
    _idController.addListener(_validate);
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _idValidation = widget.controller.idValidator.validate(_idController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.controller.role == AppRole.student;
    final label = isStudent ? 'Roll Number' : 'Employee ID';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navy),
          onPressed: widget.controller.back,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset('assets/brand/standin_logo.png', height: 28),
          ),
        ],
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
                        Text(
                          'Identification',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: navy),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your $label to help link your future verified records.',
                          style: const TextStyle(color: Color(0xFF667085), fontSize: 16),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _idController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                            LengthLimitingTextInputFormatter(20),
                          ],
                          decoration: InputDecoration(
                            labelText: label,
                            hintText: isStudent ? 'e.g. 2024-CS-01' : 'e.g. EMP-102',
                            errorText: _idController.text.isNotEmpty ? _idValidation.message : null,
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            helperText: 'Your ID remains private on this device.',
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _idValidation.isValid 
                                ? () => widget.controller.completeOrganizationId(_idController.text)
                                : null,
                            style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Continue'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => widget.controller.completeOrganizationId('SKIPPED'), 
                            child: const Text('Skip for now', style: TextStyle(color: Color(0xFF667085))),
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
