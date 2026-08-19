# Tasks: Redesign Organization Selection Flow

- `[x]` Update `Organization` domain model to include `createdBy` and `anonymousCreatorId` <!-- id: 0 -->
- `[x]` Update `StandInDatabase` (Drift) schema and run build_runner <!-- id: 1 -->
- `[x]` Update `FirestoreOrgRemote` to map `createdBy` from Firestore <!-- id: 2 -->
- `[x]` Update `OrganizationRepository` to use `activePolicyId` and `activeCalendarId` <!-- id: 3 -->
- `[x]` Update `OrganizationSearchPage` to display `anonymousCreatorId` <!-- id: 4 -->
- `[x]` Redesign `PolicyPreviewPage` and `PolicyMissingPage` UI <!-- id: 5 -->
- `[x]` Implement regression tests <!-- id: 6 -->
- `[x]` Final verification (analyze, test, build web) <!-- id: 7 -->
