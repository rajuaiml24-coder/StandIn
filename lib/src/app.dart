import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data/auth/auth_service.dart';
import 'data/user_repository.dart';
import 'data/organization_repository.dart';
import 'data/remote/firestore_user_remote.dart';
import 'data/remote/firestore_org_remote.dart';
import 'data/local/standin_database.dart';
import 'domain/attendance.dart';
import 'domain/policy_engine.dart';
import 'features/attendance/attendance_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/profile_setup_page.dart';
import 'features/onboarding/username_generation_page.dart';
import 'features/onboarding/organization_create_page.dart';
import 'features/onboarding/organization_id_page.dart';
import 'features/onboarding/organization_search_page.dart';
import 'features/onboarding/policy_preview_page.dart';
import 'features/onboarding/policy_conflict_page.dart';
import 'features/onboarding/policy_setup_basis_page.dart';
import 'features/onboarding/policy_setup_period_page.dart';
import 'features/onboarding/policy_setup_target_page.dart';
import 'features/onboarding/policy_setup_schedule_page.dart';
import 'features/onboarding/policy_setup_days_off_page.dart';
import 'features/onboarding/policy_setup_saturday_page.dart';
import 'features/onboarding/policy_setup_dates_page.dart';
import 'features/onboarding/scope_selection_page.dart';
import 'features/onboarding/role_selection_page.dart';
import 'platform/pwa_service.dart';
import 'platform/pwa_install_hint.dart';
import 'data/sync/sync_engine.dart';
import 'data/remote/firestore_attendance_remote.dart';
import 'data/local_first_attendance_repository.dart';

const navy = Color(0xFF14213D);
const orange = Color(0xFFFF8A3D);
const background = Color(0xFFF6F7FB);

class UserSession {
  final String uid;
  final StandInDatabase database;
  final UserRepository userRepo;
  final OrganizationRepository orgRepo;
  final SyncEngine syncEngine;
  final OnboardingController onboardingController;

  UserSession({
    required this.uid,
    required this.database,
    required this.userRepo,
    required this.orgRepo,
    required this.syncEngine,
    required this.onboardingController,
  });

  Future<void> dispose({bool deleteLocalDatabase = false}) async {
    await syncEngine.stop();
    await database.close();
    onboardingController.dispose();

    if (deleteLocalDatabase) {
      // Deleting local database is platform specific. 
      // For now we assume closing is enough for session isolation, 
      // but a real implementation would use drift's file deletion if available.
      // However, StandIn's architecture uses unique DB names per UID, 
      // so even if the file remains, it's isolated.
    }
  }
}

class StandInApp extends StatefulWidget {
  const StandInApp({super.key});
  @override
  State<StandInApp> createState() => _StandInAppState();
}

class _StandInAppState extends State<StandInApp> {
  late final AuthService auth;
  UserSession? _session;
  StandInDatabase? _guestDb;
  late OnboardingController _landingController;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _authTask;
  
