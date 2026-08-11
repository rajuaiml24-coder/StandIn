import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/development_repository.dart';
import 'domain/attendance.dart';
import 'domain/policy_engine.dart';
import 'domain/validators.dart';
import 'features/attendance/attendance_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/profile_setup_page.dart';
import 'features/onboarding/username_generation_page.dart';
import 'features/onboarding/security_setup_page.dart';
import 'features/onboarding/organization_create_page.dart';
import 'features/onboarding/organization_id_page.dart';
import 'features/onboarding/organization_search_page.dart';
import 'features/onboarding/policy_preview_page.dart';
import 'features/onboarding/role_selection_page.dart';
import 'platform/pwa_install_hint.dart';

const navy = Color(0xFF14213D);
const orange = Color(0xFFFF8A3D);
const background = Color(0xFFF6F7FB);

class StandInApp extends StatefulWidget {
  const StandInApp({super.key});
  @override
  State<StandInApp> createState() => _StandInAppState();
}

class _StandInAppState extends State<StandInApp> {
  late final AttendanceController attendanceController;
  final onboardingController = OnboardingController();
  
  @override
  void initState() {
    super.initState();
    attendanceController = AttendanceController(
      DevelopmentAttendanceRepository(),
      const PolicyEngine(),
      AttendancePolicy(id: 'demo-v1', version: 1, effectiveFrom: DateTime(2026, 8, 1), minimumPercent: 75, basis: CalculationBasis.hours, fullUnit: 7, halfUnit: 3.5),
    );
  }
  
  @override
  void dispose() { 
    attendanceController.dispose(); 
    onboardingController.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: onboardingController,
    builder: (context, _) {
      Widget home;
      switch (onboardingController.step) {
        case OnboardingStep.welcome:
          home = LandingLoginPage(controller: onboardingController);
          break;
        case OnboardingStep.roleSelection:
          home = RoleSelectionPage(controller: onboardingController);
          break;
        case OnboardingStep.profile:
          home = ProfileSetupPage(controller: onboardingController);
          break;
        case OnboardingStep.usernameGeneration:
          home = UsernameGenerationPage(controller: onboardingController);
          break;
        case OnboardingStep.security:
          home = SecuritySetupPage(controller: onboardingController);
          break;
        case OnboardingStep.organizationSearch:
          home = OrganizationSearchPage(controller: onboardingController);
          break;
        case OnboardingStep.organizationCreate:
          home = OrganizationCreatePage(controller: onboardingController);
          break;
        case OnboardingStep.organizationId:
          home = OrganizationIdPage(controller: onboardingController);
          break;
        case OnboardingStep.policyPreview:
          home = PolicyPreviewPage(controller: onboardingController);
          break;
        case OnboardingStep.complete:
          home = DashboardShell(
            controller: attendanceController,
            onLogout: onboardingController.logout,
          );
          break;
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true, 
          scaffoldBackgroundColor: background, 
          colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: orange), 
          cardTheme: const CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))))
        ),
        home: home,
      );
    }
  );
}

class LandingLoginPage extends StatefulWidget {
  const LandingLoginPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<LandingLoginPage> createState() => _LandingLoginPageState();
}

class _LandingLoginPageState extends State<LandingLoginPage> {
  final _userController = TextEditingController();
  final _pinController = TextEditingController();
  
  ValidationResult _usernameValidation = const ValidationResult(null);
  ValidationResult _pinValidation = const ValidationResult(null);

  @override
  void initState() {
    super.initState();
    _userController.addListener(_validate);
    _pinController.addListener(_validate);
  }

