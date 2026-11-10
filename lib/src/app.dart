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
import 'features/onboarding/role_selection_page.dart';
import 'platform/pwa_service.dart';
import 'platform/pwa_install_hint.dart';
import 'data/sync/sync_engine.dart';
import 'data/remote/firestore_attendance_remote.dart';
import 'data/local_first_attendance_repository.dart';
import 'data/planning_repository.dart';
import 'domain/planning.dart';
import 'domain/app_errors.dart';
import 'features/following/following_page.dart';
import 'features/profile/profile_page.dart';
import 'data/calendar_repository.dart';
import 'features/following/shared_rules_page.dart';
import 'features/profile/data_backup_status.dart';
import 'features/profile/attendance_reports_page.dart';

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
  bool _isRestoring = false;
  String? _restorationError;

  @override
  void initState() {
    super.initState();

    const webClientId =
        '645644256889-fta4md48g87u4httj005egv22gf80j3g.apps.googleusercontent.com';

    auth = AuthService(
      FirebaseAuth.instance,
      const FlutterSecureStorage(
        webOptions: WebOptions(dbName: 'standin_vault'),
      ),
      clientId: kIsWeb ? webClientId : null,
    );

    _initGuestState();

    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthState);
  }

  void _initGuestState() {
    // Exactly one guest database instance
    _guestDb = StandInDatabase('guest');

    // Share the same guest database across repositories
    _landingController = OnboardingController(
      authService: auth,
      userRepository: UserRepository(
          _guestDb!, FirestoreUserRemote(FirebaseFirestore.instance)),
      organizationRepository: OrganizationRepository(
          _guestDb!, FirestoreOrgRemote(FirebaseFirestore.instance)),
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

      if (mounted) {
        setState(() {
          _isRestoring = true;
          _restorationError = null;
        });
      }

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

      try {
        final existingFollows =
            await database.select(database.followRows).get();
        for (final follow in existingFollows) {
          final acceptedPolicy = await orgRepo.getResolvedPolicy(
              uid: user.uid,
              organizationId: follow.organizationId,
              scopeId: follow.scopeId,
              followId: follow.id);
          final calendar = await orgRepo.getResolvedCalendar(
              uid: user.uid,
              organizationId: follow.organizationId,
              scopeId: follow.scopeId,
              followId: follow.id);
          await CalendarRepository(database, userRemote,
                  uid: user.uid, followId: follow.id)
              .ensure(
                  calendar.copyWith(
                      organizationId: follow.organizationId,
                      scopeId: follow.scopeId),
                  policy: acceptedPolicy);
          if (acceptedPolicy != null) {
            final state = await CalendarRepository(database, userRemote,
                    uid: user.uid, followId: follow.id)
                .read();
            await LocalFirstAttendanceRepository(database,
                    uid: user.uid,
                    organizationId: follow.organizationId,
                    scopeId: follow.scopeId)
                .protectHistory(acceptedPolicy, calendar,
                    policyFor: (date) =>
                        state?.policyAt(date) ?? acceptedPolicy,
                    calendarFor: (date) => state?.calendarAt(date) ?? calendar);
          }
        }
        // Pre-fetch profile before setting session
        // This ensures build() doesn't see an empty local DB for returning users
        final hasProfile = await userRepo.syncProfile(user.uid);

        if (hasProfile) {
          await userRepo.syncFollows(user.uid);
          final profile = await userRepo.getProfile(user.uid);
          final activeFollowId = profile?.activeFollowId;
          if (activeFollowId != null) {
            // Restore hierarchical context (Follow, Organization, Policy, Calendar)
            await orgRepo.syncFollowContext(user.uid, activeFollowId,
                userRemote: userRemote);
          }
        }

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
          attendanceRemote:
              FirestoreAttendanceRemote(FirebaseFirestore.instance),
          syncEngine: syncEngine,
          initialStep: OnboardingStep.roleSelection,
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
            _isRestoring = false;
          });
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
        if (mounted) {
          setState(() {
            _isRestoring = false;
            _restorationError =
                'Could not restore your session. Please check your connection.';
          });
        }
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
    if (_restorationError != null) {
      return _buildApp(Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: orange),
                const SizedBox(height: 24),
                Text(_restorationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        color: navy,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: FilledButton(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) _handleAuthState(user);
                    },
                    child: const Text('Retry'),
                  ),
                ),
                TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    if (_isRestoring ||
        (_session == null && FirebaseAuth.instance.currentUser != null)) {
      return _buildApp(const Scaffold(
          body: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Restoring your session...',
              style: TextStyle(color: navy, fontWeight: FontWeight.w600)),
        ],
      ))));
    }

    if (_session == null) {
      return _buildApp(LandingLoginPage(controller: _landingController));
    }

    final session = _session!;

    return StreamBuilder<UserProfile?>(
      stream: session.userRepo.watchProfile(session.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;

        if (profile == null) {
          return ListenableBuilder(
            listenable: session.onboardingController,
            builder: (context, _) => _buildApp(_getOnboardingScreen(
                session.onboardingController.step,
                session.onboardingController)),
          );
        }
        if (profile.activeFollowId == null) {
          return _buildApp(NoActiveFollowShell(session: session));
        }

        return StreamBuilder<FollowRow?>(
            stream: session.database.watchFollow(profile.activeFollowId!),
            builder: (context, followSnapshot) {
              final followRow = followSnapshot.data;
              if (followRow == null) {
                if (followSnapshot.hasError ||
                    followSnapshot.connectionState == ConnectionState.active) {
                  return _buildContextRecovery(
                      'Your organization could not be loaded.');
                }
                return _buildApp(const Scaffold(
                    body: Center(child: CircularProgressIndicator())));
              }

              return FutureBuilder<AttendancePolicy?>(
                future: session.orgRepo.getResolvedPolicy(
                  uid: session.uid,
                  organizationId: followRow.organizationId,
                  scopeId: followRow.scopeId,
                  followId: followRow.id,
                ),
                builder: (context, policySnapshot) {
                  if (policySnapshot.hasError ||
                      (policySnapshot.connectionState == ConnectionState.done &&
                          policySnapshot.data == null)) {
                    return _buildContextRecovery(
                        'Your attendance rules could not be loaded.');
                  }
                  if (!policySnapshot.hasData) {
                    return _buildApp(const Scaffold(
                        body: Center(child: CircularProgressIndicator())));
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
                      if (calendarSnapshot.hasError) {
                        return _buildContextRecovery(
                            'Your attendance calendar could not be loaded.');
                      }
                      if (!calendarSnapshot.hasData) {
                        return _buildApp(const Scaffold(
                            body: Center(child: CircularProgressIndicator())));
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
            });
      },
    );
  }

  Widget _buildContextRecovery(String message) => _buildApp(Scaffold(
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () async {
                try {
                  await _session?.syncEngine.syncNow();
                } catch (_) {
                  // Keep the recovery screen available while the connection is down.
                }
                if (mounted) setState(() {});
              },
            ),
            TextButton(
                onPressed: () => auth.signOut(), child: const Text('Sign Out')),
          ],
        )),
      ));

  Widget _buildApp(Widget home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: background,
          colorScheme: ColorScheme.fromSeed(
              seedColor: navy, primary: navy, secondary: orange),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        home: home,
      );

  Widget _getOnboardingScreen(
      OnboardingStep step, OnboardingController controller) {
    switch (step) {
      case OnboardingStep.welcome:
        return LandingLoginPage(controller: controller);
      case OnboardingStep.roleSelection:
        return RoleSelectionPage(controller: controller);
      case OnboardingStep.profile:
        return ProfileSetupPage(controller: controller);
      case OnboardingStep.usernameGeneration:
        return UsernameGenerationPage(controller: controller);
      case OnboardingStep.organizationSearch:
        return OrganizationSearchPage(controller: controller);
      case OnboardingStep.organizationCreate:
        return OrganizationCreatePage(controller: controller);
      case OnboardingStep.organizationId:
        return OrganizationIdPage(controller: controller);
      case OnboardingStep.policyDetection:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case OnboardingStep.policyPreview:
        return PolicyPreviewPage(controller: controller);
      case OnboardingStep.policyConflict:
        return PolicyConflictPage(controller: controller);
      case OnboardingStep.setupUnit:
        return PolicySetupBasisPage(controller: controller);
      case OnboardingStep.setupPeriod:
        return PolicySetupPeriodPage(controller: controller);
      case OnboardingStep.setupTarget:
        return PolicySetupTargetPage(controller: controller);
      case OnboardingStep.scopeBranch:
        return OrganizationSearchPage(controller: controller);
      case OnboardingStep.scopeSemester:
        return OrganizationSearchPage(controller: controller);
      case OnboardingStep.setupDates:
        return PolicySetupDatesPage(controller: controller);
      case OnboardingStep.setupSchedule:
        return PolicySetupSchedulePage(controller: controller);
      case OnboardingStep.setupDaysOff:
        return PolicySetupDaysOffPage(controller: controller);
      case OnboardingStep.setupSaturday:
        return PolicySetupSaturdayPage(controller: controller);
      case OnboardingStep.complete:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    if (oldWidget.policy != widget.policy ||
        oldWidget.calendar != widget.calendar ||
        oldWidget.followRow.id != widget.followRow.id ||
        oldWidget.session.uid != widget.session.uid) {
      controller.dispose();
      _initController();
    }
  }

  void _initController() {
    repository = LocalFirstAttendanceRepository(
      widget.session.database,
      uid: widget.session.uid,
      organizationId: widget.followRow.organizationId,
      scopeId: widget.followRow.scopeId,
    );
    final calendars = CalendarRepository(
        widget.session.database, widget.session.userRepo.remote,
        uid: widget.session.uid, followId: widget.followRow.id);
    unawaited(calendars
        .ensure(
            widget.calendar.copyWith(
                organizationId: widget.followRow.organizationId,
                scopeId: widget.followRow.scopeId),
            policy: widget.policy)
        .catchError((Object error) =>
            debugPrint('Calendar initialization failed: $error')));
    controller = AttendanceController(
        repository, const PolicyEngine(), widget.policy, widget.calendar,
        refreshAtMidnight: true,
        calendarRepository: calendars,
        planningRepository: PlanningRepository(widget.session.database,
            organizationId: widget.followRow.organizationId,
            scopeId: widget.followRow.scopeId));
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

class _LandingLoginPageState extends State<LandingLoginPage>
    with SingleTickerProviderStateMixin {
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
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20),
                          child: Column(
                            children: [
                              const Spacer(),
                              Center(
                                child: Image.asset(
                                  'assets/brand/standin_logo.png',
                                  height: 180,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.how_to_reg,
                                      color: navy,
                                      size: 120),
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
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF667085),
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              if (widget.controller.authError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    widget.controller.authError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: FilledButton(
                                  onPressed: widget.controller.isAuthenticating
                                      ? null
                                      : widget.controller.signInWithGoogle,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: navy,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  child: widget.controller.isAuthenticating
                                      ? RotationTransition(
                                          turns: _rotationController,
                                          child: Image.asset(
                                              'assets/brand/standin_loading_icon.png',
                                              height: 28),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login,
                                                color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Continue with Google',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _InstallHint(),
                              const Spacer(),
                              const Text(
                                'By continuing, you agree to our Terms of Service',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF98A2B3)),
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
          return Card(
              color: const Color(0xFFFFF4EC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(children: [
                  const Icon(Icons.add_to_home_screen_outlined, color: navy),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(message,
                          style: const TextStyle(fontSize: 12, color: navy))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        PwaInstallHint.dismiss();
                        setState(() => _dismissed = true);
                      })
                ]),
              ));
        },
      );
}

class NoActiveFollowShell extends StatefulWidget {
  const NoActiveFollowShell({super.key, required this.session});
  final UserSession session;
  @override
  State<NoActiveFollowShell> createState() => _NoActiveFollowShellState();
}

class _NoActiveFollowShellState extends State<NoActiveFollowShell> {
  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
        body: SafeArea(
            child: ProfileView(
                uid: session.uid,
                database: session.database,
                users: session.userRepo,
                organizations: session.orgRepo,
                attendanceRemote: session.userRepo.remote.attendanceRemote,
                onManageFollowing: () {},
                onLogout: session.onboardingController.logout,
                onDeleteAccount: () => _confirmAccountDeletion(
                    context, session.onboardingController))));
  }
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
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(
          controller: widget.controller,
          onNavigateToCalendar: () => setState(() => page = 1),
          updates: UserRepository.followFromRow(widget.followRow)
                  .isPersonalCalculation
              ? null
              : RuleUpdatesPanel(
                  key: ValueKey(widget.followRow.id),
                  repository: widget.controller.calendarRepository!,
                  organizations: widget.session.orgRepo,
                  organizationId: widget.followRow.organizationId)),
      CalendarPage(controller: widget.controller),
      ProfileView(
        uid: widget.session.uid,
        database: widget.session.database,
        users: widget.session.userRepo,
        organizations: widget.session.orgRepo,
        attendanceRemote: widget.session.userRepo.remote.attendanceRemote,
        policy: widget.controller.policy,
        calendar: widget.controller.calendar,
        follow: UserRepository.followFromRow(widget.followRow),
        onManageFollowing: () {},
        onLogout: widget.session.onboardingController.logout,
        onDeleteAccount: () => _confirmAccountDeletion(
            context, widget.session.onboardingController),
      ),
    ];
    return Scaffold(
      body: SafeArea(child: screens[page]),
      floatingActionButton: page != 0
          ? null
          : FloatingActionButton.extended(
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
              NavigationDestination(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile')
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
            Text('Advertisement',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF98A2B3))),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key,
      required this.controller,
      required this.onNavigateToCalendar,
      this.updates});
  final Widget? updates;
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
            if (summary == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final today = widget.controller.recordFor(DateTime.now());

            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                children: [
                  if (showBanner) ...[
                    _InstallPwaCard(
                      onInstall: () => PwaService.instance.promptInstall(),
                      onDismiss: () =>
                          setState(() => _showInstallPrompt = false),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(summary.periodLabel,
                              style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                              summary.isPolicyIncomplete
                                  ? 'Attendance rules incomplete'
                                  : summary.isSafe
                                      ? 'Period target reached'
                                      : summary.conductedToDate == 0
                                          ? 'Ready to start'
                                          : summary.percent >=
                                                  widget.controller.policy
                                                      .minimumPercent!
                                              ? 'On track so far'
                                              : 'Below your target',
                              style: const TextStyle(
                                  fontSize: 26,
                                  letterSpacing: -.6,
                                  fontWeight: FontWeight.w800,
                                  color: navy))
                        ])),
                  ]),
                  const SizedBox(height: 20),
                  DualAttendanceSummary(
                      actual: summary.percent,
                      showProjected: widget.controller.hasFuturePlans(),
                      projected: widget.controller.planningSummary.percent,
                      actualIncomplete: summary.isPolicyIncomplete,
                      projectedIncomplete:
                          widget.controller.planningSummary.isIncomplete),
                  if (summary.isPolicyIncomplete) Text(summary.recoveryMessage),
                  const SizedBox(height: 8),
                  Text(summary.progressLabel),
                  if (widget.controller.database != null &&
                      widget.controller.calendarRepository != null)
                    DataBackupStatus(
                        database: widget.controller.database!,
                        uid: widget.controller.calendarRepository!.uid),
                  if (summary.leaveCredit > 0 || summary.extraCredit > 0)
                    Text(
                        '${summary.physicalUnits.toStringAsFixed(1)} attended + '
                        '${summary.leaveCredit.toStringAsFixed(1)} leave + '
                        '${summary.extraCredit.toStringAsFixed(1)} extra '
                        '${widget.controller.policy.basis.label(summary.actual)}'),
                  if (widget.updates != null) widget.updates!,
                  const SizedBox(height: 12),
                  if (summary.needsAttention)
                    _AttentionRequiredCard(
                        count: summary.unmarkedCount,
                        onTap: widget.onNavigateToCalendar),
                  if (!summary.isPolicyIncomplete)
                    AdviceCard(
                        summary: summary, policy: widget.controller.policy),
                  UpcomingPlans(
                      controller: widget.controller,
                      onOpenCalendar: widget.onNavigateToCalendar),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: navy)),
                      TextButton(
                        onPressed: widget.onNavigateToCalendar,
                        child: const Row(children: [
                          Text('View Calendar',
                              style: TextStyle(
                                  color: orange, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: orange),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _TodayCard(
                      record: today,
                      company: widget.controller.isCompany,
                      policy: widget.controller.policy,
                      onTap: () =>
                          showMarkAttendance(context, widget.controller)),
                  const SizedBox(height: 24),
                  const Text('Recent activity',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: navy)),
                  const SizedBox(height: 9),
                  ...widget.controller.records.reversed.take(3).map((record) =>
                      _ActivityRow(
                          record: record,
                          company: widget.controller.isCompany)),
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
        decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: orange),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance needs attention',
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.w800, fontSize: 15)),
              Text('$count working days are not marked yet.',
                  style:
                      const TextStyle(color: Color(0xFF667085), fontSize: 13)),
            ],
          )),
          TextButton(onPressed: onTap, child: const Text('Review'))
        ]),
      );
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
          border: Border.all(color: const Color(0xFFE8EBF1), width: 1.5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(
                status == PeriodStatus.impossible
                    ? Icons.error_outline_rounded
                    : (status == PeriodStatus.onTrack
                        ? Icons.shield_rounded
                        : Icons.trending_up_rounded),
                color: accent,
                size: 26)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              status == PeriodStatus.impossible
                  ? 'Attendance Goal Unachievable'
                  : (status == PeriodStatus.onTrack
                      ? 'Your Safe Limit'
                      : 'Attendance Recovery Plan'),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: navy)),
          const SizedBox(height: 4),
          Text(
            summary.recoveryMessage,
            style: const TextStyle(
                fontSize: 14, height: 1.4, color: Color(0xFF667085)),
          ),
        ])),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard(
      {required this.record,
      required this.policy,
      required this.onTap,
      this.company = false});
  final bool company;
  final AttendanceRecord? record;
  final AttendancePolicy policy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final marked = record != null;
    final policy = record?.snapshot?.policy ?? this.policy;
    final unitLabel = policy.basis == CalculationBasis.hours
        ? 'h'
        : ' ${policy.basis.label(marked ? record!.expectedUnits : policy.fullUnit)}';

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
                  color: (marked
                          ? (record!.status == AttendanceStatus.absent
                              ? Colors.red
                              : Colors.green)
                          : orange)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  marked ? statusIcon(record!.status) : Icons.add_task_outlined,
                  color: marked
                      ? (record!.status == AttendanceStatus.absent
                          ? Colors.red
                          : Colors.green)
                      : orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marked
                          ? attendanceStatusLabel(record!.status,
                              company: company,
                              oneVisit: policy.oneVisitFullDay)
                          : 'No attendance recorded',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      marked
                          ? '${record!.actualUnits.toStringAsFixed(1)} / ${record!.expectedUnits.toStringAsFixed(1)}$unitLabel today'
                          : 'Tap to mark your attendance',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF667085)),
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
  const _ActivityRow({required this.record, this.company = false});
  final bool company;
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: statusColor(record.status).withValues(alpha: .11),
                shape: BoxShape.circle),
            child: Icon(statusIcon(record.status),
                size: 17, color: statusColor(record.status))),
        const SizedBox(width: 11),
        Expanded(
            child: Text(
                '${record.date.day}/${record.date.month}/${record.date.year}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, color: navy))),
        Text(
            attendanceStatusLabel(record.status,
                company: company,
                oneVisit: record.snapshot?.policy.oneVisitFullDay ?? false),
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
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
        final monthlySummary = widget.controller
            .getMonthlySummary(viewMonth.year, viewMonth.month);
        final projected = widget.controller
            .getMonthlyPlanningSummary(viewMonth.year, viewMonth.month);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                            '${monthName(viewMonth.month)} ${viewMonth.year}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: navy))),
                    IconButton(
                        tooltip: 'Attendance reports',
                        icon: const Icon(Icons.insert_chart_outlined),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AttendanceReportsPage(
                                    records:
                                        widget.controller.watchSavedRecords(),
                                    rules: widget.controller.calendarRepository
                                        ?.watch(),
                                    name: 'Saved attendance',
                                    company: widget.controller.isCompany)))),
                    if (widget.controller.calendarRepository != null)
                      IconButton(
                          tooltip: 'Calendar settings',
                          icon: const Icon(Icons.tune),
                          onPressed: () async {
                            final repository =
                                widget.controller.calendarRepository!;
                            final row = await repository.database
                                .getFollow(repository.followId);
                            if (row == null || !context.mounted) return;
                            await editPersonalRules(
                                context,
                                repository.uid,
                                UserRepository(
                                    repository.database, repository.remote),
                                UserRepository.followFromRow(row),
                                widget.controller.policy,
                                widget.controller.calendar);
                          })
                  ]),
                  const SizedBox(height: 4),
                  DualAttendanceSummary(
                      actual: monthlySummary.percent,
                      showProjected: widget.controller.hasFuturePlans(
                          year: viewMonth.year, month: viewMonth.month),
                      projected: projected.percent,
                      actualIncomplete: monthlySummary.isPolicyIncomplete,
                      projectedIncomplete: projected.isIncomplete),
                  if (monthlySummary.isPolicyIncomplete)
                    Text(monthlySummary.recoveryMessage),
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
    final calendar = controller.calendarFor(viewMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
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
              mainAxisExtent: 48,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, index) {
              if (index < offset) return const SizedBox();
              final date =
                  DateTime(viewMonth.year, viewMonth.month, index - offset + 1);
              final calendar = controller.calendarFor(date);
              final record = controller.recordFor(date);
              final plan = controller.planFor(date);
              final isToday = DateUtils.isSameDay(date, now);
              final isHoliday = record?.status == AttendanceStatus.holiday ||
                  calendar.holidays
                      .any((h) => DateUtils.isSameDay(h.date, date));
              final isWeeklyOff = !isHoliday && calendar.isNonWorkingDay(date);
              final isFuture =
                  date.isAfter(DateTime(now.year, now.month, now.day));

              final statusCol =
                  record != null ? statusColor(record.status) : null;

              return InkWell(
                key: ValueKey(
                    'calendar-day-${date.toIso8601String().substring(0, 10)}'),
                onTap: isFuture
                    ? () => showPlanAttendance(context, controller, date)
                    : () => showMarkAttendance(context, controller, date: date),
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: plan != null && record == null
                          ? Border.all(
                              color: const Color(0xFF00796B), width: 1.5)
                          : isToday
                              ? Border.all(
                                  color: navy.withValues(alpha: 0.2),
                                  width: 1.5)
                              : null,
                      color: record != null
                          ? statusCol!.withValues(alpha: 0.12)
                          : (isHoliday
                              ? orange.withValues(alpha: 0.08)
                              : (isWeeklyOff
                                  ? const Color(0xFFF0F2F5)
                                  : Colors.transparent)),
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
                              decoration: const BoxDecoration(
                                  color: orange, shape: BoxShape.circle),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${date.day}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: (isHoliday || isWeeklyOff) &&
                                          record == null
                                      ? const Color(0xFF98A2B3)
                                      : navy,
                                )),
                            if (isHoliday)
                              const Icon(Icons.beach_access_outlined,
                                  color: orange, size: 12)
                            else if (record != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(statusIcon(record.status),
                                    color: statusCol, size: 12),
                              )
                            else if (plan != null)
                              Icon(
                                  plan.status == AttendanceStatus.absent
                                      ? Icons.event_busy_outlined
                                      : Icons.event_note_outlined,
                                  color: const Color(0xFF00796B),
                                  size: 12)
                            else if (isWeeklyOff)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.weekend,
                                    color: Color(0xFF98A2B3), size: 10),
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
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _LegendItem(
                  label:
                      controller.label(AttendanceStatus.full, date: viewMonth),
                  icon: Icons.check_circle,
                  color: Colors.green),
              _LegendItem(
                  label: 'Half',
                  icon: Icons.timelapse,
                  color: Color(0xFFF59E0B)),
              _LegendItem(
                  label: controller.label(AttendanceStatus.absent,
                      date: viewMonth),
                  icon: Icons.cancel,
                  color: Color(0xFFDC2626)),
              _LegendItem(
                  label: 'Holiday',
                  icon: Icons.beach_access_outlined,
                  color: orange),
              _LegendItem(
                  label: 'Day off',
                  icon: Icons.weekend,
                  color: Color(0xFF98A2B3)),
              _LegendItem(
                  label: 'Planned',
                  icon: Icons.event_note_outlined,
                  color: Color(0xFF00796B)),
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
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF667085))),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
      ]);
}

