Attendance Platform — Modern Mobile Screen \& UX Specification



Premium, modern, calm and trustworthy UI direction for Flutter MVP



1\. Design Direction



The product should feel like a premium modern finance/productivity app rather than a college utility. Use strong hierarchy, generous spacing, rounded cards, subtle elevation, clean typography, minimal icons and data visualization that is easy to understand in one glance.



2\. Color System



Token



Suggested value



Usage



Primary Navy



\#14213D



Primary brand, headers, selected controls



Primary Orange



\#FF8A3D



Key action, progress highlight, brand accent



Background



\#F6F7FB



Main app background



Surface



\#FFFFFF



Cards and sheets



Text



\#111827



Primary text



Secondary Text



\#667085



Supporting text



Success



\#16A34A



Safe/full attendance



Warning



\#F59E0B



Partial/near limit



Danger



\#DC2626



Absent/critical



Info



\#2563EB



Holiday/info/system state



Use colors semantically, not decoratively. Keep the main brand palette restrained: navy + warm orange. Status colors should be reserved for status.



3\. Typography \& Components



Use a clean modern sans-serif such as Inter, SF Pro equivalent or the platform's best available system font.



Large percentage numbers should be bold and visually dominant.



Use 16–20 px corner radii for major cards; avoid excessive rounded pills.



Use 8-point spacing increments.



Use subtle borders before heavy shadows.



Primary buttons should be high contrast with one clear action per screen.



Use bottom sheets for quick attendance actions.



Use lightweight animations: progress transitions, card state changes and calendar selection.



4\. Screen Map



Splash / session restore



Welcome / Student or Employee



Basic profile



Organization search



Organization policy preview



Create organization/policy (if not found)



PIN setup



Biometric setup



Existing attendance setup



Home dashboard



Mark attendance bottom sheet



Calendar



Date detail



Attendance insights



Organization/profile



Change/follow organization



Policy issue/report



Settings \& security



5\. Screen 1 — Welcome



Goal: immediately explain the product without marketing clutter.



Logo and short value proposition: 'Know your attendance. Know your safe limit.'



Two large choices: Student / Employee.



Secondary action: Already have an account? Sign in.



No ads.



6\. Screen 2 — Basic Profile



Name field.



Mobile number field without OTP in MVP.



Auto-generated username shown after account creation; editable later.



Do not ask email here unless the user chooses recovery setup.



Keep screen to one primary action: Continue.



7\. Screen 3 — Security Setup



Create PIN.



Confirm PIN.



Offer 'Use fingerprint/Face unlock' only if device supports it.



Explain: 'Your attendance stays private on this device.'



PIN should never be displayed or stored in Firestore.



8\. Screen 4 — Organization Search



Large search field at top.



Recent/followed organizations below.



Search results show organization name, branch and follower count only when useful.



Primary result card should show verification badge.



Secondary action: Can't find yours? Create it.



9\. Screen 5 — Organization Policy Preview



Organization name + branch.



Policy summary card.



Examples: Calculation: Hours; Full day: 7h; Half day: 3.5h; Minimum: 75%.



Show verification state and last updated date.



Actions: Follow / Report incorrect.



Keep the policy summary short; provide 'View details' for the full rule.



10\. Screen 6 — Home Dashboard



This is the most important screen. It should answer three questions immediately: Where am I? Am I safe? What should I do next?



Top: organization name + switch/follow control.



Hero attendance card: large percentage, required percentage and status.



Circular or arc progress indicator with restrained animation.



Best calculation card: 'You can miss 4.5h and stay above 75%.'



Recovery card when below target: 'Attend next 5h to reach 75%.'



Today card: Mark attendance.



Mini calendar strip for recent days.



Reserved ad slot at bottom; never overlay content.



11\. Screen 7 — Mark Attendance



Use a bottom sheet for fast entry.



Four primary states: Full, Half, Hours, Absent. Holiday is a separate non-attendance state.



If Full is selected and policy says 7h/day, prefill 7:00.



Allow actual hours to be reduced; status updates immediately.



Show calculation preview: '5h / 7h = 71.4% for today'.



Save action should write locally first and sync later.



No ad inside the bottom sheet.



12\. Screen 8 — Modern Calendar



Use a clean monthly calendar with compact status dots/rings instead of large text inside every date.



