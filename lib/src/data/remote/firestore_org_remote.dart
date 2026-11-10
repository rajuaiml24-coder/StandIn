import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../domain/attendance.dart';
import '../../domain/calendar_updates.dart';
import '../../domain/shared_rules.dart';

class FirestoreOrgRemote {
  FirestoreOrgRemote(this._firestore);
  final FirebaseFirestore _firestore;
  Future<bool> sharedRulePublishingEnabled() async =>
      (await _firestore
              .doc('configuration/sharedRules')
              .get(const GetOptions(source: Source.server)))
          .data()?['enabled'] ==
      true;

  Stream<int> watchRuleVersion(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .snapshots()
      .map((doc) => (doc.data()?['latestRuleRevision'] as num?)?.toInt() ?? 0)
      .distinct();
  Future<RuleRevision?> nextRuleRevision(String orgId, int after) async {
    final docs = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('ruleRevisions')
        .orderBy('version')
        .startAfter([after])
        .limit(1)
        .get();
    return docs.docs.isEmpty
        ? null
        : RuleRevision.fromJson(docs.docs.first.id, docs.docs.first.data());
  }

  Future<(SharedRules, int)> sharedRulesSnapshot(String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    if (!doc.exists) throw StateError('Organization is unavailable');
    final version = (doc.data()?['latestRuleRevision'] as num?)?.toInt() ?? 0;
    if (version > 0) {
      final revision = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('ruleRevisions')
          .doc('rules-${version.toString().padLeft(10, '0')}')
          .get();
      return (
        RuleRevision.fromJson(revision.id, revision.data()!).rules,
        version
      );
    }
    final policy = await getPolicy(
        orgId, doc.data()?['activePolicyId'] as String? ?? 'policy-global');
    if (policy == null) throw StateError('Organization rules are unavailable');
    final (_, calendar, _) = await sharedCalendarSnapshot(orgId);
    return (
      SharedRules(
          policy.copyWith(organizationId: orgId, scopeId: 'global'), calendar),
      0
    );
  }

  Future<RuleRevision> publishRules(
      String orgId,
      String uid,
      SharedRules before,
      SharedRules next,
      int baseVersion,
      DateTime effectiveDate) async {
    next.validate();
    final changes = next.changesFrom(before);
    if (changes.isEmpty) throw StateError('No changes to publish');
    final tomorrow = DateTime.now();
    final activation =
        ruleActivationDate(before.policy, next.policy, effectiveDate, tomorrow);
    if (calendarDayKey(activation) != calendarDayKey(effectiveDate)) {
      throw StateError(
          'Choose ${activation.toIso8601String().substring(0, 10)} or a later compatible period start');
    }
    if (effectiveDate
        .isBefore(DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 1))) {
      throw StateError('Choose an effective date from tomorrow onwards');
    }
    return _firestore.runTransaction((tx) async {
      final org = _firestore.collection('organizations').doc(orgId);
      final gate = await tx.get(_firestore.doc('configuration/sharedRules'));
      if (gate.data()?['enabled'] != true) {
        throw StateError(
            'Shared rule publishing will be enabled with the next tested app release. Your draft is unchanged.');
      }
      final doc = await tx.get(org);
      if (doc.data()?['createdBy'] != uid ||
          (doc.data()?['latestRuleRevision'] ?? 0) != baseVersion) {
        throw StateError('Shared rules changed. Reload before publishing');
      }
      if (baseVersion > 0) {
        final previous = await tx.get(org
            .collection('ruleRevisions')
            .doc('rules-${baseVersion.toString().padLeft(10, '0')}'));
        if (DateTime.parse(previous.data()!['effectiveDate'] as String)
            .isAfter(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
          throw StateError(
              'An update is already scheduled. Publish the next update after it starts.');
        }
      } else {
        if (before.policy.id != doc.data()?['activePolicyId'] ||
            before.calendar.id !=
                (doc.data()?['activeCalendarId'] ?? 'unconfigured')) {
          throw StateError('Shared rules changed. Reload before publishing');
        }
      }
      final version = baseVersion + 1;
      final id = 'rules-${version.toString().padLeft(10, '0')}';
      final revision = RuleRevision(
          id: id,
          version: version,
          author: uid,
          before: before,
          rules: next,
          changes: changes,
          effectiveDate: effectiveDate);
      tx.set(org.collection('ruleRevisions').doc(id), {
        ...revision.toJson(),
        'baseVersion': baseVersion,
        'effectiveAt': Timestamp.fromDate(effectiveDate),
        'publishedAt': FieldValue.serverTimestamp()
      });
      // Do not replace legacy pointers: older clients cannot consent to full-rule updates.
      tx.update(org, {
        'latestRuleRevision': version,
        'latestRuleId': id,
        'sharedRulesSchema': revision.schema,
        'updatedAt': FieldValue.serverTimestamp()
      });
      return revision;
    });
  }

  Stream<int> watchCalendarRevisionVersion(String orgId) => _firestore
      .collection('organizations')
      .doc(orgId)
      .snapshots()
      .map((doc) =>
          (doc.data()?['latestCalendarRevision'] as num?)?.toInt() ?? 0)
      .distinct();

  Future<int> calendarRevisionVersion(String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    return (doc.data()?['latestCalendarRevision'] as num?)?.toInt() ?? 0;
  }

  Future<(Organization, AttendanceCalendar, int)> sharedCalendarSnapshot(
      String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    if (!doc.exists) throw StateError('Organization is unavailable');
    final org = _mapDoc(doc);
    final calendar = org.activeCalendarId == null
        ? null
        : await getCalendar(orgId, org.activeCalendarId!);
    return (
      org,
      (calendar ?? AttendanceCalendar.unconfigured)
          .copyWith(organizationId: orgId, scopeId: 'global'),
      (doc.data()?['latestCalendarRevision'] as num?)?.toInt() ?? 0
    );
  }

  Future<CalendarRevision?> nextCalendarRevision(
      String orgId, int after) async {
    final docs = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('calendarRevisions')
        .orderBy('version')
        .startAfter([after])
        .limit(1)
        .get();
    if (docs.docs.isEmpty) return null;
    return CalendarRevision.fromJson(
        docs.docs.first.id, docs.docs.first.data());
  }

  Future<CalendarRevision> publishCalendarHolidays(String orgId, String uid,
          AttendanceCalendar base, List<Holiday> holidays) =>
      _firestore.runTransaction((tx) async {
        final org = _firestore.collection('organizations').doc(orgId);
        final doc = await tx.get(org);
        if (doc.data()?['createdBy'] != uid) {
          throw StateError(
              'Only the organization creator can publish holidays');
        }
        if (doc.data()?['activeCalendarId'] != base.id &&
            !(doc.data()?['activeCalendarId'] == null &&
                base.id == 'unconfigured')) {
          throw StateError('Shared calendar changed. Reload before publishing');
        }
        final version =
            ((doc.data()?['latestCalendarRevision'] as num?)?.toInt() ?? 0) + 1;
        final id = 'revision-${version.toString().padLeft(10, '0')}';
        final before = {
          for (final h in base.holidays) calendarDayKey(h.date): h.toJson()
        };
        final after = {
          for (final h in holidays) calendarDayKey(h.date): h.toJson()
        };
        final changes = <String, Object?>{
          for (final key in {...before.keys, ...after.keys})
            if (!sameCalendarValue(before[key], after[key])) key: after[key]
        };
        if (changes.isEmpty) throw StateError('No holiday changes to publish');
        final calendar = AttendanceCalendar(
            id: id,
            version: version,
            effectiveFrom: DateTime.now(),
            weeklyOffs: base.weeklyOffs,
            offSaturdays: base.offSaturdays,
            holidays: holidays,
            isConfigured: true,
            organizationId: orgId,
            scopeId: 'global');
        final revision = CalendarRevision(
            id: id,
            version: version,
            author: uid,
            calendar: calendar,
            changes: changes);
        tx.set(org.collection('calendarRevisions').doc(id), {
          'version': version,
          'author': uid,
          'baseCalendarId': base.id,
          'calendar': calendarJson(calendar),
          'changes': changes,
          'publishedAt': FieldValue.serverTimestamp()
        });
        tx.set(org.collection('calendars').doc(id), {
          'version': version,
          'effectiveFrom': Timestamp.fromDate(calendar.effectiveFrom),
          'weeklyOffs': calendar.weeklyOffs,
          'offSaturdays': calendar.offSaturdays,
          'holidays': holidays.map((h) => h.toJson()).toList(),
          'isConfigured': true,
          'scopeId': 'global',
          'immutableRevision': true,
          'updatedAt': FieldValue.serverTimestamp()
        });
        tx.update(org, {
          'activeCalendarId': id,
          'latestCalendarRevision': version,
          'isHolidayCalendarConfigured': true,
          'updatedAt': FieldValue.serverTimestamp()
        });
        return revision;
      });

  Future<void> putOrganization(Organization org, String uid) =>
      _firestore.runTransaction((transaction) async {
        final reference = _firestore.collection('organizations').doc(org.id);
        final existing = await transaction.get(reference);
        final nameLower = org.name.trim().toLowerCase();
        final tokens =
            nameLower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

        final data = {
          'name': org.name,
          'name_lowercase': nameLower,
          'name_tokens': tokens,
          'type': org.type.name,
          'branch': org.branch,
          'isVerified': org.isVerified,
          'isHolidayCalendarConfigured': org.isHolidayCalendarConfigured,
          'activePolicyId': org.activePolicyId,
          'activeCalendarId': org.activeCalendarId,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!existing.exists) {
          transaction
              .set(reference, {...data, 'createdBy': uid, 'followerCount': 0});
        } else {
          transaction.update(reference, data);
        }
      });

  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    if (!doc.exists) return null;
    return _mapDoc(doc);
  }