class _HolidayWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, color: orange),
          const SizedBox(width: 12),
          const Expanded(
              child: Text(
                  'Working Days & Holidays not configured for this organization.',
                  style: TextStyle(
                      color: navy, fontSize: 13, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () {}, child: const Text('Add'))
        ]),
      );
}

void _confirmAccountDeletion(
    BuildContext context, OnboardingController controller) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Account?',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text(
        'This will permanently delete your profile, attendance history, and personal settings.\n\nShared organization data will be preserved.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            final success = await controller.deleteAccount();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(controller.error ??
                        'Deletion failed. Please try again.')),
              );
            }
          },
          child: const Text('Delete Permanently',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Future<void> showMarkAttendance(
    BuildContext context, AttendanceController controller,
    {DateTime? date}) {
  final targetDate = date ?? DateTime.now();
  final now = DateTime.now();
  if (targetDate.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
    return showPlanAttendance(context, controller, targetDate);
  }
  final existing = controller.recordFor(targetDate);
  final policy = controller.entryPolicy(targetDate);
  final dayType = existing?.snapshot?.dayType ??
      const PolicyEngine()
          .dayType(controller.calendarFor(targetDate), targetDate);
  final isDayOff = dayType != AttendanceDayType.working;
  final countsOnDayOff = dayType == AttendanceDayType.holiday
      ? policy.holidayCredit
      : policy.weekOffCredit;
  final String? guidance = isDayOff
      ? countsOnDayOff
          ? 'Attendance today counts toward your percentage. Working days stay the same.'
          : 'Attendance on this day off does not count with your current rules.'
      : policy.oneVisitFullDay
          ? controller.isCompany
              ? 'One swipe counts as a full day.'
              : 'One class counts as a full day.'
          : controller.isCompany
              ? 'Choose Swiped once you meet your company’s full-day rule.'
              : null;
  double leave = existing?.leaveUnits ??
      (controller.planFor(targetDate)?.status == AttendanceStatus.leave
          ? (controller.planFor(targetDate)!.leaveUnits > 0
              ? controller.planFor(targetDate)!.leaveUnits
              : controller.planFor(targetDate)!.units)
          : controller.planFor(targetDate)?.leaveUnits ?? 0);
  final plan = controller.planFor(targetDate);
  final holiday = controller
      .calendarFor(targetDate)
      .holidays
      .where((h) => DateUtils.isSameDay(h.date, targetDate))
      .firstOrNull;

  AttendanceStatus selected = existing?.status ??
      (holiday != null
          ? AttendanceStatus.holiday
          : plan?.status ?? AttendanceStatus.full);
  double hours = (existing?.actualUnits ?? plan?.units ?? policy.fullUnit)
      .clamp(0, policy.fullUnit)
      .toDouble();
  bool saving = false;

  return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
          builder: (_, setSheet) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 28),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          plan != null && existing == null
                              ? 'Confirm attendance'
                              : 'Mark attendance',
                          style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: navy)),
                      const SizedBox(height: 4),
                      Text(
                        '${targetDate.day} ${monthName(targetDate.month)} ${targetDate.year}',
                        style: const TextStyle(
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w600),
                      ),
                      if (guidance != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(guidance)),
                      const SizedBox(height: 18),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final status in [
                          AttendanceStatus.full,
                          if (!policy.oneVisitFullDay) ...[
                            AttendanceStatus.half,
                            AttendanceStatus.partial,
                          ],
                          AttendanceStatus.absent,
                          AttendanceStatus.leave,
                          AttendanceStatus.holiday
                        ])
                          ChoiceChip(
                              avatar: status == AttendanceStatus.holiday
                                  ? const Icon(Icons.beach_access_outlined,
                                      size: 18)
                                  : null,
                              label: Text(
                                  controller.label(status, date: targetDate)),
                              selected: selected == status,
                              onSelected: saving
                                  ? null
                                  : (_) => setSheet(() {
                                        if (selected == status) return;
                                        selected = status;
                                        leave = status == AttendanceStatus.leave
                                            ? policy.fullUnit
                                            : 0;
                                        if (status == AttendanceStatus.full) {
                                          hours = policy.fullUnit;
                                        }
                                        if (status == AttendanceStatus.half) {
                                          hours = policy.halfUnit;
                                        }
                                        if (status ==
                                            AttendanceStatus.partial) {
                                          hours = partialDefault(policy);
                                        }
                                        if (status == AttendanceStatus.absent) {
                                          hours = 0;
                                        }
                                      }))
                      ]),
                      if (selected == AttendanceStatus.partial) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Partial',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, color: navy)),
                            Flexible(
                                child: Text(
                                    '${hours.toStringAsFixed(1)} ${policy.basis.label(hours)} of ${policy.fullUnit}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: orange))),
                          ],
                        ),
                        Slider(
                            key: const ValueKey('attendance-units'),
                            value: hours,
                            max: policy.fullUnit,
                            divisions:
                                (policy.fullUnit * 2).ceil().clamp(1, 1000),
                            activeColor: orange,
                            onChanged: (value) => setSheet(() {
                                  hours = value;
                                  leave = leave
                                      .clamp(0, policy.fullUnit - hours)
                                      .toDouble();
                                  if (value == 0) {
                                    selected = AttendanceStatus.absent;
                                  }
                                  if (value == policy.fullUnit) {
                                    selected = AttendanceStatus.full;
                                  }
                                })),
                      ],
                      if (selected == AttendanceStatus.leave ||
                          selected == AttendanceStatus.half ||
                          selected == AttendanceStatus.partial) ...[
                        const SizedBox(height: 16),
                        Text(
                            'Leave: ${leave.toStringAsFixed(1)} ${policy.basis.label(leave)}'),
                        Slider(
                            key: const ValueKey('attendance-leave'),
                            value: leave.clamp(
                                0,
                                selected == AttendanceStatus.leave
                                    ? policy.fullUnit
                                    : policy.fullUnit - hours),
                            max: selected == AttendanceStatus.leave
                                ? policy.fullUnit
                                : policy.fullUnit - hours,
                            divisions:
                                (policy.fullUnit * 2).ceil().clamp(1, 1000),
                            onChanged: saving
                                ? null
                                : (value) => setSheet(() => leave = value)),
                      ],
                      if (existing?.snapshot != null)
                        Text(
                            'Saved in ${existing!.snapshot!.policy.basis.label(existing.snapshot!.policy.fullUnit)}'),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      setSheet(() => saving = true);
                                      try {
                                        final preview = const PolicyEngine()
                                            .createRecord(
                                                date: targetDate,
                                                status: selected,
                                                policy: policy,
                                                actualUnits: hours,
                                                leaveUnits: leave,
                                                calendar: controller
                                                    .calendarFor(targetDate),
                                                recordedDayType: existing
                                                    ?.snapshot?.dayType);
                                        if (existing != null) {
                                          final confirmed = await showDialog<
                                                  bool>(
                                              context: sheet,
                                              builder: (dialog) => AlertDialog(
                                                      title: const Text(
                                                          'Correct attendance?'),
                                                      content: Text(
                                                          'Credit: ${existing.snapshot?.credited ?? existing.actualUnits} to ${preview.snapshot!.credited}\nRequired: ${existing.snapshot?.requiredUnits ?? existing.expectedUnits} to ${preview.snapshot!.requiredUnits}'),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dialog,
                                                                    false),
                                                            child: const Text(
                                                                'Cancel')),
                                                        FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dialog,
                                                                    true),
                                                            child: const Text(
                                                                'Save correction'))
                                                      ]));
                                          if (confirmed != true) {
                                            setSheet(() => saving = false);
                                            return;
                                          }
                                        }
                                        await controller.mark(selected,
                                            actualUnits: hours,
                                            leaveUnits: leave,
                                            date: targetDate,
                                            presentedRevision:
                                                existing?.fingerprint);
                                        if (sheet.mounted) Navigator.pop(sheet);
                                      } catch (error) {
                                        if (sheet.mounted) {
                                          setSheet(() => saving = false);
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text(actionError(error))),
                                          );
                                        }
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: navy,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                  selected == AttendanceStatus.holiday &&
                                          controller.calendarRepository != null
                                      ? 'Save holiday'
                                      : 'Save attendance',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))))
                    ]),
              ))));
}

