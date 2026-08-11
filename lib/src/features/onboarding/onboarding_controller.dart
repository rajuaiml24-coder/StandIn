import 'dart:math';
import 'package:flutter/material.dart';
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
  security,
  organizationSearch,
  organizationCreate,
  organizationId,
  policyPreview,
  complete,
}

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required AuthService authService,
    required UserRepository userRepository,
    required OrganizationRepository organizationRepository,
  })  : _authService = authService,
        _userRepository = userRepository,
        _organizationRepository = organizationRepository;

  final AuthService _authService;
  final UserRepository _userRepository;
  final OrganizationRepository _organizationRepository;

  OnboardingStep _step = OnboardingStep.welcome;
  OnboardingStep get step => _step;

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

  String? _pin;
  String? get currentPin => _pin;

  bool _biometricsEnabled = false;
  bool get biometricsEnabled => _biometricsEnabled;

  Organization? _selectedOrganization;
  Organization? get selectedOrganization => _selectedOrganization;

  AttendancePolicy? _selectedPolicy;
  AttendancePolicy? get selectedPolicy => _selectedPolicy;

  String? _identificationNumber;
  String? get identificationNumber => _identificationNumber;

  bool _isCreatingNewOrganization = false;
  bool get isCreatingNewOrganization => _isCreatingNewOrganization;

  // Validators
  final nameValidator = NameValidator();
  final mobileValidator = MobileValidator();
  final pinValidator = PinValidator();
  final usernameValidator = UsernameValidator();
  final idValidator = IdValidator();
  final orgNameValidator = OrganizationNameValidator();

  void goToSignup() {
    _step = OnboardingStep.roleSelection;
    notifyListeners();
  }

  void login(String username, String pin) {
    if (usernameValidator.validate(username).isValid && 
        pinValidator.validate(pin).isValid) {
      _step = OnboardingStep.complete;
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
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _username = suggestion;
    _isCheckingUsername = false;
    notifyListeners();
  }

  Future<bool> checkUsernameAvailability(String username) async {
    // Isolated mock for later Firestore replacement
    await Future.delayed(const Duration(milliseconds: 300));
    return true; 
  }

  void confirmUsername() {
    _step = OnboardingStep.security;
    notifyListeners();
  }

  void completeSecurity(String pin, bool biometrics) {
    if (pinValidator.validate(pin).isValid) {
      _pin = pin;
      _biometricsEnabled = biometrics;
      _step = OnboardingStep.organizationSearch;
      notifyListeners();
    }
  }

  void selectOrganization(Organization org, AttendancePolicy policy) {
    _selectedOrganization = org;
    _selectedPolicy = policy;
    _isCreatingNewOrganization = false;
    _step = OnboardingStep.organizationId;
    notifyListeners();
  }

  void goToCreateOrganization() {
    _isCreatingNewOrganization = true;
    _step = OnboardingStep.organizationCreate;
    notifyListeners();
  }

  void createOrganization(String name, String? branch, AttendancePolicy policy) {
    final org = Organization(
      id: 'temp-${Random().nextInt(10000)}',
      name: name,
      type: _role == AppRole.student ? OrganizationType.college : OrganizationType.company,
      branch: branch,
      isVerified: false,
    );
    _selectedOrganization = org;
    _selectedPolicy = policy;
    _step = OnboardingStep.organizationId;
    notifyListeners();
  }

  void completeOrganizationId(String id) {
    if (idValidator.validate(id).isValid) {
      _identificationNumber = id.trim();
      _step = OnboardingStep.policyPreview;
      notifyListeners();
    }
  }

  Future<void> followOrganization() async {
    final uid = _authService.uid;
    if (uid == null) return;

    final follow = Follow(
      id: 'f-${DateTime.now().millisecondsSinceEpoch}',
      organizationId: _selectedOrganization!.id,
      scopeId: _selectedOrganization!.id, // Default to org id as scope for now
      status: 'active',
      followedAt: DateTime.now(),
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
      activeFollowId: follow.id,
    );

    await _userRepository.createProfile(profile);
    await _userRepository.saveFollow(uid, follow);
    await _organizationRepository.saveMembership(membership);

    _step = OnboardingStep.complete;
    notifyListeners();
  }

  void back() {
    if (_step == OnboardingStep.roleSelection) {
      _step = OnboardingStep.welcome;
    } else if (_step == OnboardingStep.profile) {
      _step = OnboardingStep.roleSelection;
    } else if (_step == OnboardingStep.usernameGeneration) {
      _step = OnboardingStep.profile;
    } else if (_step == OnboardingStep.security) {
      _step = OnboardingStep.usernameGeneration;
    } else if (_step == OnboardingStep.organizationSearch) {
      _step = OnboardingStep.security;
    } else if (_step == OnboardingStep.organizationCreate) {
      _step = OnboardingStep.organizationSearch;
    } else if (_step == OnboardingStep.organizationId) {
      _step = _isCreatingNewOrganization ? OnboardingStep.organizationCreate : OnboardingStep.organizationSearch;
    } else if (_step == OnboardingStep.policyPreview) {
      _step = OnboardingStep.organizationId;
    }
    notifyListeners();
  }

  void logout() {
    _step = OnboardingStep.welcome;
    _role = null;
    _displayName = '';
    _mobile = null;
    _pin = null;
    _biometricsEnabled = false;
    _selectedOrganization = null;
    _selectedPolicy = null;
    notifyListeners();
  }
}
