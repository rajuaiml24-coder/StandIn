import 'package:flutter/material.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupTargetPage extends StatefulWidget {
  const PolicySetupTargetPage({super.key, required this.controller});
  final OnboardingController controller;
  @override
  State<PolicySetupTargetPage> createState() => _PolicySetupTargetPageState();
}

class _PolicySetupTargetPageState extends State<PolicySetupTargetPage> {
  double _value = 75;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.controller.back)),
    body: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What is your\nattendance target?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
          const SizedBox(height: 12),
          const Text('Usually set by your organization (e.g., 75%).', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
          const SizedBox(height: 64),
          Center(
            child: Text(
              '${_value.toInt()}%',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: navy, letterSpacing: -2),
            ),
          ),
          Slider(
            value: _value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: orange,
            onChanged: (v) => setState(() => _value = v),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton(
              onPressed: () => widget.controller.setTarget(_value),
              style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => widget.controller.setTarget(null),
              child: const Text("I'm not sure / Set later", style: TextStyle(color: Color(0xFF667085))),
            ),
          ),
        ],
      ),
    ),
  );
}