  Future<List<Organization>> getPopularOrganizations(
      OrganizationType type) async {
    final snapshot = await _firestore
        .collection('organizations')
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

  Future<List<Organization>> searchOrganizations(
      String query, OrganizationType type) async {
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return getPopularOrganizations(type);

    final Map<String, Organization> results = {};

    // 1. Prefix search on name_lowercase (for new/updated data)
    final endLower = search.substring(0, search.length - 1) +
        String.fromCharCode(search.codeUnitAt(search.length - 1) + 1);

    final prefixSnapshot = await _firestore
        .collection('organizations')
        .where('type', isEqualTo: type.name)
        .where('name_lowercase', isGreaterThanOrEqualTo: search)
        .where('name_lowercase', isLessThan: endLower)
        .limit(10)
        .get();

    for (var doc in prefixSnapshot.docs) {
      results[doc.id] = _mapDoc(doc);
    }

    // 2. Keyword search on name_tokens (for new/updated data)
    final tokens =
        search.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (results.length < 10 && tokens.isNotEmpty) {
      final tokenSnapshot = await _firestore
          .collection('organizations')
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

      final legacySnapshot = await _firestore
          .collection('organizations')
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
    final followerCount = (data['followerCount'] as num?)?.toInt() ?? 0;

    if (kDebugMode) {
      debugPrint(
          '[FirestoreOrgRemote] Read followerCount: $followerCount for org: ${doc.id}');
    }

    return Organization(
      id: doc.id,
      name: data['name'] as String,
      type: OrganizationType.values.byName(data['type'] as String),
      branch: data['branch'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      isHolidayCalendarConfigured:
          data['isHolidayCalendarConfigured'] as bool? ?? false,
      followerCount: followerCount,
      activePolicyId: data['activePolicyId'] as String?,
      activeCalendarId: data['activeCalendarId'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }

  Future<void> putPolicy(String orgId, AttendancePolicy policy) => _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('policies')
          .doc(policy.id)
          .set({
        'version': policy.version,
        'effectiveFrom': Timestamp.fromDate(policy.effectiveFrom),
        'state': policy.state.name,
        'evaluationPeriod': policy.evaluationPeriod.name,
        'minimumPercent': policy.minimumPercent,
        'basis': policy.basis.name,
        'fullUnit': policy.fullUnit,
        'halfUnit': policy.halfUnit,
        'leaveTreatment': policy.leaveTreatment.name,
        'weekOffCredit': policy.weekOffCredit,
        'oneVisitFullDay': policy.oneVisitFullDay,
        'holidayCredit': policy.holidayCredit,
        'weeklyOffs': policy.weeklyOffs,
        'scopeId': policy.scopeId ?? 'global',
        'startDate': policy.startDate != null
            ? Timestamp.fromDate(policy.startDate!)
            : null,
        'endDate':
            policy.endDate != null ? Timestamp.fromDate(policy.endDate!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> putCalendar(String orgId, AttendanceCalendar calendar) =>
      _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('calendars')
          .doc(calendar.id)
          .set({
        'version': calendar.version,
        'effectiveFrom': Timestamp.fromDate(calendar.effectiveFrom),
        'weeklyOffs': calendar.weeklyOffs,
        'offSaturdays': calendar.offSaturdays,
        'holidays': calendar.holidays.map((h) => h.toJson()).toList(),
        'isConfigured': calendar.isConfigured,
        'scopeId': calendar.scopeId ?? 'global',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> putMembership(Membership membership) => joinOrganizationAtomic(
      orgId: membership.organizationId, membership: membership);

  Future<void> joinOrganizationAtomic({
    required String orgId,
    required Membership membership,
  }) {
    return _firestore.runTransaction((transaction) async {
      final memberRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(membership.uid);
      final orgRef = _firestore.collection('organizations').doc(orgId);

      final memberSnapshot = await transaction.get(memberRef);

      if (!memberSnapshot.exists) {
        transaction.set(memberRef, {
          'status': membership.status,
          'idNumber': membership.idNumber,
          'joinedAt': Timestamp.fromDate(membership.joinedAt),
          'verifiedAt': membership.verifiedAt != null
              ? Timestamp.fromDate(membership.verifiedAt!)
              : null,
        });

        transaction.update(orgRef, {
          'followerCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> leaveOrganizationAtomic({
    required String orgId,
    required String uid,
  }) {
    return _firestore.runTransaction((transaction) async {
      final memberRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid);
      final orgRef = _firestore.collection('organizations').doc(orgId);

      final memberSnapshot = await transaction.get(memberRef);
      final organization = await transaction.get(orgRef);

      if (memberSnapshot.exists) {
        transaction.delete(memberRef);
        if (organization.exists) {
          final count =
              (organization.data()?['followerCount'] as num?)?.toInt() ?? 0;
          transaction.update(orgRef, {
            'followerCount': count > 0 ? count - 1 : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<int> getAuthoritativeMemberCount(String orgId) async {
    final snapshot = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> updateFollowerCount(String orgId, int count) {
    return _firestore.collection('organizations').doc(orgId).update({
      'followerCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMembership(String orgId, String uid) => _firestore
      .collection('organizations')
      .doc(orgId)
      .collection('members')
      .doc(uid)
      .delete();

  Future<void> putScope(String orgId, Scope scope) =>
      _firestore.runTransaction((transaction) async {
        final reference = _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('scopes')
            .doc(scope.id);
        final previous = await transaction.get(reference);
        if (previous.exists &&
            previous.data()?['createdBy'] != scope.createdBy) {
          throw StateError('A group with this name already exists');
        }
        final data = {
          'organizationId': scope.organizationId,
          'parentId': scope.parentId,
          'type': scope.type,
          'name': scope.name,
          'activePolicyId': scope.activePolicyId,
          'activeCalendarId': scope.activeCalendarId,
          'isArchived': scope.isArchived,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (previous.exists) {
          transaction.update(reference, data);
        } else {
          transaction.set(reference,
              {...data, 'createdBy': scope.createdBy, 'followerCount': 0});
        }
      });

  Future<List<Scope>> getScopes(String orgId, {String? parentId}) async {
    var query =
        _firestore.collection('organizations').doc(orgId).collection('scopes');

    final snapshot = await (parentId == null
        ? query.where('parentId', isNull: true).get()
        : query.where('parentId', isEqualTo: parentId).get());

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return Scope(
            id: doc.id,
            organizationId: data['organizationId'] as String,
            parentId: data['parentId'] as String?,
            type: data['type'] as String,
            name: data['name'] as String,
            activePolicyId: data['activePolicyId'] as String?,
            activeCalendarId: data['activeCalendarId'] as String?,
            followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
            createdBy: data['createdBy'] as String?,
            isArchived: data['isArchived'] as bool? ?? false,
          );
        })
        .where((scope) => !scope.isArchived)
        .toList()
      ..sort((a, b) {
        final popularity = b.followerCount.compareTo(a.followerCount);
        return popularity != 0
            ? popularity
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  Future<Scope?> getScope(String orgId, String scopeId) async {
    final doc = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('scopes')
        .doc(scopeId)
        .get();
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
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String?,
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  Future<void> publishScopeRules(
          Scope scope, AttendancePolicy policy, AttendanceCalendar calendar) =>
      _firestore.runTransaction((transaction) async {
        final org =
            _firestore.collection('organizations').doc(scope.organizationId);
        final reference = org.collection('scopes').doc(scope.id);
        final previous = await transaction.get(reference);
        if (previous.exists &&
            previous.data()?['createdBy'] != scope.createdBy) {
          throw StateError('A group with this name already exists');
        }
        transaction.set(reference, {
          'organizationId': scope.organizationId,
          'parentId': scope.parentId,
          'name': scope.name,
          'type': scope.type,
          'createdBy': scope.createdBy,
          'followerCount': previous.data()?['followerCount'] ?? 0,
          'isArchived': scope.isArchived,
          'activePolicyId': policy.id,
          'activeCalendarId': calendar.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(org.collection('policies').doc(policy.id), {
          'scopeId': scope.id,
          'version': policy.version,
          'effectiveFrom': Timestamp.fromDate(policy.effectiveFrom),
          'state': policy.state.name,
          'basis': policy.basis.name,
          'evaluationPeriod': policy.evaluationPeriod.name,
          'fullUnit': policy.fullUnit,
          'halfUnit': policy.halfUnit,
          'leaveTreatment': policy.leaveTreatment.name,
          'weekOffCredit': policy.weekOffCredit,
          'oneVisitFullDay': policy.oneVisitFullDay,
          'holidayCredit': policy.holidayCredit,
          'minimumPercent': policy.minimumPercent,
          'weeklyOffs': policy.weeklyOffs,
          'startDate': policy.startDate == null
              ? null
              : Timestamp.fromDate(policy.startDate!),
          'endDate': policy.endDate == null
              ? null
              : Timestamp.fromDate(policy.endDate!),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(org.collection('calendars').doc(calendar.id), {
          'scopeId': scope.id,
          'version': calendar.version,
          'effectiveFrom': Timestamp.fromDate(calendar.effectiveFrom),
          'weeklyOffs': calendar.weeklyOffs,
          'offSaturdays': calendar.offSaturdays,
          'holidays': calendar.holidays.map((h) => h.toJson()).toList(),
          'isConfigured': calendar.isConfigured,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  Future<AttendancePolicy?> getPolicy(String orgId, String policyId) async {
    final doc = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('policies')
        .doc(policyId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AttendancePolicy(
      id: doc.id,
      version: data['version'] as int,
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      state: PolicyState.values.byName(data['state'] as String),
      evaluationPeriod:
          EvaluationPeriod.values.byName(data['evaluationPeriod'] as String),
      minimumPercent: (data['minimumPercent'] as num?)?.toDouble(),
      basis: CalculationBasis.values.byName(data['basis'] as String),
      fullUnit: (data['fullUnit'] as num).toDouble(),
      halfUnit: (data['halfUnit'] as num).toDouble(),
      leaveTreatment: LeaveTreatment.values
          .byName(data['leaveTreatment'] as String? ?? 'noCredit'),
      weekOffCredit: data['weekOffCredit'] as bool? ?? false,
      holidayCredit: data['holidayCredit'] as bool? ?? false,
      oneVisitFullDay: data['oneVisitFullDay'] as bool? ?? false,
      weeklyOffs: (data['weeklyOffs'] as List).cast<int>(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      scopeId: data['scopeId'] as String?,
      organizationId: orgId,
    );
  }

  Future<AttendanceCalendar?> getCalendar(
      String orgId, String calendarId) async {
    final doc = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('calendars')
        .doc(calendarId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AttendanceCalendar(
      id: doc.id,
      version: data['version'] as int,
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      weeklyOffs: (data['weeklyOffs'] as List).cast<int>(),
      offSaturdays: (data['offSaturdays'] as List).cast<int>(),
      holidays: (data['holidays'] as List)
          .map((h) => Holiday.fromJson(h as Map<String, dynamic>))
          .toList(),
      isConfigured: data['isConfigured'] as bool? ?? false,
      organizationId: orgId,
      scopeId: data['scopeId'] as String?,
    );
  }
}
