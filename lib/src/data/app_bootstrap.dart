import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/auth_service.dart';
import 'local/standin_database.dart';
import 'local_first_attendance_repository.dart';
import 'remote/firestore_attendance_remote.dart';
import 'sync/sync_engine.dart';
import '../features/attendance/attendance_controller.dart';
import '../domain/attendance.dart';
import '../domain/policy_engine.dart';

/// Production composition root after Firebase.initializeApp is configured per platform.
class AppBootstrap {
  AppBootstrap(this.database, this.authService, this.remote);
  final StandInDatabase database;
  final AuthService authService;
  final FirestoreAttendanceRemote remote;

  AttendanceController attendanceController({required String uid, required String organizationId, required String scopeId, required AttendancePolicy policy}) => 
    AttendanceController(LocalFirstAttendanceRepository(database, uid: uid, organizationId: organizationId, scopeId: scopeId), const PolicyEngine(), policy);

  SyncEngine syncEngine(String uid) => SyncEngine(database, remote, uid: uid);

  factory AppBootstrap.firebase(StandInDatabase database, AuthService authService) => AppBootstrap(database, authService, FirestoreAttendanceRemote(FirebaseFirestore.instance));
}