  @override
  void dispose() {
    _userController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _usernameValidation = widget.controller.usernameValidator.validate(_userController.text);
      _pinValidation = widget.controller.pinValidator.validate(_pinController.text);
    });
  }

  bool get _canSignIn => _usernameValidation.isValid && _pinValidation.isValid;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        // Decorative background elements
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orange.withValues(alpha: 0.04),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Column(
                        children: [
                          const Spacer(),
                          // Maximized Logo
                          Center(
                            child: Image.asset(
                              'assets/brand/standin_logo.png', 
                              height: 180, 
                              errorBuilder: (_, __, ___) => const Icon(Icons.how_to_reg, color: navy, size: 120),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'StandIn', 
                            style: TextStyle(
                              fontSize: 32, 
                              letterSpacing: -1.5,
                              fontWeight: FontWeight.w900, 
                              color: navy,
                            ),
                          ),
                          const Spacer(),
                          // Login Fields
                          TextField(
                            controller: _userController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r"[a-z0-9_.]")),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Username or ID',
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.person_outline, color: navy),
                              errorText: _userController.text.isNotEmpty && !_usernameValidation.isValid 
                                  ? _usernameValidation.message 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: '4-Digit PIN',
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.lock_outline, color: navy),
                              errorText: _pinController.text.isNotEmpty && !_pinValidation.isValid 
                                  ? _pinValidation.message 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: FilledButton(
                              onPressed: _canSignIn 
                                  ? () => widget.controller.login(_userController.text, _pinController.text) 
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: navy, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                              ),
                              child: const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _InstallHint(),
                          const Spacer(),
                          TextButton(
                            onPressed: widget.controller.goToSignup, 
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Color(0xFF667085), fontSize: 15),
                                children: [
                                  TextSpan(text: 'New user? '),
                                  TextSpan(
                                    text: 'Create Account', 
                                    style: TextStyle(color: orange, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
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
      ],
    ),
  );
}

class _InstallHint extends StatefulWidget {
  const _InstallHint();
  @override
  State<_InstallHint> createState() => _InstallHintState();
}

class _InstallHintState extends State<_InstallHint> {
  late final Future<String?> _message = PwaInstallHint.message();
  bool _dismissed = false;
  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _message,
    builder: (_, snapshot) {
      final message = snapshot.data;
      if (_dismissed || message == null) return const SizedBox.shrink();
      return Card(color: const Color(0xFFFFF4EC), child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(children: [const Icon(Icons.add_to_home_screen_outlined, color: navy), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: navy))), IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { PwaInstallHint.dismiss(); setState(() => _dismissed = true); })]),
      ));
    },
  );
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.controller, required this.onLogout});
  final AttendanceController controller;
  final VoidCallback onLogout;
  @override State<DashboardShell> createState() => _DashboardShellState();
}
class _DashboardShellState extends State<DashboardShell> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(controller: widget.controller), 
      CalendarPage(controller: widget.controller), 
      InsightPage(controller: widget.controller), 
      ProfilePage(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: SafeArea(child: screens[page]),
      floatingActionButton: page == 3 ? null : FloatingActionButton.extended(onPressed: () => showMarkAttendance(context, widget.controller), backgroundColor: orange, foregroundColor: Colors.white, icon: const Icon(Icons.add_task_outlined), label: const Text('Mark today')),
      bottomNavigationBar: NavigationBar(selectedIndex: page, onDestinationSelected: (value) => setState(() => page = value), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'), NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Insights'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile')]),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) {
      final summary = controller.summary;
      if (summary == null) return const Center(child: CircularProgressIndicator());
      final today = controller.recordFor(DateTime.now());
      return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 112), children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good afternoon', style: TextStyle(color: Color(0xFF667085), fontSize: 14)), SizedBox(height: 2), Text('Your attendance', style: TextStyle(fontSize: 26, letterSpacing: -.6, fontWeight: FontWeight.w800, color: navy))])),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.notifications_none_rounded, color: navy)),
        ]),
        const SizedBox(height: 10),
        const Row(children: [Icon(Icons.account_balance_outlined, size: 15, color: Color(0xFF667085)), SizedBox(width: 5), Text('StandIn demo', style: TextStyle(fontSize: 13, color: Color(0xFF667085))), SizedBox(width: 4), Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: Color(0xFF667085))]),
        const SizedBox(height: 20),
        _AttendanceHero(summary: summary, requiredPercent: controller.policy.minimumPercent),
        const SizedBox(height: 12),
        AdviceCard(summary: summary, policy: controller.policy),
        const SizedBox(height: 20),
        const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 9),
        _TodayCard(record: today, onTap: () => showMarkAttendance(context, controller)),
        const SizedBox(height: 22),
        const Text('Recent activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 9),
        ...controller.records.reversed.take(3).map((record) => _ActivityRow(record: record)),
        const SizedBox(height: 32),
        // Reserved Ad Slot
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EBF1)),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ads_click, color: Color(0xFF98A2B3), size: 20),
                SizedBox(height: 4),
                Text('Advertisement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF98A2B3))),
              ],
            ),
          ),
        ),
      ]);
    },
  );
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({required this.summary, required this.requiredPercent});
  final AttendanceSummary summary;
  final double requiredPercent;

  @override
  Widget build(BuildContext context) {
    final statusColor = summary.isSafe ? const Color(0xFF67E8A9) : const Color(0xFFFFC37B);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: navy, 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            SizedBox(width: 120, height: 120, child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: (summary.percent / 100).clamp(0, 1).toDouble(), 
                strokeWidth: 10, 
                strokeCap: StrokeCap.round,
                color: orange, 
                backgroundColor: Colors.white10
              ),
              Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${summary.percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 32, height: 1, color: Colors.white, fontWeight: FontWeight.w900)), 
                const SizedBox(height: 4), 
                const Text('CURRENT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white60, fontWeight: FontWeight.w700))
              ])),
            ])),
            const SizedBox(width: 24),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                decoration: BoxDecoration(color: statusColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)), 
                child: Text(
                  summary.isSafe ? '• ON TRACK' : '• ATTENTION NEEDED', 
                  style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w900, color: statusColor)
                )
              ),
              const SizedBox(height: 12),
              Text(
                summary.isSafe ? 'You are safe' : 'Time to recover', 
                style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w900)
              ),
              const SizedBox(height: 4),
              Text('Required: ${requiredPercent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white60, fontSize: 14)),
            ])),
          ]),
        ],
      ),
    );
  }
}