class DualAttendanceSummary extends StatelessWidget {
  const DualAttendanceSummary(
      {super.key,
      required this.actual,
      required this.projected,
      this.actualIncomplete = false,
      this.projectedIncomplete = false,
      this.showProjected = true});
  final bool showProjected;
  final double actual, projected;
  final bool actualIncomplete, projectedIncomplete;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, size) {
        Widget metric(String label, double value, Color color,
                {String? detail, bool incomplete = false}) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(incomplete ? '—' : '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              if (detail != null)
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF667085))),
            ]);
        final left = metric('As of now', actual, const Color(0xFF16803C),
            incomplete: actualIncomplete);
        final right = metric('With plans', projected, const Color(0xFF00796B),
            detail: 'Projected', incomplete: projectedIncomplete);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: !showProjected
                ? left
                : size.maxWidth < 240
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [left, const SizedBox(height: 12), right])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Expanded(child: left),
                            const SizedBox(width: 12),
                            Expanded(child: right)
                          ]));
      });
}

class UpcomingPlans extends StatelessWidget {
  const UpcomingPlans(
      {super.key, required this.controller, required this.onOpenCalendar});
  final AttendanceController controller;
  final VoidCallback onOpenCalendar;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = const PolicyEngine().periodRange(controller.policy, now);
    final upcoming = controller.plans
        .where((p) =>
            !p.isDeleted &&
            p.date.isAfter(today) &&
            range != null &&
            !p.date.isBefore(DateTime(
                range.start.year, range.start.month, range.start.day)) &&
            !p.date.isAfter(range.end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Row(children: [
        const Expanded(
            child: Text('Upcoming plans',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
        IconButton(
            tooltip: 'View plans in calendar',
            onPressed: onOpenCalendar,
            icon: const Icon(Icons.calendar_month_outlined))
      ]),
      if (upcoming.isEmpty) const Text('No upcoming plans this period'),
      for (final plan in upcoming.take(3))
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(statusIcon(plan.status)),
            title: Text(
                '${plan.date.day} ${monthName(plan.date.month)} | ${plan.status == AttendanceStatus.full ? 'Going' : attendanceStatusLabel(plan.status)}'),
            subtitle: Text(controller.planDescription(plan)),
            onTap: () => showPlanAttendance(context, controller, plan.date)),
    ]);
  }
}

