import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'remote/firestore_user_remote.dart';

class UserRepository {
  UserRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreUserRemote _remote;

  Future<UserProfile?> getProfile(String uid) async {
    final row = await _database.getUserProfile(uid);
    if (row != null) {
      return UserProfile(
        uid: row.uid,
        displayName: row.displayName,
        role: AppRole.values.byName(row.role),
        mobile: row.mobile,
        activeFollowId: row.activeFollowId,
      );
    }
    return null;
  }

  Future<void> syncProfile(String uid) async {
    final profile = await _remote.watchProfile(uid).first;
    if (profile != null) {
      await _database.upsertUserProfile(UserProfileRowsCompanion.insert(
        uid: profile.uid,
        displayName: profile.displayName,
        role: profile.role.name,
        mobile: Value(profile.mobile),
        activeFollowId: Value(profile.activeFollowId),
        createdAt: DateTime.now(), // Firestore should have authoritative dates
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    // Write locally first
    await _database.upsertUserProfile(UserProfileRowsCompanion.insert(
      uid: profile.uid,
      displayName: profile.displayName,
      role: profile.role.name,
      mobile: Value(profile.mobile),
      activeFollowId: Value(profile.activeFollowId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
    // Remote write (idempotent)
    await _remote.createUserProfile(profile);
  }

  Future<bool> checkUsernameAvailable(String username) => _remote.isUsernameAvailable(username);

  Future<void> claimUsername(String username, String uid) => _remote.claimUsername(username, uid);

  Future<void> saveFollow(String uid, Follow follow) async {
    await _database.upsertFollow(FollowRowsCompanion.insert(
      id: follow.id,
      organizationId: follow.organizationId,
      scopeId: follow.scopeId,
      status: follow.status,
      followedAt: follow.followedAt,
      personalTargetPercent: Value(follow.personalTargetPercent),
    ));
    await _remote.putFollow(uid, follow);
  }
}
