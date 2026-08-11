import 'package:flutter_test/flutter_test.dart';
import 'package:fake_firebase_security_rules/fake_firebase_security_rules.dart';
import 'dart:io';

void main() {
  late FakeFirebaseSecurityRules rules;

  setUpAll(() {
    final rulesFile = File('firestore.rules').readAsStringSync();
    rules = FakeFirebaseSecurityRules(rulesFile);
  });

  group('Firestore Security Rules Logic', () {
    test('User A cannot create a membership for User B', () {
      final auth = {'uid': 'user_a'};
      final data = {
        'status': 'applicant',
        'uid': 'user_b', // Mismatch
      };
      
      final allowed = rules.isAllowed(
        path: '/organizations/org1/members/user_b',
        method: Method.create,
        auth: auth,
        data: data,
      );
      expect(allowed, false, reason: 'Users should only be able to create their own membership');
    });

    test('User A can create their own applicant membership', () {
      final auth = {'uid': 'user_a'};
      final data = {
        'status': 'applicant',
        'uid': 'user_a',
      };
      
      final allowed = rules.isAllowed(
        path: '/organizations/org1/members/user_a',
        method: Method.create,
        auth: auth,
        data: data,
      );
      expect(allowed, true);
    });

    test('User cannot promote themselves to verified_member', () {
      final auth = {'uid': 'user_a'};
      final currentData = {
        'status': 'applicant',
        'uid': 'user_a',
      };
      final newData = {
        'status': 'verified_member',
        'uid': 'user_a',
      };
      
      final allowed = rules.isAllowed(
        path: '/organizations/org1/members/user_a',
        method: Method.update,
        auth: auth,
        data: newData,
        currentData: currentData,
      );
      expect(allowed, false, reason: 'Only admins should be able to update membership status');
    });

    test('User cannot escalate to isAdmin', () {
      final auth = {'uid': 'user_a'};
      final currentData = {
        'displayName': 'User A',
        'isAdmin': false,
        'role': 'student',
      };
      final newData = {
        'displayName': 'User A',
        'isAdmin': true, // Escalation!
        'role': 'student',
      };
      
      final allowed = rules.isAllowed(
        path: '/users/user_a',
        method: Method.update,
        auth: auth,
        data: newData,
        currentData: currentData,
      );
      expect(allowed, false, reason: 'Users must not be able to change their isAdmin status');
    });

    test('Historical attendance context is immutable', () {
      final auth = {'uid': 'user_a'};
      final currentData = {
        'date': '2026-08-10',
        'organizationId': 'org1',
        'policyVersionId': 'v1',
        'status': 'full',
      };
      final newData = {
        'date': '2026-08-10',
        'organizationId': 'org2', // Trying to change org
        'policyVersionId': 'v1',
        'status': 'full',
      };
      
      final allowed = rules.isAllowed(
        path: '/users/user_a/attendance/rec1',
        method: Method.update,
        auth: auth,
        data: newData,
        currentData: currentData,
      );
      expect(allowed, false, reason: 'Attendance context fields (org, scope, version) must be immutable');
    });
  });
}
