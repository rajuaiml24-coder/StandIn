Attendance Platform — Business \& Product Blueprint



MVP-to-scale plan for a Student + Hybrid Employee attendance platform



1\. Executive Product Vision



Build a mobile-first attendance platform where the organization defines the attendance policy and the individual follows that organization. The app should work immediately as a personal attendance tracker, then scale into an organization-connected platform where colleges and employers can publish verified attendance data, rules, notices and other services.



Core principle: Organization owns the policy; user owns the personal attendance record; community helps verify policy.



2\. Business Goals



Launch a simple consumer product that can reach first value in under 2 minutes.



Keep onboarding and infrastructure costs low; avoid SMS OTP as a default authentication path in MVP.



Create a reusable organization-policy network that becomes more valuable as followers increase.



Design the data model from day one for future college/employer integrations.



Monetize free users with carefully placed banner/native ads without harming the core workflow.



Create a future B2B path: organization-managed attendance, student/employee onboarding, dashboards and paid institutional features.



3\. User Types



Type



MVP Need



Future



Student



Follow college, configure/confirm policy, record attendance, see percentage and safe limits



College sync, timetable, notices, exams, community



Employee



Follow employer, configure/confirm WFO policy, record office attendance



Employer sync, compliance dashboard, leave/WFO integration



Organization Admin



Create/update organization and policy



Manage members, attendance feeds, notices, analytics, paid plan



Community Contributor



Report/propose policy corrections



Verification/reputation and policy history



4\. New User Journey



Open app and choose Student or Employee.



Enter display name.



Enter mobile number as a contact/identity field; do not send SMS OTP by default in MVP.



Create an app PIN for privacy. Offer device biometric unlock if supported.



Search for college/company.



If organization exists, show a concise policy preview and let the user Follow it.



If organization does not exist, allow creation of a minimal organization profile and policy.



Student optionally enters roll number; employee can optionally enter employee ID only when needed.



Ask whether the user wants to enter existing attendance or start from today.



Open the dashboard immediately.



5\. Authentication \& Privacy Strategy



Use Firebase Authentication as the future identity layer, but do not make SMS OTP mandatory in MVP. Mobile number can be stored as profile/contact data. The local app lock should be a PIN plus optional device biometric. Recovery can initially use optional email plus support verification. Architect the account so email/password, phone OTP and other providers can later be linked to the same Firebase UID.



Never store raw passwords or raw PINs in Firestore.



Use a permanent Firebase Auth UID as the primary user identity.



Keep mobile number private; do not expose it through community features.



Roll number is private organization-matching data, not a public username.



Attendance records are private by default.



Username is a public/community identity and should be generated automatically in MVP.



Do not require email, profile photo, DOB, address, social accounts or contacts in MVP.



6\. Organization / Follow Model



Use Follow and Join as separate concepts.



Follow: user wants to use the organization's attendance policy. No institutional verification required.



Join: user claims verified membership in the organization. Later this can use roll number/employee ID plus an organization-managed roster.



A user can change current organization without deleting historical attendance.



Keep organization hierarchy flexible: organization → branch/campus → department/program when required.



Do not force complex hierarchy during onboarding.



7\. Attendance Policy Engine



The policy engine is the product's key differentiator. It must support:



Calculation basis: classes/periods, hours, days, or custom.



Minimum required percentage: e.g. 65%, 75%, 80%.



Full-day definition: e.g. 7 hours.



Half-day definition: e.g. 3.5 hours.



Partial-hour calculation.



Holiday/non-working-day rules.



Optional subject/course-specific policies in later phases.



Policy versioning so historical calculations are not silently changed.



Effective-from date for every policy update.



Verification state: community reported, under review, verified, organization verified.



8\. Community Policy Verification



A user can report that an organization policy is wrong.



The report creates a proposal instead of immediately changing the live policy.



Other followers can confirm or reject the proposal.



The system tracks proposal evidence and number of confirmations.



An approved policy becomes a new version with an effective date.



Users receive a clear notice when a policy changes.



Historical attendance remains auditable; never rewrite past attendance invisibly.



9\. Core Attendance Experience



Dashboard shows current percentage, required percentage, safety state and best next action.



Examples: 'You can miss 4.5 hours and remain above 75%' or 'Attend the next 5 hours to reach 80%'.



Mark attendance: Full, Half, Partial/Hours, Absent, Holiday.



If policy is hour-based, Full Day initially displays organization hours and lets the user adjust actual hours.



Calendar shows daily attendance state and opens a date-detail screen.



All calculations must come from the policy engine, not duplicated UI formulas.



10\. Data \& Technical Architecture



Use Flutter for the mobile client, Firebase Authentication for identity, Cloud Firestore as the cloud source of truth, and a local SQLite-based database such as Drift as the application cache/local-first store. Firestore itself has offline persistence, but a deliberate local repository/cache layer gives us predictable domain storage, efficient calculations, local search, sync queues and tighter control over Firestore reads.