class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.summary, required this.policy});
  final AttendanceSummary summary;
  final AttendancePolicy policy;
  @override
  Widget build(BuildContext context) {
    final safe = summary.isSafe;
    final units = safe ? summary.safeToMiss : summary.unitsToRecover;
    final accent = safe ? const Color(0xFF16A34A) : orange;
    
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFE8EBF1), width: 1.5)
      ), 
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, 
          height: 48, 
          decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)), 
          child: Icon(safe ? Icons.shield_rounded : Icons.trending_up_rounded, color: accent, size: 26)
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            safe ? 'Your Safe Limit' : 'Your Recovery Plan', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: navy)
          ), 
          const SizedBox(height: 4), 
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF667085)),
              children: [
                TextSpan(text: safe ? 'You can miss ' : 'Attend the next '),
                TextSpan(
                  text: '${units.toStringAsFixed(1)}h', 
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800)
                ),
                TextSpan(text: safe ? ' and stay above ' : ' to reach '),
                TextSpan(
                  text: '${policy.minimumPercent.toStringAsFixed(0)}%', 
                  style: const TextStyle(color: navy, fontWeight: FontWeight.w800)
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ])),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.record, required this.onTap});
  final AttendanceRecord? record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final marked = record != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (marked ? Colors.green : orange).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  marked ? Icons.check_rounded : Icons.add_task_outlined,
                  color: marked ? Colors.green : orange,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marked ? statusText(record!.status) : 'No attendance recorded',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      marked
                          ? '${record!.actualUnits.toStringAsFixed(1)}h recorded today'
                          : 'Tap to mark your attendance',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              Text(
                marked ? 'Edit' : 'Mark',
                style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: statusColor(record.status).withValues(alpha: .11), shape: BoxShape.circle), child: Icon(statusIcon(record.status), size: 17, color: statusColor(record.status))),
    const SizedBox(width: 11), Expanded(child: Text('${record.date.day}/${record.date.month}/${record.date.year}', style: const TextStyle(fontWeight: FontWeight.w700, color: navy))), Text(statusText(record.status), style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
  ]));
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.controller});
  final AttendanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) {
    final now = DateTime.now(); final first = DateTime(now.year, now.month, 1); final offset = first.weekday % 7; final total = DateUtils.getDaysInMonth(now.year, now.month);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 112), children: [
      const Text('Calendar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 4), Text('${monthName(now.month)} ${now.year} - stored on this device', style: const TextStyle(color: Color(0xFF667085))), const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: offset + total, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemBuilder: (_, index) {
        if (index < offset) return const SizedBox();
        final date = DateTime(now.year, now.month, index - offset + 1); final record = controller.recordFor(date);
        return InkWell(onTap: () => showMarkAttendance(context, controller), child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: DateUtils.isSameDay(date, now) ? Border.all(color: navy, width: 2) : null, color: record == null ? Colors.transparent : statusColor(record.status).withValues(alpha: .12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${date.day}'), if (record != null) Icon(statusIcon(record.status), color: statusColor(record.status), size: 14)])));
      }))),
      const SizedBox(height: 18), const Wrap(spacing: 12, children: [Text('Green: full'), Text('Amber: partial'), Text('Red: absent'), Text('Blue: holiday')]),
    ]);
  });
}

