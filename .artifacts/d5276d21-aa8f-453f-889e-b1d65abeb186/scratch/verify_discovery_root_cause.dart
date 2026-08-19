import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';

void main() async {
  final firestore = FakeFirebaseFirestore();
  final remote = FirestoreOrgRemote(firestore);

  print('--- Verification: Organization Discovery Root Cause ---');

  // 1. Setup existing data (Current implementation)
  await firestore.collection('organizations').doc('org_abc_college').set({
    'name': 'ABC College',
    'type': 'college',
    'isVerified': false,
  });
  
  await firestore.collection('organizations').doc('org_abc_tech').set({
    'name': 'ABC Technologies',
    'type': 'company',
    'isVerified': false,
  });

  print('Data seeded.');

  // 2. Test Scenario: Case sensitivity
  print('\nScenario: Case sensitivity');
  final results1 = await remote.searchOrganizations('abc', OrganizationType.college);
  print('Search "abc" (college): Found ${results1.length} results.');
  if (results1.isEmpty) {
    print('FAILURE: Search is case-sensitive and failed to find "ABC College".');
  }

  // 3. Test Scenario: Partial search (tokens)
  print('\nScenario: Partial search (tokens)');
  final results2 = await remote.searchOrganizations('Technologies', OrganizationType.company);
  print('Search "Technologies" (company): Found ${results2.length} results.');
  if (results2.isEmpty) {
    print('FAILURE: Prefix search fails for non-leading keywords.');
  }

  // 4. Verify Write Path (Branch)
  print('\nScenario: Write Path (Branch)');
  final newOrg = Organization(
    id: 'org_new',
    name: 'New College',
    type: OrganizationType.college,
    branch: 'Main Campus',
  );
  await remote.putOrganization(newOrg);
  final doc = await firestore.collection('organizations').doc('org_new').get();
  final data = doc.data()!;
  print('New organization document data: $data');
  if (data['branch'] == null) {
    print('FAILURE: "branch" field is missing from Firestore document.');
  }
  if (data['name_lowercase'] == null) {
    print('FAILURE: "name_lowercase" field is missing (needed for case-insensitive search).');
  }

  print('\n--- Root Cause Verification Complete ---');
}
