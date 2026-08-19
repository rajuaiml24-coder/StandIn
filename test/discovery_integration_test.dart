import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreOrgRemote remote;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    remote = FirestoreOrgRemote(firestore);
  });

  group('Organization Discovery Integration', () {
    test('Can find newly created organization case-insensitively', () async {
      final org = Organization(
        id: 'org1',
        name: 'ABC University',
        type: OrganizationType.college,
        branch: 'Main Campus',
      );

      await remote.putOrganization(org, 'user1');

      // Search exact
      final results1 = await remote.searchOrganizations('ABC University', OrganizationType.college);
      expect(results1.length, 1);
      expect(results1.first.name, 'ABC University');
      expect(results1.first.branch, 'Main Campus');

      // Search prefix lowercase
      final results2 = await remote.searchOrganizations('abc', OrganizationType.college);
      expect(results2.length, 1);
      expect(results2.first.name, 'ABC University');

      // Search keyword
      final results3 = await remote.searchOrganizations('University', OrganizationType.college);
      expect(results3.length, 1);
    });

    test('Filters by role (type)', () async {
      await remote.putOrganization(Organization(
        id: 'c1',
        name: 'ABC College',
        type: OrganizationType.college,
      ), 'user1');
      await remote.putOrganization(Organization(
        id: 'co1',
        name: 'ABC Tech',
        type: OrganizationType.company,
      ), 'user1');

      // Student search
      final studentResults = await remote.searchOrganizations('ABC', OrganizationType.college);
      expect(studentResults.length, 1);
      expect(studentResults.first.id, 'c1');

      // Employee search
      final employeeResults = await remote.searchOrganizations('ABC', OrganizationType.company);
      expect(employeeResults.length, 1);
      expect(employeeResults.first.id, 'co1');
    });

    test('Keyword search works for middle words', () async {
       await remote.putOrganization(Organization(
        id: 'org2',
        name: 'Silicon Valley Institute',
        type: OrganizationType.college,
      ), 'user1');

      final results = await remote.searchOrganizations('Valley', OrganizationType.college);
      expect(results.length, 1);
      expect(results.first.name, 'Silicon Valley Institute');
    });

    test('Legacy compatibility: can find organizations without search metadata if casing matches', () async {
      // Manually seed legacy data
      await firestore.collection('organizations').doc('legacy_org').set({
        'name': 'Legacy University',
        'type': 'college',
      });

      // Search matching casing -> Found
      final results1 = await remote.searchOrganizations('Legacy', OrganizationType.college);
      expect(results1.length, 1);
      expect(results1.first.name, 'Legacy University');

      // Search lowercase -> Not found (expected limitation for legacy)
      final results2 = await remote.searchOrganizations('legacy', OrganizationType.college);
      expect(results2.length, 0);
    });
  });
}