double partialDefault(AttendancePolicy policy) =>
    policy.halfUnit > 0 && policy.halfUnit < policy.fullUnit
        ? policy.halfUnit
        : policy.fullUnit / 2;

Future<void> showPlanAttendance(BuildContext context,
    AttendanceController controller, DateTime date) async {
  final existing = controller.planFor(date);
  final policy = controller.policyFor(date);
  final calendar = controller.calendarFor(date);
  final extraAllowed =
      const PolicyEngine().dayType(calendar, date) == AttendanceDayType.holiday
          ? policy.holidayCredit
          : policy.weekOffCredit;
  final holiday = calendar.holidays
      .where((h) => DateUtils.isSameDay(h.date, date))
      .firstOrNull;
  final nonWorking = calendar.isNonWorkingDay(date);
  var selected =
      existing == null && nonWorking && controller.calendarRepository != null
          ? AttendanceStatus.holiday
          : existing?.status ?? AttendanceStatus.full;
  var leave = existing?.leaveUnits ?? 0.0;
  var units = (existing?.status == AttendanceStatus.leave
          ? (existing!.leaveUnits > 0 ? existing.leaveUnits : existing.units)
          : existing?.units ?? policy.fullUnit)
      .clamp(0, policy.fullUnit)
      .toDouble();
  var name = holiday?.name ?? 'Holiday';
  var saving = false;
  String? error;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(builder: (_, update) {
            Future<void> save(
                {bool remove = false, bool working = false}) async {
              update(() {
                saving = true;
                error = null;
              });
              try {
                if (working) {
                  await controller.setHoliday(date, null);
                } else if (remove) {
                  await controller.removePlan(date);
                } else if (selected == AttendanceStatus.holiday) {
                  await controller.setHoliday(date, name);
                } else {
                  await controller.plan(selected, date,
                      units: units, leaveUnits: leave);
                }
                if (sheet.mounted) Navigator.pop(sheet);
              } catch (failure) {
                if (sheet.mounted) {
                  update(() {
                    saving = false;
                    error = actionError(failure);
                  });
                }
              }
            }

            return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(sheet).viewInsets.bottom + 28),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                '${date.day} ${monthName(date.month)} ${date.year}',
                                style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800))),
                        if (existing != null)
                          IconButton(
                              tooltip: 'Remove plan',
                              onPressed:
                                  saving ? null : () => save(remove: true),
                              icon: const Icon(Icons.delete_outline))
                      ]),
                      if (nonWorking && extraAllowed)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'If you attend, it counts toward your percentage. Working days stay the same.')),
                      const SizedBox(height: 20),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final status in [
                          if (!nonWorking || extraAllowed) ...[
                            AttendanceStatus.full,
                            if (!policy.oneVisitFullDay) ...[
                              AttendanceStatus.half,
                              AttendanceStatus.partial,
                            ],
                            AttendanceStatus.absent,
                            if (!nonWorking) AttendanceStatus.leave
                          ],
                          if (controller.calendarRepository != null)
                            AttendanceStatus.holiday,
                        ])
                          ChoiceChip(
                              avatar: status == AttendanceStatus.holiday
                                  ? const Icon(Icons.beach_access_outlined,
                                      size: 18)
                                  : null,
                              label: Text(switch (status) {
                                AttendanceStatus.full => 'Going',
                                AttendanceStatus.half => 'Half day',
                                AttendanceStatus.partial => 'Partial',
                                AttendanceStatus.holiday => 'Holiday',
                                AttendanceStatus.leave => 'Leave',
                                _ => 'Not going'
                              }),
                              selected: selected == status,
                              onSelected: saving
                                  ? null
                                  : (_) => update(() {
                                        if (selected == status) return;
                                        selected = status;
                                        leave = 0;
                                        if (status == AttendanceStatus.leave) {
                                          units = policy.fullUnit;
                                        }
                                        if (status == AttendanceStatus.full) {
                                          units = policy.fullUnit;
                                        }
                                        if (status == AttendanceStatus.half) {
                                          units = policy.halfUnit;
                                        }
                                        if (status ==
                                            AttendanceStatus.partial) {
                                          units = partialDefault(policy);
                                        }
                                        if (status == AttendanceStatus.absent) {
                                          units = 0;
                                        }
                                      })),
                      ]),
                      if (selected == AttendanceStatus.holiday) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                            initialValue: name,
                            onChanged: (value) => name = value,
                            maxLength: 80,
                            decoration: const InputDecoration(
                                labelText: 'Holiday name')),
                        if (existing != null)
                          const Text(
                              'Your saved plan is kept and excluded while this date is a holiday.'),
                      ],
                      if (nonWorking && controller.calendarRepository != null)
                        TextButton.icon(
                            onPressed:
                                saving ? null : () => save(working: true),
                            icon: const Icon(Icons.work_outline),
                            label: const Text('Make working day')),
                      if (selected == AttendanceStatus.leave) ...[
                        const SizedBox(height: 16),
                        SegmentedButton<double>(
                            segments: [
                              ButtonSegment(
                                  value: policy.fullUnit,
                                  label: const Text('Full leave')),
                              ButtonSegment(
                                  value: policy.halfUnit,
                                  label: const Text('Half leave'))
                            ],
                            selected: {
                              units
                            },
                            onSelectionChanged: saving
                                ? null
                                : (values) =>
                                    update(() => units = values.first)),
                      ],
                      if ((selected == AttendanceStatus.half ||
                              selected == AttendanceStatus.partial) &&
                          !nonWorking) ...[
                        const SizedBox(height: 16),
                        Text(
                            'Leave: ${leave.toStringAsFixed(1)} ${policy.basis.label(leave)}'),
                        Slider(
                            value: leave.clamp(0, policy.fullUnit - units),
                            max: policy.fullUnit - units,
                            key: const ValueKey('plan-leave'),
                            divisions:
                                (policy.fullUnit * 2).ceil().clamp(1, 1000),
                            onChanged: saving
                                ? null
                                : (value) => update(() => leave = value)),
                      ],
                      if (selected == AttendanceStatus.partial) ...[
                        const SizedBox(height: 20),
                        Text(
                            'Partial: ${units.toStringAsFixed(1)} ${policy.basis.label(units)} of ${policy.fullUnit}'),
                        Slider(
                            key: const ValueKey('plan-units'),
                            value: units,
                            max: policy.fullUnit,
                            divisions:
                                (policy.fullUnit * 2).ceil().clamp(1, 1000),
                            onChanged: saving
                                ? null
                                : (value) => update(() {
                                      units = value;
                                      leave = leave
                                          .clamp(0, policy.fullUnit - units)
                                          .toDouble();
                                      if (value == 0) {
                                        selected = AttendanceStatus.absent;
                                      }
                                      if (value == policy.fullUnit) {
                                        selected = AttendanceStatus.full;
                                      }
                                    })),
                      ],
                      if (existing != null &&
                          (existing.policyVersionId !=
                                  planningPolicyKey(policy) ||
                              existing.calendarVersionId !=
                                  planningCalendarKey(calendar)))
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'Calendar changed. Review this plan before using it.',
                                style: TextStyle(color: Colors.red))),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(error!,
                                style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: saving ? null : () => save(),
                              icon: Icon(selected == AttendanceStatus.holiday
                                  ? Icons.beach_access_outlined
                                  : Icons.event_available_outlined),
                              label: Text(saving
                                  ? 'Saving...'
                                  : selected == AttendanceStatus.holiday
                                      ? 'Save holiday'
                                      : 'Save plan'))),
                    ]));
          }));
}