class InsightPage extends StatelessWidget {
  const InsightPage({super.key, required this.controller}); final AttendanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) { final s = controller.summary; if (s == null) return const Center(child: CircularProgressIndicator()); return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 112), children: [const Text('Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 20), Row(children: [Metric(value: '${s.percent.toStringAsFixed(1)}%', label: 'Current'), const SizedBox(width: 12), Metric(value: '${controller.policy.minimumPercent.toStringAsFixed(0)}%', label: 'Required')]), const SizedBox(height: 14), AdviceCard(summary: s, policy: controller.policy), const SizedBox(height: 14), Card(child: ListTile(leading: const Icon(Icons.rule_outlined, color: navy), title: const Text('Current policy'), subtitle: Text('Hours - full day ${controller.policy.fullUnit.toStringAsFixed(0)}h - version ${controller.policy.version}')))]); });
}
class Metric extends StatelessWidget { const Metric({super.key, required this.value, required this.label}); final String value; final String label; @override Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)), Text(label, style: const TextStyle(color: Color(0xFF667085)))])))); }
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 20),
        const Card(child: ListTile(leading: CircleAvatar(backgroundColor: navy, child: Text('S', style: TextStyle(color: Colors.white))), title: Text('StandIn member'), subtitle: Text('Student - profile stored privately'))),
        const SizedBox(height: 16),
        const Card(
            child: Column(children: [
          ListTile(leading: Icon(Icons.account_balance_outlined), title: Text('StandIn demo'), subtitle: Text('Following - Policy v1')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.fingerprint), title: Text('Biometric unlock')),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.lock_outline), title: Text('Change PIN'))
        ])),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]);
}

Future<void> showMarkAttendance(BuildContext context, AttendanceController controller) {
  AttendanceStatus selected = AttendanceStatus.full; double hours = controller.policy.fullUnit;
  return showModalBottomSheet(
    context: context, 
    isScrollControlled: true, 
    showDragHandle: true, 
    builder: (sheet) => StatefulBuilder(
      builder: (_, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 28), 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Text('Mark attendance', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: navy)), 
              const SizedBox(height: 8), 
              const Text('Saved locally first. It will sync when you are online.'), 
              const SizedBox(height: 18), 
              Wrap(
                spacing: 8, 
                runSpacing: 8, 
                children: [
                  for (final status in [AttendanceStatus.full, AttendanceStatus.half, AttendanceStatus.partial, AttendanceStatus.absent, AttendanceStatus.holiday]) 
                    ChoiceChip(
                      label: Text(statusText(status)), 
                      selected: selected == status, 
                      onSelected: (_) => setSheet(() { 
                        selected = status; 
                        if (status == AttendanceStatus.full) hours = controller.policy.fullUnit; 
                        if (status == AttendanceStatus.half) hours = controller.policy.halfUnit; 
                      })
                    )
                ]
              ), 
              if (selected == AttendanceStatus.partial) 
                Slider(
                  value: hours, 
                  max: controller.policy.fullUnit, 
                  divisions: 14, 
                  activeColor: orange, 
                  onChanged: (value) => setSheet(() => hours = value)
                ), 
              const SizedBox(height: 12), 
              SizedBox(
                width: double.infinity, 
                child: FilledButton(
                  onPressed: () async { 
                    await controller.mark(selected, actualUnits: hours); 
                    if (sheet.mounted) Navigator.pop(sheet); 
                  }, 
                  style: FilledButton.styleFrom(backgroundColor: navy), 
                  child: const Text('Save attendance')
                )
              )
            ]
          ),
        )
      )
    )
  );
}

String statusText(AttendanceStatus status) => switch (status) { AttendanceStatus.full => 'Full', AttendanceStatus.half => 'Half day', AttendanceStatus.partial => 'Partial hours', AttendanceStatus.absent => 'Absent', AttendanceStatus.holiday => 'Holiday', AttendanceStatus.none => 'Not recorded' };
Color statusColor(AttendanceStatus status) => switch (status) { AttendanceStatus.full => Colors.green, AttendanceStatus.half || AttendanceStatus.partial => const Color(0xFFF59E0B), AttendanceStatus.absent => const Color(0xFFDC2626), AttendanceStatus.holiday => const Color(0xFF2563EB), AttendanceStatus.none => Colors.grey };
IconData statusIcon(AttendanceStatus status) => switch (status) { AttendanceStatus.full => Icons.check_rounded, AttendanceStatus.half || AttendanceStatus.partial => Icons.timelapse_rounded, AttendanceStatus.absent => Icons.close_rounded, AttendanceStatus.holiday => Icons.celebration_outlined, AttendanceStatus.none => Icons.remove_rounded };
String monthName(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];