  @override
  void initState() {
    super.initState();
    
    const webClientId = '645644256889-fta4md48g87u4httj005egv22gf80j3g.apps.googleusercontent.com';
    
    auth = AuthService(
      FirebaseAuth.instance, 
      const FlutterSecureStorage(
        webOptions: WebOptions(dbName: 'standin_vault'),
      ),
      clientId: kIsWeb ? webClientId : null,
    );

    _initGuestState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_handleAuthState);
  }

  void _initGuestState() {
    // Exactly one guest database instance
    _guestDb = StandInDatabase('guest');
    
    // Share the same guest database across repositories
    _landingController = OnboardingController(
      authService: auth,
      userRepository: UserRepository(_guestDb!, FirestoreUserRemote(FirebaseFirestore.instance)),
      organizationRepository: OrganizationRepository(_guestDb!, FirestoreOrgRemote(FirebaseFirestore.instance)),
      attendanceRemote: FirestoreAttendanceRemote(FirebaseFirestore.instance),
    );
  }

  void _handleAuthState(User? user) {
    // Chain to existing task to ensure sequential processing
    // We use a local closure to capture the user at the time of the event
    _authTask = (_authTask ?? Future.value()).then((_) async {
      try {
        await _processAuthState(user);
      } catch (e) {
        debugPrint('Error processing auth state: $e');
      }
    });
  }

  Future<void> _processAuthState(User? user) async {
    if (user == null) {
      if (_session != null) {
        final oldSession = _session;
        setState(() => _session = null);
        await oldSession?.dispose();
        
        // Re-initialize guest state after authenticated session is fully closed
        if (mounted) {
          setState(() => _initGuestState());
        }
      }
    } else {
      // Strict UID check: Reuse existing session if UID hasn't changed
      if (_session?.uid == user.uid) return;

      // Close existing authenticated session if switching accounts
      if (_session != null) {
        final oldSession = _session;
        setState(() => _session = null);
        await oldSession?.dispose();
      }

      // Close guest database before opening authenticated one
      if (_guestDb != null) {
        _landingController.dispose();
        await _guestDb?.close();
        _guestDb = null;
      }

      final dbName = 'standin_${user.uid}';
      final database = StandInDatabase(dbName);
      final userRemote = FirestoreUserRemote(FirebaseFirestore.instance);
      final orgRemote = FirestoreOrgRemote(FirebaseFirestore.instance);
      final userRepo = UserRepository(database, userRemote);
      final orgRepo = OrganizationRepository(database, orgRemote);
      
      // Pre-fetch profile before setting session
      // This ensures build() doesn't see an empty local DB for returning users
      final hasProfile = await userRepo.syncProfile(user.uid);

      final syncEngine = SyncEngine(
        database, 
        FirestoreAttendanceRemote(FirebaseFirestore.instance),
        userRemote,
        orgRemote,
        orgRepo,
        uid: user.uid,
      );
      syncEngine.start();

      final onboardingController = OnboardingController(
        authService: auth,
        userRepository: userRepo,
        organizationRepository: orgRepo,
        attendanceRemote: FirestoreAttendanceRemote(FirebaseFirestore.instance),
        initialStep: hasProfile ? OnboardingStep.welcome : OnboardingStep.roleSelection,
      );

      if (mounted) {
        setState(() {
          _session = UserSession(
            uid: user.uid,
            database: database,
            userRepo: userRepo,
            orgRepo: orgRepo,
            syncEngine: syncEngine,
            onboardingController: onboardingController,
          );
        });
      }
    }
  }
  
  @override
  void dispose() { 
    _authSubscription?.cancel();
    _session?.dispose();
    _landingController.dispose();
    _guestDb?.close();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
             return _buildApp(const Scaffold(body: Center(child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 CircularProgressIndicator(),
                 SizedBox(height: 24),
                 Text('Restoring your session...', style: TextStyle(color: navy, fontWeight: FontWeight.w600)),
               ],
             ))));
          }
          return _buildApp(LandingLoginPage(controller: _landingController));
        },
      );
    }

    final session = _session!;

    return StreamBuilder<UserProfile?>(
      stream: session.userRepo.watchProfile(session.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;

        if (profile == null || profile.activeFollowId == null) {
          return ListenableBuilder(
            listenable: session.onboardingController,
            builder: (context, _) => _buildApp(_getOnboardingScreen(session.onboardingController.step, session.onboardingController)),
          );
        }

        return StreamBuilder<FollowRow?>(
          stream: session.database.watchFollow(profile.activeFollowId!),
          builder: (context, followSnapshot) {
            final followRow = followSnapshot.data;
            if (followRow == null) {
              return _buildApp(const Scaffold(body: Center(child: CircularProgressIndicator())));
            }

            return FutureBuilder<AttendancePolicy?>(
              future: session.orgRepo.getResolvedPolicy(
                uid: session.uid, 
                organizationId: followRow.organizationId, 
                scopeId: followRow.scopeId,
                followId: followRow.id,
              ),
              builder: (context, policySnapshot) {
                if (!policySnapshot.hasData) {
                  return _buildApp(const Scaffold(body: Center(child: CircularProgressIndicator())));
                }

                final policy = policySnapshot.data!;

                return FutureBuilder<AttendanceCalendar>(
                  future: session.orgRepo.getResolvedCalendar(
                    uid: session.uid, 
                    organizationId: followRow.organizationId, 
                    scopeId: followRow.scopeId,
                    followId: followRow.id,
                  ),
                  builder: (context, calendarSnapshot) {
                    if (!calendarSnapshot.hasData) {
                      return _buildApp(const Scaffold(body: Center(child: CircularProgressIndicator())));
                    }

                    final calendar = calendarSnapshot.data!;
                    return _buildApp(DashboardResolver(
                      session: session,
                      policy: policy,
                      calendar: calendar,
                      followRow: followRow,
                    ));
                  },
                );
              },
            );
          }
        );
      },
    );
  }

  Widget _buildApp(Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, 
      scaffoldBackgroundColor: background, 
      colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: orange), 
      cardTheme: CardThemeData(
        elevation: 0, 
        color: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    home: home,
  );

  Widget _getOnboardingScreen(OnboardingStep step, OnboardingController controller) {
    switch (step) {
      case OnboardingStep.welcome: return LandingLoginPage(controller: controller);
      case OnboardingStep.roleSelection: return RoleSelectionPage(controller: controller);
      case OnboardingStep.profile: return ProfileSetupPage(controller: controller);
      case OnboardingStep.usernameGeneration: return UsernameGenerationPage(controller: controller);
      case OnboardingStep.organizationSearch: return OrganizationSearchPage(controller: controller);
      case OnboardingStep.organizationCreate: return OrganizationCreatePage(controller: controller);
      case OnboardingStep.organizationId: return OrganizationIdPage(controller: controller);
      case OnboardingStep.policyDetection: return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case OnboardingStep.policyPreview: return PolicyPreviewPage(controller: controller);
      case OnboardingStep.policyConflict: return PolicyConflictPage(controller: controller);
      case OnboardingStep.setupUnit: return PolicySetupBasisPage(controller: controller);
      case OnboardingStep.setupPeriod: return PolicySetupPeriodPage(controller: controller);
      case OnboardingStep.setupTarget: return PolicySetupTargetPage(controller: controller);
      case OnboardingStep.scopeBranch: return ScopeSelectionPage(controller: controller);
      case OnboardingStep.scopeSemester: return ScopeSelectionPage(controller: controller);
      case OnboardingStep.setupDates: return PolicySetupDatesPage(controller: controller);
      case OnboardingStep.setupSchedule: return PolicySetupSchedulePage(controller: controller);
      case OnboardingStep.setupDaysOff: return PolicySetupDaysOffPage(controller: controller);
      case OnboardingStep.setupSaturday: return PolicySetupSaturdayPage(controller: controller);
      case OnboardingStep.complete: return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}

class DashboardResolver extends StatefulWidget {
  const DashboardResolver({
    super.key,
    required this.session,
    required this.policy,
    required this.calendar,
    required this.followRow,
  });
  final UserSession session;
  final AttendancePolicy policy;
  final AttendanceCalendar calendar;
  final FollowRow followRow;

  @override
  State<DashboardResolver> createState() => _DashboardResolverState();
}

class _DashboardResolverState extends State<DashboardResolver> {
  late AttendanceController controller;
  late LocalFirstAttendanceRepository repository;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(DashboardResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policy.id != widget.policy.id || oldWidget.calendar.id != widget.calendar.id || oldWidget.session.uid != widget.session.uid) {
      controller.dispose();
      _initController();
    }
  }

  void _initController() {
    repository = LocalFirstAttendanceRepository(
      widget.session.database,
      uid: widget.session.uid,
      organizationId: widget.policy.organizationId ?? 'unknown',
      scopeId: widget.policy.scopeId ?? 'global',
    );
    controller = AttendanceController(repository, const PolicyEngine(), widget.policy, widget.calendar);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DashboardShell(
    session: widget.session,
    controller: controller,
    policy: widget.policy,
    calendar: widget.calendar,
    followRow: widget.followRow,
  );
}

class LandingLoginPage extends StatefulWidget {
  const LandingLoginPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<LandingLoginPage> createState() => _LandingLoginPageState();
}

class _LandingLoginPageState extends State<LandingLoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Column(
                        children: [
                          const Spacer(),
                          Center(
                            child: Image.asset(
                              'assets/brand/standin_logo.png', 
                              height: 180, 
                              errorBuilder: (_, __, ___) => const Icon(Icons.how_to_reg, color: navy, size: 120),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Workday & Attendance Safety Planner',
                            style: TextStyle(
                              fontSize: 20,
                              letterSpacing: -1,
                              fontWeight: FontWeight.w400,
                              color: navy,
                            ),
                          ),
                          const Text(
                            'by WithWells Technologies',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Color(0xFF667085), fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          
                          if (widget.controller.authError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                widget.controller.authError!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: FilledButton(
                              onPressed: widget.controller.isAuthenticating ? null : widget.controller.signInWithGoogle,
                              style: FilledButton.styleFrom(
                                backgroundColor: navy, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                              ),
                              child: widget.controller.isAuthenticating
                                ? RotationTransition(
                                    turns: _rotationController,
                                    child: Image.asset('assets/brand/standin_loading_icon.png', height: 28),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Continue with Google', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _InstallHint(),
                          const Spacer(),
                          const Text(
                            'By continuing, you agree to our Terms of Service',
                            style: TextStyle(fontSize: 11, color: Color(0xFF98A2B3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
  const DashboardShell({
    super.key, 
    required this.session,
    required this.controller, 
    required this.policy,
    required this.calendar,
    required this.followRow,
  });
  final UserSession session;
  final AttendanceController controller;
  final AttendancePolicy policy;
  final AttendanceCalendar calendar;
  final FollowRow followRow;
  @override State<DashboardShell> createState() => _DashboardShellState();
}
class _DashboardShellState extends State<DashboardShell> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(controller: widget.controller, onNavigateToCalendar: () => setState(() => page = 1)), 
      CalendarPage(controller: widget.controller), 
      ProfilePage(
        session: widget.session,
        policy: widget.policy,
        calendar: widget.calendar,
        follow: widget.followRow,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: screens[page]),
      floatingActionButton: (page == 1 || page == 2) ? null : FloatingActionButton.extended(
        onPressed: () => showMarkAttendance(context, widget.controller), 
        backgroundColor: orange, 
        foregroundColor: Colors.white, 
        icon: const Icon(Icons.add_task_outlined), 
        label: const Text('Mark today'),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlobalAdBanner(),
          NavigationBar(
            selectedIndex: page, 
            onDestinationSelected: (value) => setState(() => page = value), 
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), 
              NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'), 
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile')
            ],
          ),
        ],
      ),
    );
  }
}

class GlobalAdBanner extends StatelessWidget {
  const GlobalAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        border: Border(
          top: BorderSide(color: Color(0xFFE8EBF1)),
          bottom: BorderSide(color: Color(0xFFE8EBF1)),
        ),
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
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller, required this.onNavigateToCalendar});
  final AttendanceController controller;
  final VoidCallback onNavigateToCalendar;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showInstallPrompt = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: PwaService.instance.installAvailable,
      initialData: PwaService.instance.isAvailable,
      builder: (context, snapshot) {
        final canInstall = snapshot.data ?? false;
        final isInstalled = PwaService.instance.isInstalled();
        final showBanner = _showInstallPrompt && canInstall && !isInstalled;

        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, __) {
            final summary = widget.controller.summary;
            if (summary == null) return const Center(child: CircularProgressIndicator());
            final today = widget.controller.recordFor(DateTime.now());

            return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 80), children: [
              if (showBanner) ...[
                _InstallPwaCard(
                  onInstall: () => PwaService.instance.promptInstall(),
                  onDismiss: () => setState(() => _showInstallPrompt = false),
                ),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(summary.periodLabel, style: const TextStyle(color: Color(0xFF667085), fontSize: 14, fontWeight: FontWeight.w600)), 
                  const SizedBox(height: 2), 
                  Text(summary.isSafe ? 'You are safe' : 'Attention needed', 
                    style: const TextStyle(fontSize: 26, letterSpacing: -.6, fontWeight: FontWeight.w800, color: navy)
                  )
                ])),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.notifications_none_rounded, color: navy)),
              ]),
              const SizedBox(height: 20),
              _AttendanceHero(summary: summary, policy: widget.controller.policy),
              const SizedBox(height: 12),
              if (summary.needsAttention)
                _AttentionRequiredCard(count: summary.unmarkedCount, onTap: widget.onNavigateToCalendar),
              if (!summary.isPolicyIncomplete)
                AdviceCard(summary: summary, policy: widget.controller.policy),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
                  TextButton(
                    onPressed: widget.onNavigateToCalendar, 
                    child: const Row(children: [
                      Text('View Calendar', style: TextStyle(color: orange, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: orange),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _TodayCard(record: today, policy: widget.controller.policy, onTap: () => showMarkAttendance(context, widget.controller)),
              const SizedBox(height: 24),
              const Text('Recent activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 9),
              ...widget.controller.records.reversed.take(3).map((record) => _ActivityRow(record: record)),
            ]);
          },
        );
      },
    );
  }
}