String statusText(AttendanceStatus status) => switch (status) {
      AttendanceStatus.full => 'Full',
      AttendanceStatus.half => 'Half day',
      AttendanceStatus.partial => 'Partial',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.holiday => 'Holiday',
      AttendanceStatus.leave => 'On Leave',
      AttendanceStatus.weeklyOff => 'Weekly Off',
      AttendanceStatus.none => 'Not recorded'
    };

Color statusColor(AttendanceStatus status) => switch (status) {
      AttendanceStatus.full => Colors.green,
      AttendanceStatus.half ||
      AttendanceStatus.partial =>
        const Color(0xFFF59E0B),
      AttendanceStatus.absent => const Color(0xFFDC2626),
      AttendanceStatus.holiday ||
      AttendanceStatus.leave =>
        const Color(0xFF2563EB),
      AttendanceStatus.weeklyOff => const Color(0xFF98A2B3),
      AttendanceStatus.none => Colors.grey
    };

IconData statusIcon(AttendanceStatus status) => switch (status) {
      AttendanceStatus.full => Icons.check_rounded,
      AttendanceStatus.half ||
      AttendanceStatus.partial =>
        Icons.timelapse_rounded,
      AttendanceStatus.absent => Icons.close_rounded,
      AttendanceStatus.holiday => Icons.beach_access_outlined,
      AttendanceStatus.leave => Icons.work_off_outlined,
      AttendanceStatus.weeklyOff => Icons.weekend,
      AttendanceStatus.none => Icons.remove_rounded
    };
String monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];

class _InstallPwaCard extends StatelessWidget {
  const _InstallPwaCard({required this.onInstall, required this.onDismiss});
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.install_mobile_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Install StandIn App',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold))),
                IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 36, bottom: 12),
              child: Text(
                  'Install StandIn for a faster, offline-ready experience on your home screen.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: onDismiss,
                    child: const Text('Maybe later',
                        style: TextStyle(color: Colors.white70))),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onInstall,
                  style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Install Now'),
                ),
              ],
            ),
          ],
        ),
      );
}