UI → ViewModel/Controller → Repository → Local DB / Firestore Sync → Cloud.



Organization policy is cached locally and refreshed only when version/lastUpdated changes.



Attendance is written locally first, marked pending-sync, then uploaded in batches.



Use targeted Firestore reads and listeners; do not stream entire collections.



Use summary documents for frequently displayed totals where justified.



Use repository-level caching and memoized calculations.



Keep cloud writes idempotent using stable attendance record IDs.



Separate organization policy, user profile, membership/follow relation and attendance records.



Plan for background sync/retry when network returns.



Use Firestore Security Rules so users can read/write only their own attendance and permitted organization data.



11\. Suggested Firestore Domain Model



Collection



Purpose



users/{uid}



Private user profile, auth-linked metadata, current organization reference



organizations/{orgId}



Organization identity, type, branch, verification state



organizations/{orgId}/policyVersions/{versionId}



Versioned attendance policy



organizations/{orgId}/followers/{uid}



Follow relationship and timestamps



organizations/{orgId}/members/{uid}



Verified organization membership; future



users/{uid}/attendance/{attendanceId}



Private daily attendance record



users/{uid}/organizationHistory/{orgId}



Historical organization relationship



policyProposals/{proposalId}



Community policy corrections and review state



appConfig/{doc}



Feature flags, remote settings, ad configuration metadata



12\. Local Database Strategy



Use Drift/SQLite for durable local domain data and predictable queries.



Cache current organization, policy version, attendance history and calculated summaries.



Maintain a sync queue for offline writes.



Use a sync state per record: local, pending, synced, conflict/error.



Never make the UI wait for Firestore for normal dashboard/calendar rendering.



Firestore remains authoritative for synchronized cloud data; local DB is the fast operational layer.



Keep Firestore listeners limited to data where near-real-time updates materially improve the experience.



13\. Ads \& Monetization



Use Google Mobile Ads/AdMob after the core UX is stable. Start with one reserved banner slot on selected screens. The ad container must have fixed/reserved space so loading or refreshing an ad never moves buttons, attendance cards or calendar controls.



Do not place ads beside destructive actions or attendance buttons.



Do not place an ad between a date and its attendance controls.



Prefer a bottom anchored banner or a reserved inline slot on dashboard/history screens.



Keep ad frequency conservative; retention is more valuable than short-term impressions.



Use test ad units during development.



Later evaluate native ads and premium ad-free subscription only after retention is proven.



Do not build product decisions around a specific eCPM; measure real revenue after launch.



14\. MVP Scope — Build Only This First



Onboarding: Student/Employee → name → mobile → PIN → organization → follow.



Create organization if not found.



Organization policy preview.



Attendance dashboard.



Mark Full/Half/Hours/Absent/Holiday.



Modern monthly calendar.



Date detail.



Attendance calculations and safety recommendations.



Change/follow another organization.



Local database + Firestore sync.



Firebase Auth foundation prepared for future email/phone providers.



Basic policy reporting.



15\. Explicitly Defer



College social network.



Instagram/social account sync.



Chat.



Friends/following users.



College notices and events.



Full timetable/ERP integrations.



Advanced analytics.



Paid organization management.



Complex employee HR integrations.



16\. Entrepreneurial Success Metrics



Time to first useful attendance result.



Onboarding completion rate.



Percentage of users who mark attendance on day 1.



7-day and 30-day retention.



Weekly active users / monthly active users.



Organizations created and followed.



Policy confirmation rate.



Policy correction rate.



Average attendance actions per active user.



Ad revenue per active user after retention is healthy.



17\. Instructions for the AI Builder



Do not start coding blindly. First review this blueprint, identify contradictions, missing edge cases and security risks, and propose improvements. Return a concise architecture review and screen/data-flow plan for approval. After approval, implement incrementally. Preserve separation between UI, repositories, local DB, policy engine and Firebase services. Do not put Firestore calls directly inside screens.



Important: If a proposed feature increases Firebase reads/writes, SMS costs, or operational complexity, explain the cost and propose a cheaper alternative before implementing it.



18\. Technical Reference Notes



Firebase Firestore supports offline persistence and synchronization on Android, Apple and web; this is useful but does not replace our deliberate local repository/database layer.



Firebase Authentication supports email/password and phone authentication and can support multiple providers linked to the same user account. Phone authentication uses SMS and should therefore remain optional until the business case justifies the cost.



AdMob supports banner/native ads in Flutter; use test ads during development and reserve layout space to prevent UI movement.



Official references: Firebase Firestore offline persistence; Firebase Authentication for Flutter; Firebase phone authentication; Google Mobile Ads Flutter guidance.



Prepared: 10 Aug 2026

