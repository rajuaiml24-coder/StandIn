import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app.dart';
import '../../domain/validators.dart';
import 'onboarding_controller.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  ValidationResult _nameValidation = const ValidationResult(null);
  ValidationResult _mobileValidation = const ValidationResult(null);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validate);
    _mobileController.addListener(_validate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _nameValidation = widget.controller.nameValidator.validate(_nameController.text);
      _mobileValidation = _mobileController.text.isEmpty 
          ? ValidationResult.valid 
          : widget.controller.mobileValidator.validate(_mobileController.text);
    });
  }

  bool get _canContinue => _nameValidation.isValid && _mobileValidation.isValid;

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
                      const Text(
                        'Basic Profile',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Help us personalize your attendance experience.',
                        style: TextStyle(color: Color(0xFF667085), fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _nameController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s']")),
                          LengthLimitingTextInputFormatter(50),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'e.g. John Doe',
                          errorText: _nameController.text.isNotEmpty ? _nameValidation.message : null,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '10-digit number',
                          errorText: _mobileController.text.isNotEmpty ? _mobileValidation.message : null,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          helperText: 'Required for account identity.',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _canContinue ? () => widget.controller.completeProfile(_nameController.text, _mobileController.text) : null,
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
