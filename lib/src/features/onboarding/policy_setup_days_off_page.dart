import 'package:flutter/material.dart';
import 'onboarding_controller.dart';
import '../../app.dart';

class PolicySetupDaysOffPage extends StatefulWidget {
  const PolicySetupDaysOffPage({super.key, required this.controller});
  final OnboardingController controller;
  @override
  State<PolicySetupDaysOffPage> createState() => _PolicySetupDaysOffPageState();
}

class _PolicySetupDaysOffPageState extends State<PolicySetupDaysOffPage> {
  final List<int> _selected = [7]; // Default Sunday off selected

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
                    const Text('Which days are\nnormally off?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy, height: 1.2)),
                    const SizedBox(height: 12),
                    const Text('Select your regular weekly holidays.', style: TextStyle(fontSize: 15, color: Color(0xFF667085))),
                    const SizedBox(height: 32),
                    ...List.generate(7, (index) {
                      final dayNum = index + 1;
                      final isSelected = _selected.contains(dayNum);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CheckboxListTile(
                          value: isSelected,
                          title: Text(_days[index], style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: navy)),
                          tileColor: background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(dayNum);
                              } else {
                                _selected.remove(dayNum);
                              }
                            });
                          },
                        ),
                      );
                    }),
                    const Spacer(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: () => widget.controller.selectDaysOff(_selected),
                        style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => widget.controller.selectDaysOff([]), // All days working
                        child: const Text("All days are working", style: TextStyle(color: Color(0xFF667085))),
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
