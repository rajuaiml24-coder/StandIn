# Organization Discovery End-to-End Fix

This plan ensures that newly created organizations are immediately discoverable and that legacy organizations remain searchable.

## User Review Required

> [!IMPORTANT]
> **Immediate Persistence**: Organizations will now be saved to the local database and enqueued for sync as soon as the "Create" button is pressed, rather than waiting for the end of onboarding. This makes them discoverable by others almost immediately (subject to sync latency).

> [!WARNING]
> **Legacy Search Limitation**: I am implementing a compatibility fallback for older organizations that do not have `name_lowercase` or `name_tokens`. However, because Firestore queries are case-sensitive, these legacy organizations will only be found if the user's search query exactly matches the casing of the stored name (e.g., searching "ABC" finds "ABC College", but "abc" does not).
> - A full migration of all existing organizations to the new search format would be required for 100% case-insensitive discovery of legacy data. I am excluding this from the current fix per constraints.

## Open Questions

- None.

## Proposed Changes

### 1. Data Layer (Repository)
- **[MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)**:
    - Add `Future<void> saveOrganization(Organization org)` to persist metadata and enqueue sync immediately.

### 2. Onboarding Layer (Controller)
- **[MODIFY] [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)**:
    - Update `createOrganization` to call `_organizationRepository.saveOrganization(org)`.

### 3. Remote Data Layer (Firestore)
- **[MODIFY] [firestore_org_remote.dart](file:///C:/StandIn/lib/src/data/remote/firestore_org_remote.dart)**:
    - **searchOrganizations**: Add a fallback query on the raw `name` field to support discovery of legacy organizations that lack search metadata.
    - Result merging: Ensure deduplication of results between prefix, keyword, and legacy fallback queries.

## Verification Plan

### Automated Tests
- Update `test/discovery_integration_test.dart` to include a "Legacy Organization" scenario where an organization document lacks `name_lowercase` but should still be found by a case-matched prefix.
- Add a test case for "Immediate Save" to verify metadata is enqueued upon creation.

### Manual Verification
1. **New Discovery**: Student A creates "Green Valley College" $\rightarrow$ Student B searches "green" $\rightarrow$ Found.
2. **Legacy Discovery**:
   - Manually insert (via scratch script) an organization without `name_lowercase`.
   - Search with matching casing $\rightarrow$ Found.
   - Search with lowercase $\rightarrow$ Not found (Expected limitation).
3. **Role Filtering**: Employee searches "Green Valley" $\rightarrow$ Not found.
4. **Offline Path**: Create organization while offline $\rightarrow$ Reconnect $\rightarrow$ Verify document appears in Firestore.
