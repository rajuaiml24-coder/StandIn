import 'package:flutter/material.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupSaturdayPage extends StatefulWidget {
  const PolicySetupSaturdayPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<PolicySetupSaturdayPage> createState() => _PolicySetupSaturdayPageState();
}

class _PolicySetupSaturdayPageState extends State<PolicySetupSaturdayPage> {
  int _choice = 0; // 0: Working, 1: Weekly Off, 2: Selected
  final List<int> _selectedSaturdays = [2, 4]; // Default 2nd & 4th

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white, 
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: navy), onPressed: widget.controller.back)
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How does Saturday\nwork?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
                    const SizedBox(height: 12),
                    const Text('Choose the behavior that matches your organization.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
                    const SizedBox(height: 32),
                    _choiceTile(0, 'Every Saturday is a working day'),
                    _choiceTile(1, 'Every Saturday is a weekly off'),
                    _choiceTile(2, 'Only selected Saturdays are off'),
                    
                    if (_choice == 2) ...[
                      const SizedBox(height: 24),
                      const Text('Which Saturdays are off?', style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                      const SizedBox(height: 12),
                      ...List.generate(5, (index) {
                        final satNum = index + 1;
                        final isSelected = _selectedSaturdays.contains(satNum);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text('${_ordinal(satNum)} Saturday'),
                          activeColor: navy,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSaturdays.add(satNum);
                              } else {
                                _selectedSaturdays.remove(satNum);
                              }
                            });
                          },
                        );
                      }),
                    ],
                    
                    const Spacer(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: () {
                          if (_choice == 0) {
                            widget.controller.selectSaturdayOption(false, specificSaturdays: []);
                          } else if (_choice == 1) {
                            widget.controller.selectSaturdayOption(true);
                          } else {
                            widget.controller.selectSaturdayOption(false, specificSaturdays: _selectedSaturdays);
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('Confirm and Start', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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

  Widget _choiceTile(int value, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: RadioListTile<int>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: _choice,
      title: Text(label, style: TextStyle(fontWeight: _choice == value ? FontWeight.w800 : FontWeight.w500, color: navy)),
      tileColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      activeColor: navy,
      // ignore: deprecated_member_use
      onChanged: (val) => setState(() => _choice = val!),
    ),
  );

  String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    4 => '4th',
    5 => '5th',
    _ => '$n'
  };
}
