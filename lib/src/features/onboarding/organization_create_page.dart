import 'package:flutter/material.dart';
import '../../app.dart';
import '../../domain/attendance.dart';
import '../../domain/validators.dart';
import 'onboarding_controller.dart';

class OrganizationCreatePage extends StatefulWidget {
  const OrganizationCreatePage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<OrganizationCreatePage> createState() => _OrganizationCreatePageState();
}

class _OrganizationCreatePageState extends State<OrganizationCreatePage> {
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _targetController = TextEditingController(text: '75');
  final _hoursController = TextEditingController(text: '7.0');

  ValidationResult _nameValidation = const ValidationResult(null);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _targetController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _nameValidation = widget.controller.orgNameValidator.validate(_nameController.text);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                        widget.controller.role == AppRole.student ? 'Add College' : 'Add Company',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: navy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Provide minimal details to start tracking.',
                        style: TextStyle(color: Color(0xFF667085), fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: widget.controller.role == AppRole.student ? 'College Name' : 'Company Name',
                          hintText: 'e.g. Stanford University',
                          errorText: _nameController.text.isNotEmpty ? _nameValidation.message : null,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _branchController,
                        decoration: const InputDecoration(
                          labelText: 'Branch / Campus (Optional)',
                          hintText: 'e.g. Main Campus',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _nameValidation.isValid ? () {
                            widget.controller.createOrganization(_nameController.text, _branchController.text, null);
                          } : null,
                          style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Continue'),
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