Green: full/healthy attendance.



Amber: partial/half or warning.



Red: absent/critical.



Blue: holiday.



Gray: not recorded.



Selected date uses a clear navy outline or surface treatment.



Tap a date to open Date Detail.



Month navigation should be smooth and lightweight.



13\. Screen 9 — Date Detail



Date and weekday.



Attendance state.



Actual hours / expected hours.



Percentage contribution.



Edit attendance.



Notes optional in later version.



Show whether the record is synced or pending sync with a subtle indicator.



14\. Screen 10 — Insights



Current percentage.



Required percentage.



Attendance trend.



Hours/classes attended versus expected.



Safe-to-miss calculation.



Recovery calculation.



Avoid charts in MVP if they add complexity; one simple trend visualization is enough.



15\. Organization \& Switching



Current organization card.



Change organization.



Follow another organization.



Previous organizations remain in history.



Switching organization never deletes old attendance.



Show policy version/effective date when switching.



16\. Policy Report Screen



Current rule shown at top.



Simple reason selector: minimum percentage wrong / day hours wrong / half-day wrong / calculation method wrong / other.



Optional proposed value.



Submit proposal.



Do not let a single report immediately change the live policy.



17\. Ads — Exact UX Rules



Use one reserved banner slot on Home and selected history/insight screens.



Prefer bottom anchored/adaptive banner or a stable inline slot.



Reserve the exact layout area before the ad loads so the UI does not jump.



Never place ads inside attendance input controls, calendar date cells, security screens or onboarding.



Never place an ad immediately beside Full/Half/Absent actions.



Never cover navigation or content.



Ads should be visually separated with a small 'Advertisement' label if required by policy/UI.



Use test ads during development.



18\. Navigation



Recommended MVP bottom navigation:



Tab



Purpose



Home



Current percentage, safety and next action



Calendar



Attendance history and date details



Insights



Calculations and trends



Profile



Organization, security, settings



Keep Mark Attendance as the prominent floating/primary action rather than a permanent fifth tab.



19\. Responsive \& Accessibility Requirements



Support small Android phones first, then tablets.



Respect system font scaling.



Maintain touch targets of at least approximately 44–48 dp.



Do not communicate status using color alone; use icon/text as well.



Dark mode should be planned even if released later.



Avoid dense tables and tiny calendar labels.



20\. UX States That Must Be Designed



First-time empty state.



No organization found.



Organization policy pending verification.



Offline mode.



Pending sync.



Sync error.



Policy changed.



Attendance below required percentage.



Attendance exactly at required percentage.



No attendance recorded today.



Organization switched.



PIN locked.



Biometric unavailable.



21\. Flutter Architecture Expectations



Material 3 foundation with a custom theme.



Feature-first folders: auth, onboarding, organizations, attendance, calendar, insights, profile, ads.



Repositories between UI and data sources.



Drift local DB for durable local state.



Firestore service isolated behind repositories.



Policy engine as a pure Dart domain/service layer with unit tests.



No Firestore reads directly from widgets/screens.



Use providers/change-notifiers or another predictable state-management approach consistently.



Keep calculations deterministic and testable.



22\. AI Builder Design Instruction



Do not generate a generic template. Produce a premium, modern, polished attendance product. Before implementing, review this screen specification and suggest any UX improvements that reduce onboarding friction, improve retention, protect privacy, reduce Firestore reads/writes, or improve ad placement. Do not add new screens without explaining why.



Every screen should specify: purpose, primary action, secondary action, data source, loading state, empty state, offline state, error state, navigation destination, and Firestore/local DB interaction.



23\. Definition of Done for UI



A new user can reach the dashboard without unnecessary forms.



Returning users see useful attendance immediately.



The main percentage is understandable within one second.



The next best action is obvious.



Marking attendance works offline.



Calendar works from local data without a Firestore read per date.



Ads never move the layout or obstruct controls.



Every screen has loading/empty/error/offline states.



The UI feels consistent across Student and Employee modes.



24\. Reference Notes



Firebase Firestore supports offline persistence and synchronization. Firebase Authentication supports email/password and phone authentication and future provider linking. Google Mobile Ads provides Flutter banner/native implementations and requires test ads during development.



Prepared: 10 Aug 2026







