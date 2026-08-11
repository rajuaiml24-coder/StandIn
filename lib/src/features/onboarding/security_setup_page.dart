import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app.dart';
import '../../domain/validators.dart';
import 'onboarding_controller.dart';

class SecuritySetupPage extends StatefulWidget {
  const SecuritySetupPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<SecuritySetupPage> createState() => _SecuritySetupPageState();
}

class _SecuritySetupPageState extends State<SecuritySetupPage> {
  final _pinController = TextEditingController();
  bool _useBiometrics = false;
  ValidationResult _pinValidation = const ValidationResult(null);

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_validate);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _pinValidation = widget.controller.pinValidator.validate(_pinController.text);
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
                        'Security Setup',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your attendance stays private on this device.',
                        style: TextStyle(color: Color(0xFF667085), fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Create App PIN',
                          hintText: '4-digit PIN',
                          counterText: '',
                          errorText: _pinController.text.isNotEmpty && !_pinValidation.isValid 
                              ? _pinValidation.message 
                              : null,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('Use biometric unlock', style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                        subtitle: const Text('Fingerprint or Face unlock'),
                        value: _useBiometrics,
                        onChanged: (val) => setState(() => _useBiometrics = val),
                        activeTrackColor: orange.withValues(alpha: 0.5),
                        activeThumbColor: orange,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Spacer(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _pinValidation.isValid 
                              ? () => widget.controller.completeSecurity(_pinController.text, _useBiometrics)
                              : null,
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