class _AttentionRequiredCard extends StatelessWidget {
  const _AttentionRequiredCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20), 
    decoration: BoxDecoration(color: const Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: orange),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance needs attention', style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 15)),
          Text('$count working days are not marked yet.', style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
        ],
      )),
      TextButton(onPressed: onTap, child: const Text('Review'))
    ]),
  );
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({required this.summary, required this.policy});
  final AttendanceSummary summary;
  final AttendancePolicy policy;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (summary.status) {
      PeriodStatus.onTrack => const Color(0xFF16A34A),
      PeriodStatus.atRisk => const Color(0xFFF59E0B),
      PeriodStatus.impossible => const Color(0xFFDC2626),
    };

    final statusLabel = switch (summary.status) {
      PeriodStatus.onTrack => "YOU'RE ON TRACK",
      PeriodStatus.atRisk => "ATTENTION NEEDED",
      PeriodStatus.impossible => "TARGET UNREACHABLE",
    };

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
            decoration: BoxDecoration(color: statusColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)), 
            child: Text(
              statusLabel, 
              style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: statusColor)
            )
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(width: 90, height: 90, child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(
                  value: (summary.percent / 100).clamp(0, 1).toDouble(), 
                  strokeWidth: 8, 
                  strokeCap: StrokeCap.round,
                  color: summary.status == PeriodStatus.onTrack ? const Color(0xFF16A34A) : orange, 
                  backgroundColor: Colors.white10
                ),
                Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '${summary.percent.toStringAsFixed(0)}%', 
                    style: const TextStyle(fontSize: 22, height: 1, color: Colors.white, fontWeight: FontWeight.w900)
                  ), 
                  const Text(
                    'CURRENT', 
                    style: TextStyle(fontSize: 8, letterSpacing: 0.5, color: Colors.white60, fontWeight: FontWeight.w700)
                  )
                ])),
              ])),
              const SizedBox(width: 24),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  summary.attendedLabel, 
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                ),
                const SizedBox(height: 4),
                Text(summary.conductedLabel, style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
              ])),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('${summary.periodLabel} • Target: ${policy.minimumPercent?.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                const Icon(Icons.info_outline, color: Colors.white38, size: 14),
              ],
            ),
          )
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
    final status = summary.status;
    
    final Color accent = switch (status) {
      PeriodStatus.onTrack => const Color(0xFF16A34A),
      PeriodStatus.atRisk => orange,
      PeriodStatus.impossible => const Color(0xFFDC2626),
    };

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
          child: Icon(
            status == PeriodStatus.impossible ? Icons.error_outline_rounded : (status == PeriodStatus.onTrack ? Icons.shield_rounded : Icons.trending_up_rounded), 
            color: accent, 
            size: 26
          )
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            status == PeriodStatus.impossible ? 'Attendance Goal Unachievable' : (status == PeriodStatus.onTrack ? 'Your Safe Limit' : 'Attendance Recovery Plan'), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: navy)
          ), 
          const SizedBox(height: 4), 
          Text(
            summary.recoveryMessage,
            style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF667085)),
          ),
        ])),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.record, required this.policy, required this.onTap});
  final AttendanceRecord? record;
  final AttendancePolicy policy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final marked = record != null;
    final unitLabel = policy.basis == CalculationBasis.hours ? 'h' : ' ${policy.basis.label(marked ? record!.expectedUnits : policy.fullUnit)}';
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (marked ? (record!.status == AttendanceStatus.absent ? Colors.red : Colors.green) : orange).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  marked ? statusIcon(record!.status) : Icons.add_task_outlined,
                  color: marked ? (record!.status == AttendanceStatus.absent ? Colors.red : Colors.green) : orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marked ? statusText(record!.status) : 'No attendance recorded',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      marked
                          ? '${record!.actualUnits.toStringAsFixed(1)} / ${record!.expectedUnits.toStringAsFixed(1)}$unitLabel today'
                          : 'Tap to mark your attendance',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w800, color: navy),
              ),
              const SizedBox(width: 4),
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

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.controller});
  final AttendanceController controller;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late PageController _pageController;
  late DateTime _baseDate;
  int _currentPage = 0;
  static const int _initialPage = 1200; // 100 years of range

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, 1);
    _pageController = PageController(initialPage: _initialPage);
    _currentPage = _initialPage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int page) {
    final monthsOffset = page - _initialPage;
    return DateTime(_baseDate.year, _baseDate.month + monthsOffset, 1);
  }

  @override
  Widget build(BuildContext context) {
    final viewMonth = _dateForPage(_currentPage);
    final now = DateTime.now();

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final monthlySummary = widget.controller.getMonthlySummary(viewMonth.year, viewMonth.month);
        final hasAttendance = monthlySummary.periodLabel != 'Attendance not marked' && monthlySummary.periodLabel != 'Not started';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monthName(viewMonth.month)} ${viewMonth.year}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: navy, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 4),
                  if (hasAttendance)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${monthlySummary.percent.toStringAsFixed(1)}% attendance', 
                            style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(monthlySummary.periodLabel, style: const TextStyle(color: Color(0xFF98A2B3), fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, page) {
                  final date = _dateForPage(page);
                  return _MonthGrid(
                    controller: widget.controller,
                    viewMonth: date,
                    now: now,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.controller,
    required this.viewMonth,
    required this.now,
  });

  final AttendanceController controller;
  final DateTime viewMonth;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final offset = viewMonth.weekday - 1;
    final total = DateUtils.getDaysInMonth(viewMonth.year, viewMonth.month);
    final calendar = controller.calendar;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel('Mon'), _WeekdayLabel('Tue'), _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'), _WeekdayLabel('Fri'), _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offset + total,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, index) {
              if (index < offset) return const SizedBox();
              final date = DateTime(viewMonth.year, viewMonth.month, index - offset + 1);
              final record = controller.recordFor(date);
              final isToday = DateUtils.isSameDay(date, now);
              final isHoliday = calendar.holidays.any((h) => DateUtils.isSameDay(h.date, date));
              final isWeeklyOff = !isHoliday && calendar.isNonWorkingDay(date);
              final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

              final statusCol = record != null ? statusColor(record.status) : null;

              return InkWell(
                onTap: isFuture ? null : () => showMarkAttendance(context, controller, date: date),
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: isFuture ? 0.3 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isToday ? Border.all(color: navy.withValues(alpha: 0.2), width: 1.5) : null,
                      color: record != null
                          ? statusCol!.withValues(alpha: 0.12)
                          : (isHoliday ? orange.withValues(alpha: 0.08) : (isWeeklyOff ? const Color(0xFFF0F2F5) : Colors.transparent)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isToday)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${date.day}', style: TextStyle(
                              fontSize: 17,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                              color: (isHoliday || isWeeklyOff) && record == null ? const Color(0xFF98A2B3) : navy,
                            )),
                            if (record != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(statusIcon(record.status), color: statusCol, size: 12),
                              )
                            else if (isHoliday)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.celebration, color: orange, size: 10),
                              )
                            else if (isWeeklyOff)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.weekend, color: Color(0xFF98A2B3), size: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _LegendItem(label: 'Full', icon: Icons.check_circle, color: Colors.green),
              _LegendItem(label: 'Half', icon: Icons.timelapse, color: Color(0xFFF59E0B)),
              _LegendItem(label: 'Absent', icon: Icons.cancel, color: Color(0xFFDC2626)),
              _LegendItem(label: 'Holiday / Off', icon: Icons.celebration, color: Color(0xFF98A2B3)),
            ],
          ),
          if (!calendar.isConfigured) _HolidayWarningCard(),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF667085))),
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
  ]);
}

