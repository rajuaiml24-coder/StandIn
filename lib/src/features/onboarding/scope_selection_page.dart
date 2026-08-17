import 'package:flutter/material.dart';
import '../../app.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';

class ScopeSelectionPage extends StatefulWidget {
  const ScopeSelectionPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<ScopeSelectionPage> createState() => _ScopeSelectionPageState();
}

class _ScopeSelectionPageState extends State<ScopeSelectionPage> {
  final _controller = TextEditingController();
  List<Scope> _existing = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final parentId = widget.controller.step == OnboardingStep.scopeSemester 
        ? widget.controller.selectedBranch?.id 
        : null;
    final results = await widget.controller.getScopesForParent(parentId);
    if (mounted) setState(() { _existing = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isBranch = widget.controller.step == OnboardingStep.scopeBranch;
    final title = isBranch ? 'What\'s your branch?' : 'Which semester?';
    final label = isBranch ? 'Branch / Department' : 'Semester';
    final hint = isBranch ? 'e.g. CSE, ECE, Mechanical' : 'e.g. 3rd Sem, Fall 2024';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: navy), onPressed: widget.controller.back),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 8),
              Text('Pick from existing or add yours.', style: const TextStyle(color: Color(0xFF667085), fontSize: 16)),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: orange),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        if (isBranch) {
                          widget.controller.createBranch(_controller.text);
                        } else {
                          widget.controller.createSemester(_controller.text);
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('EXISTING', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
              const SizedBox(height: 12),
              if (_loading) 
                const Center(child: CircularProgressIndicator())
              else if (_existing.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No existing found. Create one above.', style: TextStyle(color: Color(0xFF98A2B3))),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _existing.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final scope = _existing[index];
                      return ListTile(
                        title: Text(scope.name, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        tileColor: const Color(0xFFF6F7FB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          if (isBranch) {
                            widget.controller.selectBranch(scope);
                          } else {
                            widget.controller.selectSemester(scope);
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (isBranch) {
                      widget.controller.selectBranch(null);
                    } else {
                      widget.controller.selectSemester(null);
                    }
                  },
                  child: Text(isBranch ? 'Skip Branch' : 'Skip Semester', style: const TextStyle(color: Color(0xFF667085))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
