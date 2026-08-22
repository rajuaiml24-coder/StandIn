import 'dart:math';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../../data/remote/firestore_attendance_remote.dart';
import '../../data/auth/auth_service.dart';
import '../../data/organization_repository.dart';
import '../../data/user_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/validators.dart';

enum OnboardingStep {
  welcome,
  roleSelection,
  profile,
  usernameGeneration,
  organizationSearch,
  organizationCreate,
  organizationId,
  policyDetection,
  policyPreview,
  policyConflict,
  setupUnit,
  setupPeriod,
  setupTarget,
  scopeBranch,
  scopeSemester,
  setupDates,
  setupSchedule,
  setupDaysOff,
  setupSaturday,
  complete,
}

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required AuthService authService,
    required UserRepository userRepository,
    required OrganizationRepository organizationRepository,
    required FirestoreAttendanceRemote attendanceRemote,
    OnboardingStep initialStep = OnboardingStep.welcome,
  })  : _authService = authService,
        _userRepository = userRepository,
        _organizationRepository = organizationRepository,
        _attendanceRemote = attendanceRemote,
        _step = initialStep;

  final AuthService _authService;
  final UserRepository _userRepository;
  final OrganizationRepository _organizationRepository;
  final FirestoreAttendanceRemote _attendanceRemote;

  OnboardingStep _step;
  OnboardingStep get step => _step;

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  String? _authError;
  String? get authError => _authError;

  AppRole? _role;
  AppRole? get role => _role;

  String _displayName = '';
  String get displayName => _displayName;

  String? _mobile;
  String? get mobile => _mobile;

  String? _username;
  String? get username => _username;

  bool _isCheckingUsername = false;
  bool get isCheckingUsername => _isCheckingUsername;

  Organization? _selectedOrganization;
  Organization? get selectedOrganization => _selectedOrganization;

  Scope? _selectedBranch;
  Scope? get selectedBranch => _selectedBranch;

  Scope? _selectedSemester;
  Scope? get selectedSemester => _selectedSemester;

  AttendancePolicy? _officialPolicy;
  AttendancePolicy? get officialPolicy => _officialPolicy;

  AttendanceCalendar? _officialCalendar;
  AttendanceCalendar? get officialCalendar => _officialCalendar;

  // Temporary policy builder state
  CalculationBasis? _basis;
  CalculationBasis? get basis => _basis;

  EvaluationPeriod? _evaluationPeriod;
  EvaluationPeriod? get evaluationPeriod => _evaluationPeriod;

  double? _targetPercent;
  double? get targetPercent => _targetPercent;

  double? _fullUnit;
  double? get fullUnit => _fullUnit;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  List<int> _weeklyOffs = [];
  List<int> get weeklyOffs => _weeklyOffs;

  List<int> _offSaturdays = [];
  List<int> get offSaturdays => _offSaturdays;

  bool _isCalendarConfigured = false;
  bool get isCalendarConfigured => _isCalendarConfigured;

  String? _identificationNumber;
  String? get identificationNumber => _identificationNumber;

  bool _isCreatingNewOrganization = false;
  bool get isCreatingNewOrganization => _isCreatingNewOrganization;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Validators
  final nameValidator = NameValidator();
  final mobileValidator = MobileValidator();
  final usernameValidator = UsernameValidator();
  final idValidator = IdValidator();
  final orgNameValidator = OrganizationNameValidator();

  Future<void> signInWithGoogle() async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      _isAuthenticating = false;
      if (credential == null) {
        notifyListeners();
        return; // Cancelled
      }
      notifyListeners();
      // No more navigation logic here.
      // StandInApp listens to authStateChanges and will handle the transition.
    } catch (e) {
      _authError = e.toString();
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  void start(AppRole role) {
    _role = role;
    _step = OnboardingStep.profile;
    notifyListeners();
  }

  Future<void> completeProfile(String name, String? mobile) async {
    if (nameValidator.validate(name).isValid && 
        (mobile == null || mobile.isEmpty || mobileValidator.validate(mobile).isValid)) {
      _displayName = name.trim();
      _mobile = mobile?.trim();
      await generateUsernameSuggestion();
      _step = OnboardingStep.usernameGeneration;
      notifyListeners();
    }
  }

  Future<void> generateUsernameSuggestion() async {
    _isCheckingUsername = true;
    notifyListeners();
    final base = _displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final suffix = Random().nextInt(999).toString().padLeft(3, '0');
    final suggestion = '${base.substring(0, min(base.length, 11))}_$suffix';
    _username = suggestion;
    _isCheckingUsername = false;
    notifyListeners();
  }

  Future<bool> checkUsernameAvailability(String username) async {
    return _userRepository.checkUsernameAvailable(username);
  }

  void confirmUsername() {
    // Finding Attendance Rules phase
    _step = OnboardingStep.organizationSearch;
    notifyListeners();
  }

  Future<void> selectOrganization(Organization org) async {
    _selectedOrganization = org;
    _isCreatingNewOrganization = false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Direct discovery of organization-level rules (Direct Follow Flow)
      _officialPolicy = await _organizationRepository.getOfficialPolicyForScope(
        org.id, 
        'global', 
        activePolicyId: org.activePolicyId,
      );
      _officialCalendar = await _organizationRepository.getOfficialCalendarForScope(
        org.id, 
        'global', 
        activeCalendarId: org.activeCalendarId,
      );
      
      if (_officialPolicy != null) {
        _evaluationPeriod = _officialPolicy!.evaluationPeriod;
        _basis = _officialPolicy!.basis;
      } else {
        // Fallback for UI pre-selection if no organization rules yet (Safe defaults)
        _evaluationPeriod = EvaluationPeriod.monthly;
        _basis = CalculationBasis.hours;
      }
      
      // Check for conflict (Existing personal override)
      final resolved = await _organizationRepository.getResolvedPolicy(
        uid: _authService.uid ?? 'unknown', 
        organizationId: org.id, 
        scopeId: 'global',
      );

      if (resolved?.state == PolicyState.personal) {
        _step = OnboardingStep.policyConflict;
      } else {
        _step = OnboardingStep.policyPreview;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goToCreateOrganization() {
    _isCreatingNewOrganization = true;
    _step = OnboardingStep.organizationCreate;
    notifyListeners();
  }

  void createOrganization(String name, String? branch, AttendancePolicy? policy) {
    final org = Organization(
      id: 'org-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _role == AppRole.student ? OrganizationType.college : OrganizationType.company,
      branch: branch,
      isVerified: false,
      followerCount: 1,
      createdBy: _authService.uid,
    );
    _selectedOrganization = org;
    _officialPolicy = policy;

    // Save metadata immediately for discovery
    final uid = _authService.uid;
    if (uid != null) {
      _organizationRepository.saveOrganization(org, uid);
    }

    // Path C: Creator Flow -> Direct to Rule Setup (No Branch/Semester required)
    _step = OnboardingStep.setupUnit;
    notifyListeners();
  }

  Future<List<Organization>> searchOrganizations(String query) async {
    if (_role == null) return [];
    final type = _role == AppRole.student ? OrganizationType.college : OrganizationType.company;
    return _organizationRepository.searchOrganizations(query, type);
  }

  Future<List<Scope>> getScopesForParent(String? parentId) async {
    if (_selectedOrganization == null) return [];
    return _organizationRepository.getScopesForParent(_selectedOrganization!.id, parentId);
  }

  void selectBranch(Scope? branch) {
    _selectedBranch = branch;
    _step = OnboardingStep.scopeSemester;
    notifyListeners();
  }

  void createBranch(String name) {
    final id = Scope.generateId(_selectedOrganization!.id, 'branch', name);
    final scope = Scope(
      id: id,
      organizationId: _selectedOrganization!.id,
      type: 'branch',
      name: name,
    );
    _selectedBranch = scope;
    _step = OnboardingStep.scopeSemester;
    notifyListeners();
  }

  void selectSemester(Scope? semester) {
    _selectedSemester = semester;
    _step = OnboardingStep.organizationId;
    notifyListeners();
  }

  void createSemester(String name) {
    final id = Scope.generateId(_selectedOrganization!.id, 'semester', name, _selectedBranch?.id);
    final scope = Scope(
      id: id,
      organizationId: _selectedOrganization!.id,
      parentId: _selectedBranch?.id,
      type: 'semester',
      name: name,
    );
    _selectedSemester = scope;
    _step = OnboardingStep.organizationId;
    notifyListeners();
  }

  Future<void> completeOrganizationId(String id) async {
    if (idValidator.validate(id).isValid) {
      _identificationNumber = id.trim();
      
      // Simple path: After ID, we either Preview Official Policy or start Personal Setup
      if (_officialPolicy != null) {
        _step = OnboardingStep.policyPreview;
      } else {
        _step = OnboardingStep.setupUnit;
      }
      notifyListeners();
    }
  }

  Future<void> useOfficialPolicy() async {
    _basis = null; // Clear personal overrides to ensure inheritance
    
    final isCustomPeriod = _officialPolicy != null && _evaluationPeriod != _officialPolicy!.evaluationPeriod;
    
    if (isCustomPeriod) {
      _step = OnboardingStep.setupTarget;
      notifyListeners();
    } else {
      await followOrganization();
    }
  }

  Future<void> followWithPersonalSettings() async {
    _step = OnboardingStep.setupUnit;
    notifyListeners();
  }

  Future<void> keepPersonalSettings() async {
    await followOrganization();
  }

  void selectBasis(CalculationBasis basis) {
    _basis = basis;
    _step = OnboardingStep.setupPeriod;
    notifyListeners();
  }

  void selectPeriod(EvaluationPeriod period) {
    _evaluationPeriod = period;
    if (_step == OnboardingStep.setupPeriod) {
      _step = OnboardingStep.setupTarget;
    }
    notifyListeners();
  }

  Future<void> setTarget(double? percent) async {
    _targetPercent = percent;
    
    // For Followers: Target is the last step unless it's a date-based period
    final isFollower = !_isCreatingNewOrganization;
    final needsDates = _evaluationPeriod == EvaluationPeriod.semester || _evaluationPeriod == EvaluationPeriod.custom;

    if (isFollower && !needsDates) {
      await followOrganization();
      return;
    }

    if (needsDates) {
      _step = OnboardingStep.setupDates;
    } else {
      _step = OnboardingStep.setupSchedule;
    }
    notifyListeners();
  }

  Future<void> setDates(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    
    if (!_isCreatingNewOrganization) {
      await followOrganization();
      return;
    }
    
    _step = OnboardingStep.setupSchedule;
    notifyListeners();
  }

  Future<void> completeSchedule({double? fullUnit, DateTime? start, DateTime? end}) async {
    if (_basis == CalculationBasis.days) {
      _fullUnit = 1.0;
    } else {
      _fullUnit = fullUnit;
    }
    if (start != null) _startDate = start;
    if (end != null) _endDate = end;
    _step = OnboardingStep.setupDaysOff;
    notifyListeners();
  }

  void selectDaysOff(List<int> offDays) {
    _weeklyOffs = offDays;
    _isCalendarConfigured = true;
    _step = OnboardingStep.setupSaturday;
    notifyListeners();
  }

  void selectSaturdayOption(bool everySatOff, {List<int>? specificSaturdays}) {
    if (everySatOff) {
      if (!_weeklyOffs.contains(DateTime.saturday)) {
        _weeklyOffs.add(DateTime.saturday);
      }
      _offSaturdays = [];
    } else {
      _weeklyOffs.remove(DateTime.saturday);
      _offSaturdays = specificSaturdays ?? [];
    }
    _step = OnboardingStep.complete;
    followOrganization();
    notifyListeners();
  }

  Future<void> followOrganization() async {
    final uid = _authService.uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_username != null) {
        await _userRepository.claimUsername(_username!, uid);
      }

      // Determine scope
      final scopeId = _selectedSemester?.id ?? _selectedBranch?.id ?? 'global';

      // Prepare personal calendar from official template if following existing org
      var personalWeeklyOffs = _weeklyOffs;
      var personalOffSaturdays = _offSaturdays;
      var calendarConfigured = _isCalendarConfigured;

      if (!_isCreatingNewOrganization && _officialCalendar != null) {
        personalWeeklyOffs = _officialCalendar!.weeklyOffs;
        personalOffSaturdays = _officialCalendar!.offSaturdays;
        calendarConfigured = true;
      }

      // Prepare domain models
      final followId = 'f-${DateTime.now().millisecondsSinceEpoch}';
      final follow = Follow(
        id: followId,
        organizationId: _selectedOrganization!.id,
        scopeId: scopeId,
        status: 'active',
        followedAt: DateTime.now(),
        personalBasis: _basis,
        personalEvaluationPeriod: _evaluationPeriod,
        personalTargetPercent: _targetPercent,
        personalFullUnit: _fullUnit,
        personalHalfUnit: _fullUnit != null ? _fullUnit! / 2 : null,
        personalStartDate: _startDate,
        personalEndDate: _endDate,
        personalWeeklyOffs: jsonEncode(personalWeeklyOffs),
        personalOffSaturdays: jsonEncode(personalOffSaturdays),
        personalHolidays: jsonEncode([]),
        isPersonalCalendarConfigured: calendarConfigured,
      );

      final membership = Membership(
        uid: uid,
        organizationId: _selectedOrganization!.id,
        status: 'follower',
        idNumber: _identificationNumber,
        joinedAt: DateTime.now(),
      );

      final profile = UserProfile(
        uid: uid,
        displayName: _displayName,
        mobile: _mobile,
        role: _role!,
        activeFollowId: followId,
      );

      // 1. Save Profile (Always local first)
      await _userRepository.createProfile(profile);

      // 2. Handle Organization Setup vs. Simple Join
      if (_isCreatingNewOrganization) {
        // Full setup for the CREATOR only (Path: Create Org -> Rules -> Create & Follow)
        // No Branch/Semester required for initial creation.
        final List<Scope> newScopes = [];
        
        final basis = _basis ?? CalculationBasis.hours;
        final fullUnit = basis == CalculationBasis.days ? 1.0 : (_fullUnit ?? (basis == CalculationBasis.hours ? 8.0 : 6.0));

        final policy = _officialPolicy ?? AttendancePolicy(
          id: 'policy-global',
          version: 1,
          effectiveFrom: DateTime.now(),
          state: PolicyState.official,
          evaluationPeriod: _evaluationPeriod ?? EvaluationPeriod.monthly,
          basis: basis,
          fullUnit: fullUnit,
          halfUnit: fullUnit / 2,
          minimumPercent: _targetPercent,
          startDate: _startDate,
          endDate: _endDate,
          scopeId: 'global',
          organizationId: _selectedOrganization!.id,
        );

        final calendar = AttendanceCalendar(
          id: 'cal-global',
          version: 1,
          effectiveFrom: DateTime.now(),
          weeklyOffs: personalWeeklyOffs,
          offSaturdays: personalOffSaturdays,
          isConfigured: true,
          scopeId: 'global',
          organizationId: _selectedOrganization!.id,
        );

        // ENQUEUE ALL 5: Org, Policy, Calendar, Membership, Follow
        await _organizationRepository.setupOrganization(
          org: _selectedOrganization!,
          policy: policy,
          calendar: calendar,
          membership: membership,
          follow: follow,
          uid: uid,
          scopes: newScopes,
        );
      } else {
        // Simple join for the FOLLOWER (Path: Search -> Select -> Preview -> Follow)
        // 1. Ensure authoritative metadata (activePolicyId) is cached locally for resolution
        await _organizationRepository.saveOrganizationMetadata(_selectedOrganization!);

        // 2. Resolve final Follow record with smart overrides
        // Only set personal overrides if the user actually changed them from organization defaults
        final effectiveFollow = follow.copyWith(
          personalBasis: _basis == _officialPolicy?.basis ? null : _basis,
          personalEvaluationPeriod: _evaluationPeriod == _officialPolicy?.evaluationPeriod ? null : _evaluationPeriod,
        );

        await _userRepository.saveFollow(uid, effectiveFollow);
        await _organizationRepository.saveMembership(membership);
        await _organizationRepository.incrementFollowerCount(_selectedOrganization!.id);
      }

      _step = OnboardingStep.complete;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void back() {
    switch (_step) {
      case OnboardingStep.welcome:
        break;
      case OnboardingStep.roleSelection:
        _step = OnboardingStep.welcome;
        break;
      case OnboardingStep.profile:
        _step = OnboardingStep.roleSelection;
        break;
      case OnboardingStep.usernameGeneration:
        _step = OnboardingStep.profile;
        break;
      case OnboardingStep.organizationSearch:
        _step = OnboardingStep.usernameGeneration;
        break;
      case OnboardingStep.organizationCreate:
        _step = OnboardingStep.organizationSearch;
        break;
      case OnboardingStep.policyPreview:
        _step = _isCreatingNewOrganization ? OnboardingStep.organizationCreate : OnboardingStep.organizationSearch;
        break;
      case OnboardingStep.setupUnit:
        _step = OnboardingStep.organizationCreate;
        break;
      case OnboardingStep.setupPeriod:
        _step = OnboardingStep.setupUnit;
        break;
      case OnboardingStep.setupTarget:
        _step = OnboardingStep.setupPeriod;
        break;
      case OnboardingStep.setupDates:
        _step = OnboardingStep.setupTarget;
        break;
      case OnboardingStep.setupSchedule:
        _step = (_evaluationPeriod == EvaluationPeriod.semester || _evaluationPeriod == EvaluationPeriod.custom)
            ? OnboardingStep.setupDates
            : OnboardingStep.setupTarget;
        break;
      case OnboardingStep.setupDaysOff:
        _step = OnboardingStep.setupSchedule;
        break;
      case OnboardingStep.setupSaturday:
        _step = OnboardingStep.setupDaysOff;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    final uid = _authService.uid;
    if (uid == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Re-authenticate (Mandatory for user.delete())
      await _authService.reauthenticateWithGoogle();

      // 2. Purge Remote Data
      await _userRepository.purgeRemoteData(uid, _organizationRepository, _attendanceRemote);

      // 3. Delete Firebase Auth User
      // We don't call logout here because we want to trigger user.delete()
      final user = auth.FirebaseAuth.instance.currentUser;
      await user?.delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _step = OnboardingStep.welcome;
    _isAuthenticating = false;
    _isLoading = false;
    _role = null;
    _displayName = '';
    _mobile = null;
    _selectedOrganization = null;
    _officialPolicy = null;
    _basis = null;
    _evaluationPeriod = null;
    _targetPercent = null;
    notifyListeners();
  }
}