class _HolidayWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      const Icon(Icons.calendar_today_outlined, color: orange),
      const SizedBox(width: 12),
      const Expanded(child: Text('Working Days & Holidays not configured for this organization.', style: TextStyle(color: navy, fontSize: 13, fontWeight: FontWeight.w600))),
      TextButton(onPressed: () {}, child: const Text('Add'))
    ]),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key, 
    required this.session,
    required this.policy,
    required this.calendar,
    required this.follow,
  });
  final UserSession session;
  final AttendancePolicy policy;
  final AttendanceCalendar calendar;
  final FollowRow follow;

  Future<Map<String, String>> _getHierarchy() async {
    final org = await session.database.getOrganization(follow.organizationId);
    final currentScope = await session.database.getScope(follow.scopeId);
    
    String? parentName;
    if (currentScope?.parentId != null) {
      final parent = await session.database.getScope(currentScope!.parentId!);
      parentName = parent?.name;
    }

    return {
      'org': org?.name ?? 'Unknown Organization',
      'parent': parentName ?? '',
      'scope': currentScope?.name ?? '',
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
    future: _getHierarchy(),
    builder: (context, snapshot) {
      final hierarchy = snapshot.data ?? {'org': 'Loading...', 'parent': '', 'scope': ''};
      final isPersonal = policy.state == PolicyState.personal;
      final unitLabel = policy.basis.label(policy.fullUnit);

      return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 80), children: [
        const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 20),
        StreamBuilder<UserProfile?>(
          stream: session.userRepo.watchProfile(session.uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: navy, child: Text(profile?.displayName.substring(0, 1).toUpperCase() ?? 'S', style: const TextStyle(color: Colors.white))), 
              title: Text(profile?.displayName ?? 'StandIn Member'), 
              subtitle: Text('${profile?.role.name.toUpperCase()} - profile stored privately')
            ));
          }
        ),
        const SizedBox(height: 24),
        const Text('FOLLOWING', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
        const SizedBox(height: 12),
        Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            leading: const Icon(Icons.account_balance_outlined, color: navy), 
            title: Text(hierarchy['org']!),
            subtitle: Text(hierarchy['scope']!.isEmpty ? 'General' : '${hierarchy['parent']!.isNotEmpty ? "${hierarchy['parent']} • " : ""}${hierarchy['scope']}'),
          ),
          if (policy.startDate != null && policy.endDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
              child: Text(
                'Academic Period: ${policy.startDate!.day}/${policy.startDate!.month}/${policy.startDate!.year} – ${policy.endDate!.day}/${policy.endDate!.month}/${policy.endDate!.year}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF667085), fontWeight: FontWeight.w500),
              ),
            ),
        ])),
        const SizedBox(height: 24),
        const Text('OFFICIAL ATTENDANCE RULES', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.rule_rounded, color: navy), 
            title: Text('Required ${policy.minimumPercent?.toStringAsFixed(0)}%'),
            subtitle: Text('Tracked by $unitLabel (${policy.evaluationPeriod.name})'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined, color: navy), 
            title: const Text('Working Days & Holidays'),
            subtitle: Text(calendar.isConfigured ? 'Standard schedule applied' : 'Not configured yet'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
        ])),
        const SizedBox(height: 24),
        const Text('MY ATTENDANCE SETTINGS', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(
            leading: Icon(isPersonal ? Icons.person_outline : Icons.lock_outline, color: isPersonal ? orange : Colors.grey), 
            title: Text(isPersonal ? 'Using Personal Override' : 'No personal overrides'),
            subtitle: Text(isPersonal ? 'Your target: ${policy.minimumPercent?.toStringAsFixed(0)}%' : 'Following official rules'),
            trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
          ),
        ])),
        const SizedBox(height: 24),
        const Text('APP INFORMATION', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.install_mobile_rounded, color: navy),
            title: const Text('Install StandIn App'),
            subtitle: const Text('Access StandIn faster from your home screen'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showInstallInstructions(context),
          ),
        ])),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAccountDeletion(context, session.onboardingController),
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            label: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: session.onboardingController.logout,
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
  );
}

