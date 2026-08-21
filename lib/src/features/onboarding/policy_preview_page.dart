import 'package:flutter/material.dart';
import '../../app.dart';
import 'onboarding_controller.dart';
import '../../domain/attendance.dart';
import 'package:intl/intl.dart';

class PolicyPreviewPage extends StatelessWidget {
  const PolicyPreviewPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final org = controller.selectedOrganization!;
        final officialPolicy = controller.officialPolicy;
        final calendar = controller.officialCalendar;

        // Effective rules to display (Inherited from org if available, otherwise defaults)
        final effectiveTarget = officialPolicy?.minimumPercent ?? 85.0;
        final effectiveBasis = officialPolicy?.basis ?? CalculationBasis.hours;
        final effectiveFullUnit = officialPolicy?.fullUnit ?? 8.0;
        final effectiveStartDate = officialPolicy?.startDate;
        final effectiveEndDate = officialPolicy?.endDate;

        return Scaffold(
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(org.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Official organization', style: TextStyle(color: navy.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: orange, size: 20),
                    const SizedBox(width: 8),
                    Text('${org.followerCount} ${org.followerCount == 1 ? "follower" : "followers"}', style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_outline, color: Color(0xFF667085), size: 18),
                    const SizedBox(width: 4),
                    Text('by ${org.anonymousCreatorId}', style: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Attendance Rules', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
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
                      _PolicyRow(label: 'Target', value: '${effectiveTarget.toStringAsFixed(0)}%'),
                      const Divider(height: 32),
                      _PolicyRow(label: 'Calculation basis', value: effectiveBasis.name.toUpperCase()),
                      const Divider(height: 32),
                      _PolicyRow(label: 'Working days', value: _getWorkingDays(officialPolicy, calendar)),
                      const Divider(height: 32),
                      _PolicyRow(label: 'Weekly off', value: _getWeeklyOff(officialPolicy, calendar)),
                      const Divider(height: 32),
                      _PolicyRow(label: 'Expected units', value: '${effectiveFullUnit.toStringAsFixed(1)} ${effectiveBasis.label(effectiveFullUnit)}/day'),
                      if (effectiveStartDate != null && effectiveEndDate != null) ...[
                        const Divider(height: 32),
                        _PolicyRow(label: 'Attendance period', value: _getPeriodText(effectiveStartDate, effectiveEndDate)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Your Tracking Period', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
                const SizedBox(height: 12),
                _PeriodSelection(controller: controller),
                const SizedBox(height: 48),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(controller.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: controller.isLoading ? null : controller.useOfficialPolicy,
                    style: FilledButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: controller.isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Follow This Organization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: OutlinedButton(
                    onPressed: controller.goToCreateOrganization,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: navy, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Create New Organization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navy)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWorkingDays(AttendancePolicy? policy, AttendanceCalendar? calendar) {
    final offs = calendar?.weeklyOffs ?? policy?.weeklyOffs ?? [7];
    if (offs.isEmpty) return 'Everyday';
    final days = [1, 2, 3, 4, 5, 6, 7];
    final working = days.where((d) => !offs.contains(d)).toList();
    if (working.length == 7) return 'Everyday';
    if (working.isEmpty) return 'None';
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (working.length > 3 && working.last - working.first == working.length - 1) {
      return '${dayNames[working.first - 1]} – ${dayNames[working.last - 1]}';
    }
    return working.map((d) => dayNames[d - 1]).join(', ');
  }

  String _getWeeklyOff(AttendancePolicy? policy, AttendanceCalendar? calendar) {
    final offs = calendar?.weeklyOffs ?? policy?.weeklyOffs ?? [7];
    if (offs.isEmpty) return 'None';
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return offs.map((d) => dayNames[d - 1]).join(', ');
  }

  String _getPeriodText(DateTime start, DateTime end) {
    final df = DateFormat('MMMM yyyy');
    return '${df.format(start)} – ${df.format(end)}';
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
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 16)),
    ],
  );
}

class _PeriodSelection extends StatelessWidget {
  const _PeriodSelection({required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final options = [
      EvaluationPeriod.monthly,
      EvaluationPeriod.quarterly,
      EvaluationPeriod.semester,
    ];

    return Column(
      children: options.map((period) {
        final isSelected = controller.evaluationPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => controller.selectPeriod(period),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? navy : const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? Colors.white : const Color(0xFF98A2B3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    period.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
