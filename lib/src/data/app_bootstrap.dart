import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/auth_service.dart';
import 'local/standin_database.dart';
import 'local_first_attendance_repository.dart';
import 'remote/firestore_attendance_remote.dart';
import 'sync/sync_engine.dart';
import 'organization_repository.dart';
import '../features/attendance/attendance_controller.dart';
import '../domain/attendance.dart';
import '../domain/policy_engine.dart';

import 'remote/firestore_user_remote.dart';
import 'remote/firestore_org_remote.dart';

/// Production composition root after Firebase.initializeApp is configured per platform.
class AppBootstrap {
  AppBootstrap(this.database, this.authService, this.attendanceRemote, this.userRemote, this.orgRemote, this.orgRepository);
  final StandInDatabase database;
  final AuthService authService;
  final FirestoreAttendanceRemote attendanceRemote;
  final FirestoreUserRemote userRemote;
  final FirestoreOrgRemote orgRemote;
  final OrganizationRepository orgRepository;

  AttendanceController attendanceController({required String uid, required String organizationId, required String scopeId, required AttendancePolicy policy, required AttendanceCalendar calendar}) => 
    AttendanceController(LocalFirstAttendanceRepository(database, uid: uid, organizationId: organizationId, scopeId: scopeId), const PolicyEngine(), policy, calendar);

  SyncEngine syncEngine(String uid) => SyncEngine(
        database,
        attendanceRemote,
        userRemote,
        orgRemote,
        orgRepository,
        uid: uid,
      );

  factory AppBootstrap.firebase(StandInDatabase database, AuthService authService) {
    final fs = FirebaseFirestore.instance;
    final orgRemote = FirestoreOrgRemote(fs);
    return AppBootstrap(
      database, 
      authService, 
      FirestoreAttendanceRemote(fs),
      FirestoreUserRemote(fs),
      orgRemote,
      OrganizationRepository(database, orgRemote),
    );
  }
}