void _confirmAccountDeletion(BuildContext context, OnboardingController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text(
        'This will permanently delete your profile, attendance history, and personal settings.\n\nShared organization data will be preserved.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final success = await controller.deleteAccount();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(controller.error ?? 'Deletion failed. Please try again.')),
              );
            }
          },
          child: const Text('Delete Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Future<void> showMarkAttendance(BuildContext context, AttendanceController controller, {DateTime? date}) {
  final targetDate = date ?? DateTime.now();
  final existing = controller.recordFor(targetDate);
  
  AttendanceStatus selected = existing?.status ?? AttendanceStatus.full; 
  double hours = existing?.actualUnits ?? controller.policy.fullUnit;
  
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
              Text('Mark attendance', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: navy)), 
              const SizedBox(height: 4),
              Text(
                '${targetDate.day} ${monthName(targetDate.month)} ${targetDate.year}',
                style: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w600),
              ),
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
              if (selected == AttendanceStatus.partial) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Actual hours', style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                    Text('${hours.toStringAsFixed(1)}h / ${controller.policy.fullUnit}h', style: const TextStyle(fontWeight: FontWeight.w800, color: orange)),
                  ],
                ),
                Slider(
                  value: hours, 
                  max: controller.policy.fullUnit, 
                  divisions: (controller.policy.fullUnit * 2).toInt(), 
                  activeColor: orange, 
                  onChanged: (value) => setSheet(() => hours = value)
                ),
              ],
              const SizedBox(height: 24), 
              SizedBox(
                width: double.infinity, 
                child: FilledButton(
                  onPressed: () async { 
                    await controller.mark(selected, actualUnits: hours, date: targetDate); 
                    if (sheet.mounted) Navigator.pop(sheet); 
                  }, 
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ), 
                  child: const Text('Save attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                )
              )
            ]
          ),
        )
      )
    )
  );
}

