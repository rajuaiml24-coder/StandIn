import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/attendance.dart';

class FirestoreOrgRemote {
  FirestoreOrgRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> putOrganization(Organization org, String uid) {
    final nameLower = org.name.trim().toLowerCase();
    final tokens = nameLower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    
    final data = {
      'name': org.name,
      'name_lowercase': nameLower,
      'name_tokens': tokens,
      'type': org.type.name,
      'branch': org.branch,
      'isVerified': org.isVerified,
      'isHolidayCalendarConfigured': org.isHolidayCalendarConfigured,
      'followerCount': org.followerCount,
      'activePolicyId': org.activePolicyId,
      'activeCalendarId': org.activeCalendarId,
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return _firestore.collection('organizations').doc(org.id).set(data, SetOptions(merge: true));
  }

  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    if (!doc.exists) return null;
    return _mapDoc(doc);
  }

  Future<List<Organization>> getPopularOrganizations(OrganizationType type) async {
    final snapshot = await _firestore.collection('organizations')
        .where('type', isEqualTo: type.name)
        .orderBy('followerCount', descending: true)
        .limit(15)
        .get();
    
    return snapshot.docs.map(_mapDoc).toList();
  }

  Future<void> incrementFollowerCount(String orgId) {
    return _firestore.collection('organizations').doc(orgId).update({
      'followerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Organization>> searchOrganizations(String query, OrganizationType type) async {
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return getPopularOrganizations(type);

    final Map<String, Organization> results = {};

    // 1. Prefix search on name_lowercase (for new/updated data)
    final endLower = search.substring(0, search.length - 1) + 
                String.fromCharCode(search.codeUnitAt(search.length - 1) + 1);
    
    final prefixSnapshot = await _firestore.collection('organizations')
        .where('type', isEqualTo: type.name)
        .where('name_lowercase', isGreaterThanOrEqualTo: search)
        .where('name_lowercase', isLessThan: endLower)
        .limit(10)
        .get();

    for (var doc in prefixSnapshot.docs) {
      results[doc.id] = _mapDoc(doc);
    }

    // 2. Keyword search on name_tokens (for new/updated data)
    final tokens = search.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (results.length < 10 && tokens.isNotEmpty) {
      final tokenSnapshot = await _firestore.collection('organizations')
          .where('type', isEqualTo: type.name)
          .where('name_tokens', arrayContains: tokens.first)
          .limit(10)
          .get();
      
      for (var doc in tokenSnapshot.docs) {
        if (!results.containsKey(doc.id)) {
          results[doc.id] = _mapDoc(doc);
        }
      }
    }

    // 3. Legacy Fallback: Prefix search on raw name (case-sensitive)
    if (results.length < 10) {
      final rawQuery = query.trim();
      final endRaw = rawQuery.substring(0, rawQuery.length - 1) + 
                  String.fromCharCode(rawQuery.codeUnitAt(rawQuery.length - 1) + 1);

      final legacySnapshot = await _firestore.collection('organizations')
          .where('type', isEqualTo: type.name)
          .where('name', isGreaterThanOrEqualTo: rawQuery)
          .where('name', isLessThan: endRaw)
          .limit(10)
          .get();

      for (var doc in legacySnapshot.docs) {
        if (!results.containsKey(doc.id)) {
          results[doc.id] = _mapDoc(doc);
        }
      }
    }

    final List<Organization> finalResults = results.values.toList();
    finalResults.sort((a, b) => b.followerCount.compareTo(a.followerCount));

    return finalResults.take(15).toList();
  }

  Organization _mapDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Organization(
      id: doc.id,
      name: data['name'] as String,
      type: OrganizationType.values.byName(data['type'] as String),
      branch: data['branch'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      isHolidayCalendarConfigured: data['isHolidayCalendarConfigured'] as bool? ?? false,
      followerCount: data['followerCount'] as int? ?? 0,
      activePolicyId: data['activePolicyId'] as String?,
      activeCalendarId: data['activeCalendarId'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }

  Future<void> putPolicy(String orgId, AttendancePolicy policy) =>
      _firestore.collection('organizations').doc(orgId).collection('policies').doc(policy.id).set({
        'version': policy.version,
        'effectiveFrom': Timestamp.fromDate(policy.effectiveFrom),
        'state': policy.state.name,
        'evaluationPeriod': policy.evaluationPeriod.name,
        'minimumPercent': policy.minimumPercent,
        'basis': policy.basis.name,
        'fullUnit': policy.fullUnit,
        'halfUnit': policy.halfUnit,
        'weeklyOffs': policy.weeklyOffs,
        'startDate': policy.startDate != null ? Timestamp.fromDate(policy.startDate!) : null,
        'endDate': policy.endDate != null ? Timestamp.fromDate(policy.endDate!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> putCalendar(String orgId, AttendanceCalendar calendar) =>
      _firestore.collection('organizations').doc(orgId).collection('calendars').doc(calendar.id).set({
        'version': calendar.version,
        'effectiveFrom': Timestamp.fromDate(calendar.effectiveFrom),
        'weeklyOffs': calendar.weeklyOffs,
        'offSaturdays': calendar.offSaturdays,
        'holidays': calendar.holidays.map((h) => h.toJson()).toList(),
        'isConfigured': calendar.isConfigured,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> putMembership(Membership membership) =>
      _firestore.collection('organizations').doc(membership.organizationId).collection('members').doc(membership.uid).set({
        'status': membership.status,
        'idNumber': membership.idNumber,
        'joinedAt': Timestamp.fromDate(membership.joinedAt),
        'verifiedAt': membership.verifiedAt != null ? Timestamp.fromDate(membership.verifiedAt!) : null,
      });

  Future<void> deleteMembership(String orgId, String uid) =>
      _firestore.collection('organizations').doc(orgId).collection('members').doc(uid).delete();

  Future<void> putScope(String orgId, Scope scope) =>
      _firestore.collection('organizations').doc(orgId).collection('scopes').doc(scope.id).set({
        'organizationId': scope.organizationId,
        'parentId': scope.parentId,
        'type': scope.type,
        'name': scope.name,
        'activePolicyId': scope.activePolicyId,
        'activeCalendarId': scope.activeCalendarId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<List<Scope>> getScopes(String orgId, {String? parentId}) async {
    var query = _firestore.collection('organizations').doc(orgId).collection('scopes');
    
    final snapshot = await (parentId == null 
        ? query.where('parentId', isNull: true).get()
        : query.where('parentId', isEqualTo: parentId).get());

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Scope(
        id: doc.id,
        organizationId: data['organizationId'] as String,
        parentId: data['parentId'] as String?,
        type: data['type'] as String,
        name: data['name'] as String,
        activePolicyId: data['activePolicyId'] as String?,
        activeCalendarId: data['activeCalendarId'] as String?,
      );
    }).toList();
  }

  Future<Scope?> getScope(String orgId, String scopeId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).collection('scopes').doc(scopeId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Scope(
      id: doc.id,
      organizationId: data['organizationId'] as String,
      parentId: data['parentId'] as String?,
      type: data['type'] as String,
      name: data['name'] as String,
      activePolicyId: data['activePolicyId'] as String?,
      activeCalendarId: data['activeCalendarId'] as String?,
    );
  }

  Future<AttendancePolicy?> getPolicy(String orgId, String policyId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).collection('policies').doc(policyId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AttendancePolicy(
      id: doc.id,
      version: data['version'] as int,
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      state: PolicyState.values.byName(data['state'] as String),
      evaluationPeriod: EvaluationPeriod.values.byName(data['evaluationPeriod'] as String),
      minimumPercent: (data['minimumPercent'] as num?)?.toDouble(),
      basis: CalculationBasis.values.byName(data['basis'] as String),
      fullUnit: (data['fullUnit'] as num).toDouble(),
      halfUnit: (data['halfUnit'] as num).toDouble(),
      weeklyOffs: (data['weeklyOffs'] as List).cast<int>(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      scopeId: data['scopeId'] as String?,
      organizationId: orgId,
    );
  }

  Future<AttendanceCalendar?> getCalendar(String orgId, String calendarId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).collection('calendars').doc(calendarId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AttendanceCalendar(
      id: doc.id,
      version: data['version'] as int,
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      weeklyOffs: (data['weeklyOffs'] as List).cast<int>(),
      offSaturdays: (data['offSaturdays'] as List).cast<int>(),
      holidays: (data['holidays'] as List).map((h) => Holiday.fromJson(h as Map<String, dynamic>)).toList(),
      isConfigured: data['isConfigured'] as bool? ?? false,
      organizationId: orgId,
      scopeId: data['scopeId'] as String?,
    );
  }
}
