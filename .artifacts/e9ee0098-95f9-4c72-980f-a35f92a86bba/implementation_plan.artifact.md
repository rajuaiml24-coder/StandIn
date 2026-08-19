# Implementation Plan: Organization Discovery and Selection Redesign

Redesign the organization selection flow to promote popular organizations, improve discovery, and ensure privacy.

## User Review Required

> [!IMPORTANT]
> The discovery flow will now prioritize "Popular Organizations" based on `followerCount`. I will implement a deterministic increment for `followerCount` in Firestore to maintain accurate rankings.

> [!NOTE]
> I will repurpose the `OrganizationSearchPage` to serve as the "Discovery" page, showing popular organizations by default and allowing search.

## Proposed Changes

### Domain Layer

#### [MODIFY] [attendance.dart](file:///C:/StandIn/lib/src/domain/attendance.dart)
- No changes needed (already has `followerCount`, `createdBy`, and `anonymousCreatorId`).

### Data Layer

#### [MODIFY] [firestore_org_remote.dart](file:///C:/StandIn/lib/src/data/remote/firestore_org_remote.dart)
- Add `getPopularOrganizations(OrganizationType type, {int limit = 15})` to fetch organizations sorted by `followerCount` descending.
- Add `incrementFollowerCount(String orgId)` using `FieldValue.increment(1)`.
- Update `putOrganization` to initialize `followerCount: 1` if it's a new organization (for creators).
- Update `_mapDoc` to include `followerCount`.

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- Add `getPopularOrganizations(OrganizationType type)` to wrap the remote call and cache results.
- Update `setupOrganization` to ensure `followerCount` is handled (initializing to 1).
- Add `followOrganization(String uid, Follow follow, Membership membership)` that handles both saving the follow and incrementing the remote `followerCount`.

#### [MODIFY] [user_repository.dart](file:///C:/StandIn/lib/src/data/user_repository.dart)
- Update `saveFollow` to potentially trigger the follower count increment (or delegate to `OrganizationRepository`).

### Presentation Layer

#### [MODIFY] [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)
- Add `popularOrganizations` list and `loadPopularOrganizations()` method.
- Update `start(AppRole role)` to transition to `organizationSearch` (Discovery) instead of `profile` if that's the desired flow, OR ensure `organizationSearch` is the next major step.
- Update `followOrganization()` to use the new repository method that increments follower count.
- Ensure `createOrganization()` results in the creator following the org immediately with `followerCount = 1`.

#### [MODIFY] [organization_search_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_search_page.dart)
- Redesign to show "Popular [Colleges/Companies]" when search is empty.
- Show `followerCount` and `anonymousCreatorId` in the list items.

#### [NEW] [organization_preview_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_preview_page.dart)
- Create a dedicated preview page matching the "Desired Flow" in the prompt.
- Handle cases where official rules are missing by showing the non-blocking message.
- Provide [Follow This Organization] and [Create New Organization] buttons.

## Verification Plan

### Automated Tests
- Update `test/org_selection_redesign_test.dart` to verify:
    - Popular organizations query returns correct results and sorting.
    - `followerCount` increments correctly on follow.
    - Creator becomes the first follower (count = 1).
    - Role-based filtering is strictly enforced in discovery.

### Manual Verification
1.  **Discovery Flow**: Select Role -> See Popular Orgs -> Search -> Preview.
2.  **Follow Flow**: Follow an existing org -> Verify `followerCount` increases in Firestore.
3.  **Creation Flow**: Create a new org -> Verify creator is a follower and `followerCount` is 1.
4.  **Privacy**: Check all screens to ensure no personal UIDs or names are exposed.