String statusText(AttendanceStatus status) => switch (status) { 
  AttendanceStatus.full => 'Full', 
  AttendanceStatus.half => 'Half day', 
  AttendanceStatus.partial => 'Partial hours', 
  AttendanceStatus.absent => 'Absent', 
  AttendanceStatus.holiday => 'Holiday', 
  AttendanceStatus.leave => 'On Leave',
  AttendanceStatus.weeklyOff => 'Weekly Off',
  AttendanceStatus.none => 'Not recorded' 
};

Color statusColor(AttendanceStatus status) => switch (status) { 
  AttendanceStatus.full => Colors.green, 
  AttendanceStatus.half || AttendanceStatus.partial => const Color(0xFFF59E0B), 
  AttendanceStatus.absent => const Color(0xFFDC2626), 
  AttendanceStatus.holiday || AttendanceStatus.leave => const Color(0xFF2563EB), 
  AttendanceStatus.weeklyOff => const Color(0xFF98A2B3),
  AttendanceStatus.none => Colors.grey 
};

IconData statusIcon(AttendanceStatus status) => switch (status) { 
  AttendanceStatus.full => Icons.check_rounded, 
  AttendanceStatus.half || AttendanceStatus.partial => Icons.timelapse_rounded, 
  AttendanceStatus.absent => Icons.close_rounded, 
  AttendanceStatus.holiday => Icons.celebration, 
  AttendanceStatus.leave => Icons.work_off_outlined,
  AttendanceStatus.weeklyOff => Icons.weekend,
  AttendanceStatus.none => Icons.remove_rounded 
};
String monthName(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];

