# Blueprint & Specification Review: StandIn App

I have reviewed the `App_Business_Product.md` (Blueprint) and `App_UX_UI_Screen_Spec.md` (UX Spec). Here is my analysis of the project's current alignment and the path forward.

## Strategic Alignment

The StandIn project is well-positioned as a "privacy-first, offline-first" attendance utility. The architectural choice of a local-first operational layer (Drift) combined with Firestore for cloud sync is excellent for maintaining a high-performance UI while ensuring data durability.

### Strengths in Current Codebase
- **Design System**: The recent `WelcomePage` redesign perfectly captures the "Premium Navy/Orange" brand identity defined in the UX Spec.
- **Architecture**: The `AttendanceController` and `Repository` pattern already in use provides the necessary abstraction for the local-first strategy.
- **Policy Engine**: The core logic for calculating attendance percentages and "safe-to-miss" limits is already present, fulfilling the product's "key differentiator."

### Critical Gaps (MVP Scope)
1.  **Onboarding Journey**: The current app jumps straight from `WelcomePage` to the `Dashboard`. We are missing:
    - **Screen 2**: Basic Profile (Name/Mobile).
    - **Screen 3**: Security Setup (PIN/Biometrics).
    - **Screen 4 & 5**: Organization Search and Policy Preview.
2.  **Safety Recommendations**: While the engine calculates these, the `HomePage` UI needs more "calm and trustworthy" data visualization (Safety/Recovery cards) as per Section 10 of the spec.
3.  **Local-First Implementation**: The app currently uses a `DevelopmentAttendanceRepository`. We need to switch to a production-ready `LocalFirstAttendanceRepository` using the Drift database defined in `lib/src/data/local/standin_database.dart`.
4.  **Firebase Identity**: The "permanent Firebase Auth UID" mentioned in the blueprint is not yet integrated as the primary user identity.

## Technical Observations

- **Policy Versioning**: The blueprint mentions "Policy versioning so historical calculations are not silently changed." We should ensure the `OrganizationPolicyRows` table in Drift supports this.
- **Sync Queue**: Section 12 highlights the need for a "sync queue for offline writes." I see `SyncQueueRows` in the database schema, but the logic to process this queue in `LocalFirstAttendanceRepository` needs to be implemented.
- **Ad Placement**: The "reserved space" requirement is critical. We should ensure the `HomePage` layout accounts for the `Reserved ad slot` at the bottom to prevent UI jumps.

## Suggested Roadmap

1.  **Phase 1: Complete Onboarding Flow** (Screens 2-5).
2.  **Phase 2: Enhanced Dashboard & Visualization** (Safety/Recovery cards + Ad reservation).
3.  **Phase 3: Production Persistence & Sync** (Drift + Firestore Sync Engine).
4.  **Phase 4: Security Features** (PIN + Biometrics).

---

> [!TIP]
> **Priority Recommendation**: We should implement the **Onboarding Flow** next. This will allow us to capture the "User Persona" (Student/Employee) and "Organization Follow" logic which is fundamental to the attendance calculations.
