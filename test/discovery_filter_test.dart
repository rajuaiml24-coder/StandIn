import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}

void main() {
  late StandInDatabase database;
  late MockFirestoreOrgRemote mockRemote;
  late OrganizationRepository repository;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    mockRemote = MockFirestoreOrgRemote();
    repository = OrganizationRepository(database, mockRemote);
  });

  tearDown(() async {
    await database.close();
  });

  group('Discovery Filter Logic', () {
    final college = Organization(id: 'c1', name: 'Wells College', type: OrganizationType.college);
    final company = Organization(id: 'co1', name: 'Wells Corp', type: OrganizationType.company);

    test('Student search only returns colleges', () async {
      when(() => mockRemote.searchOrganizations('Wells', OrganizationType.college))
          .thenAnswer((_) async => [college]);

      final results = await repository.searchOrganizations('Wells', OrganizationType.college);
      
      expect(results.length, 1);
      expect(results.first.type, OrganizationType.college);
      expect(results.first.name, contains('College'));
    });

    test('Employee search only returns companies', () async {
      when(() => mockRemote.searchOrganizations('Wells', OrganizationType.company))
          .thenAnswer((_) async => [company]);

      final results = await repository.searchOrganizations('Wells', OrganizationType.company);
      
      expect(results.length, 1);
      expect(results.first.type, OrganizationType.company);
      expect(results.first.name, contains('Corp'));
    });
  });
}