class _InstallPwaCard extends StatelessWidget {
  const _InstallPwaCard({required this.onInstall, required this.onDismiss});
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.install_mobile_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(child: Text('Install StandIn App', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            IconButton(onPressed: onDismiss, icon: const Icon(Icons.close, color: Colors.white70, size: 20)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 36, bottom: 12),
          child: Text('Install StandIn for a faster, offline-ready experience on your home screen.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: onDismiss, child: const Text('Maybe later', style: TextStyle(color: Colors.white70))),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onInstall,
              style: FilledButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Install Now'),
            ),
          ],
        ),
      ],
    ),
  );
}

void _showInstallInstructions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How to install StandIn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy)),
          const SizedBox(height: 16),
          const Text('iOS (Safari):', style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
          const Text('1. Tap the Share button in the bottom bar.'),
          const Text('2. Scroll down and tap "Add to Home Screen".'),
          const SizedBox(height: 12),
          const Text('Android (Chrome):', style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
          const Text('1. Tap the three dots menu in the top right.'),
          const Text('2. Tap "Install app" or "Add to Home screen".'),
          const SizedBox(height: 12),
          const Text('Desktop (Chrome):', style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
          const Text('1. Click the Install icon in the address bar.'),
          const Text('2. Or use the browser menu > Save and Share > Install StandIn.'),
        ],
      ),
    ),
  );
}
