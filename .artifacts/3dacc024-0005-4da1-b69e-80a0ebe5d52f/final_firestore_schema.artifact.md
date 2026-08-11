# Final Proposed Firestore Schema & Architecture

This specification defines the exact Firestore structure, data types, and logic for the StandIn platform.

## 1. Global Identity & Authentication

### `usernames/{normalizedUsername}`
- **Path**: `/usernames/{a_z0_9_._}`
- **Purpose**: Global uniqueness index for usernames.
- **Security**: Public read; `allow create` if authenticated and `request.resource.data.uid == request.auth.uid`. Immutable.
- **Fields**:
  - `uid`: `String` (The permanent Firebase Auth UID)

### `users/{uid}`
- **Path**: `/users/{uid}`
- **Purpose**: Global user profile.
- **Security**: Read/Write only by owner (`request.auth.uid == uid`).
- **Sync Strategy**: Real-time listener (small document).
- **Fields**:
  - `displayName`: `String`
  - `role`: `String` (Enum: `student`, `employee`)
  - `mobile`: `String` (Private contact)
  - `activeFollowId`: `String` (Convenience pointer to a `follows` doc ID)
  - `createdAt`: `Timestamp`
  - `updatedAt`: `Timestamp`

---

## 2. Organization Hierarchy & Discovery

### `organizations/{orgId}`
- **Path**: `/organizations/{stableId}`
- **Purpose**: Top-level entity metadata.
- **Security**: Public read; Write restricted to Admin.
- **Fields**:
  - `name`: `String`
  - `type`: `String` (Enum: `college`, `company`)
  - `isVerified`: `Boolean`
  - `isHolidayCalendarConfigured`: `Boolean`
  - `activePolicyId`: `String` (Global fallback policy)
  - `activeCalendarId`: `String` (Global fallback calendar)
  - `updatedAt`: `Timestamp`

### `organizations/{orgId}/scopes/{scopeId}`
- **Path**: `/organizations/{orgId}/scopes/{scopeId}`
- **Purpose**: Hierarchy nodes (Branch, Department, Semester, Team).
- **Security**: Authenticated read.
- **Fields**:
  - `parentId`: `String` | `null`
  - `type`: `String` (Enum: `branch`, `department`, `semester`, `team`)
  - `name`: `String`
  - `activePolicyId`: `String` | `null`
  - `activeCalendarId`: `String` | `null`

---

## 3. Policy & Calendar Engine (Versioned)

### `organizations/{orgId}/policies/{policyId}`
- **Path**: `/organizations/{orgId}/policies/{policyId}`
- **Purpose**: Immutable versions of attendance rules.
- **Security**: Authenticated read.
- **Versioning**: Snapshot-based. `effectiveFrom` defines the switch point.
- **Fields**:
  - `scopeId`: `String` (The scope this version was created for)
  - `version`: `Number`
  - `state`: `String` (Enum: `draft`, `community`, `confirmed`, `official`)
  - `effectiveFrom`: `Timestamp`
  - `evaluationPeriod`: `String` (Enum: `weekly`, `monthly`, `semester`, etc.)
  - `startDate`: `Timestamp` | `null` (Required for academic periods)
  - `endDate`: `Timestamp` | `null` (Required for academic periods)
  - `minimumPercent`: `Number` | `null`
  - `basis`: `String` (Enum: `hours`, `days`, `periods`)
  - `fullUnit`: `Number`
  - `halfUnit`: `Number`
  - `weeklyOffs`: `Array<Number>` (Days 1-7)

### `organizations/{orgId}/calendars/{calendarId}`
- **Path**: `/organizations/{orgId}/calendars/{calendarId}`
- **Purpose**: Versioned holiday/workday schedules.
- **Security**: Authenticated read.
- **Fields**:
  - `scopeId`: `String`
  - `effectiveFrom`: `Timestamp`
  - `state`: `String`
  - `holidays`: `Map<DateString, String>` (e.g., `"2026-08-15": "Independence Day"`)
  - `specialWorkingDays`: `Map<DateString, String>`

---

## 4. Relationships (The Source of Truth)

### `users/{uid}/follows/{followId}`
- **Path**: `/users/{uid}/follows/{followId}`
- **Purpose**: **User's chosen contexts**. This is the primary sync source.
- **Security**: Owner only.
- **Fields**:
  - `organizationId`: `String`
  - `scopeId`: `String` (Most specific context followed)
  - `personalTargetPercent`: `Number` | `null` (Individual goal, not org policy)
  - `status`: `String` (Enum: `active`, `archived`)
  - `followedAt`: `Timestamp`

### `organizations/{orgId}/members/{uid}`
- **Path**: `/organizations/{orgId}/members/{uid}`
- **Purpose**: Verification and official relationship state.
- **Security**: Read by Owner + Org Admin. Write by System (Admin) or User (as 'applicant').
- **Fields**:
  - `status`: `String` (Enum: `follower`, `applicant`, `verified_member`)
  - `idNumber`: `String` | `null` (Roll Number / Employee ID)
  - `joinedAt`: `Timestamp`
  - `verifiedAt`: `Timestamp` | `null`

---

## 5. Attendance (Private)

### `users/{uid}/attendance/{attendanceId}`
- **Path**: `/users/{uid}/attendance/{date_org_scope_id}`
- **Purpose**: High-frequency private records.
- **Security**: Owner only.
- **Write pattern**: Idempotent writes using stable IDs.
- **Fields**:
  - `date`: `String` (Format: `YYYY-MM-DD`)
  - `organizationId`: `String`
  - `scopeId`: `String`
  - `status`: `String` (Enum: `full`, `half`, `absent`, etc.)
  - `actualUnits`: `Number`
  - `expectedUnits`: `Number`
  - `policyVersionId`: `String` (Immutable reference for historical integrity)
  - `calendarVersionId`: `String` | `null`
  - `updatedAt`: `Timestamp` (For delta sync)

---

## 6. Resolution & Sync Rules

### Policy Resolution (Deterministic)
The client/repository resolves the policy for an `activeFollow` using this precedence:
1. **Personal Target**: `users/{uid}/follows/{id}.personalTargetPercent` (User goal).
2. **Specific Scope**: `organizations/{orgId}/policies` where `scopeId == followedScopeId`.
3. **Hierarchy Walk**: Recursive check of `scopes/{parentId}` until a policy is found.
4. **Org Fallback**: `organizations/{orgId}` global policy.

> [!CAUTION]
> **Historical Integrity**: When attendance is marked, the ID of the policy version used MUST be saved in the attendance record. Calculations for that date always use that snapshot.

### Calendar Resolution
1. **Scope Calendar**: Specific holidays for a semester/team.
2. **Organization Calendar**: General holidays for the company/college.
3. **Conflict Rule**: Specific scope holidays/workdays overwrite parent ones.

### Sync Metadata (Drift Cache)
- **Attendance Delta**: `db.query("attendance").where("updatedAt > lastSync")`.
- **Policy Versioning**: Drift stores `policyId` and `version`. App only reads Firestore if `activePolicyId` in the Scope/Org document has changed.

---

## 7. Performance & Cost
- **Home Screen**: 0 Firestore reads on open. It displays Drift data. A background background "Sync Check" doc fetch (User doc) determines if further reads are needed.
- **Listeners**: Restricted to `users/{uid}` only.
- **Indexes**:
  - `attendance`: `(uid ASC, updatedAt DESC)`
  - `follows`: `(uid ASC, status ASC)`
  - `memberships`: `(orgId ASC, status ASC, uid ASC)`
  - `proposals`: `(orgId ASC, scopeId ASC, type ASC)`
