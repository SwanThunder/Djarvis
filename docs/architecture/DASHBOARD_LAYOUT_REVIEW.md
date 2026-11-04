# Main-screen layout brief review

[Русская версия](DASHBOARD_LAYOUT_REVIEW.ru.md) · [Required visual design](../DESIGN.md) · [Product definition](../PRODUCT.md) · [Delivery design CP17](DELIVERY_DESIGN.md)

Status: review prepared in PLAN-016 and completed in PLAN-017 (2026-11-04, Europe/Moscow). Owner answers recorded below (L1–L4, L2a, L6, L7) are accepted product choices; everything else in this document is a proposal or an open item. No screen, prototype or visual test exists, and programming remains unapproved.

## 1. Source

- Local original: `design/Djarvis_Main_Dashboard_Layout_Architecture_v1_0.txt` (layout specification v1.0, Russian), SHA-256 `b8a782015dfa3434dda0f02e500e0d6c2224a41221847d2e6b2d1e0bf27aaa0d`. It stays local, unchanged and excluded from publication, like the other owner design originals.
- Scope of the brief: spatial layout of the main screen, container hierarchy, adaptive rearrangement, the boundary between the dashboard and the voice butler, and a mandatory floating microphone button that can be hidden. It explicitly excludes colors, materials, motion, data, APIs and business logic; those remain governed by [DESIGN](../DESIGN.md) and the visual brief v2.1.
- The brief itself states that it does not replace project architecture, that reference geometry must not create new sections or fake data, and that unresolved conflicts are decided in favor of the project architecture and reported.

## 2. Summary of the brief

| Area | Brief requirement |
| --- | --- |
| Shell | Left navigation rail, main workspace with a top bar and a Bento content grid below it; floating microphone and voice-butler overlay are separate layers above the grid. |
| Navigation rail | App identity at the top, vertical icons below; reference shows six icons (home, layers, calendar, folder, star, settings) as geometry only; actual destinations come from the project. |
| Top bar | Left context selector, wide central search, right group of plus action, notifications and profile; separated from the grid; do not create missing functions to match the picture. |
| Content grid | Seven outer cards: four equal compact cards in the first row; second row ≈60/40 — one large composite card on the left (calendar matrix left, circular progress plus two status rows right) and two stacked cards on the right (upper with three segments, lower with two rows). Card meaning is not taken from the picture. |
| Floating microphone | Fixed to the bottom-right of the viewport (16–24 px desktop offset, safe-area aware), above cards, not inside a card, never covering required content; opens the existing voice butler as an overlay; the dashboard keeps its state. |
| Hide option | User can hide the button through the existing settings/appearance area («Показывать кнопку микрофона»); hiding does not disable the butler and reserves no space; existing invocation methods remain; no new phrase, shortcut or route is invented. |
| Layers | 0 shell → 1 dashboard → 2 floating microphone (when visible) → 3 voice-butler overlay. |
| Adaptive | Tablet: top cards 2×2, large card full width; mobile: one column in the same functional order, internal calendar/progress stacked; existing mobile navigation form only. |
| Acceptance | 16 checklist items, including no fictitious sections/data and no color/motion rules in this specification. |

## 3. Consistent with the current design

- Narrow left sidebar plus top bar plus responsive Bento workspace; logo at the top of the sidebar.
- Top-bar grouping: context controls left, search centered, actions/profile right. The profile element maps to the local profile; no account requirement is introduced.
- Ban on CRM content, demo records, decorative KPIs and destinations created only for styling.
- One settings area: the microphone-button visibility switch belongs to the existing appearance settings, and the brief forbids a separate page for it.
- Responsive desktop/tablet/mobile behavior with unchanged functional order; Android remains a later design, so mobile rules are guidance only.
- Colors, Glass/Solid materials and motion stay in DESIGN and v2.1; the brief adds none.

## 4. Conflicts and gaps, with owner answers

| ID | Topic | Finding | Resolution |
| --- | --- | --- | --- |
| L1 | Assistant circle | DESIGN requires the circular assistant above the day panel; the brief's grid has no circle and moves the butler into an overlay. | **Owner choice:** keep the circle at the top of the main screen, above the brief's grid. The grid becomes the day panel. The overlay opens for an active voice session. |
| L2 | Floating button vs. mute | The product already requires an instant mute button that stops wake detection and dialogue capture. The brief's button invokes the butler. | **Owner choice:** one button with two actions — primary press invokes the butler; a secondary action mutes/unmutes. Exact secondary gesture remains open (L2a). |
| L3 | Press behavior | The brief says "open the existing butler interface"; product invocation was only by wake phrase. | **Owner choice:** pressing opens the overlay and immediately starts listening, as if the wake phrase had been spoken. All capture gates still apply. |
| L4 | Unavailable state | Expired access, OS microphone denial, missing local resources and manual mute forbid capture. | **Owner choice:** the button stays visible in a distinct unavailable state; pressing shows a short reason and the fixing action. It never captures while a gate fails. |
| L5 | Sidebar width | Brief: ≈1/11–1/12 of the panel, to be refined by the project grid; DESIGN: 52–68 px. | Proposal: keep DESIGN's 52–68 px; the brief explicitly defers to the project grid. |
| L6 | Top-bar contents | Context selector, plus action and notifications have no defined Djarvis function yet. | **Owner choice (PLAN-017):** day selector, quick create (task, habit, note) and notifications list (reminders and pending confirmations); no profile element. |
| L7 | Card contents | The brief fixes geometry only; DESIGN's suggested first view is circle, day summary, meetings/tasks, habit status. | **Owner choice (PLAN-017):** the section 6 mapping is accepted as written, except the top-bar profile row. |

### 4.1 Consequences of L2–L4 (proposals derived from accepted rules)

- **Mute must stay reachable when the button is hidden.** The product requires an instant mute control; hiding the floating button cannot remove it. Proposal: keep mute in the voice-butler overlay and the tray menu as well; this adds no new route.
- **Secondary action must be accessible (L2a).** A long press alone is neither instant nor keyboard-accessible. Proposal: long press or right-click plus a keyboard-accessible context menu on the same button, with a visible muted state. **Owner choice (PLAN-017):** right-click or the keyboard menu key opens the menu with mute/unmute. No global shortcut is invented.
- **Muted state:** the primary press does not silently unmute. It shows "Microphone is off" with an explicit "Turn on" action, consistent with explicit unmute in the audio state machine (CP09).
- **Press-to-talk and gates:** each press rechecks entitlement, OS permission and local resources at capture start; a press during an active session focuses the existing overlay instead of opening a second one. Voice use counts as product use for trial start (ADR-005).
- **Expired access:** the button shows the unavailable state and routes to license renewal/import; it never opens a functional assistant.
- **Quiet hours/calls/games** suppress only proactive speech; a user's explicit press still works.
- The overlay is the presentation of the existing voice session (CP09/CP17), not a second butler; closing it returns to the preserved dashboard. The circle on the dashboard can show actual session state without perpetual decorative motion (DESIGN).

## 5. Layer order with the owner choices

```text
LEVEL 0  application shell
LEVEL 1  dashboard: sidebar + top bar + assistant circle + Bento day panel
LEVEL 2  floating microphone button (when visible): press = talk, secondary = mute/unmute
LEVEL 3  voice-butler overlay (active session)
```

## 6. Slot mapping (accepted in PLAN-017, except the profile row)

Only existing records and commands are used; no new metrics or modules. Navigation labels and order remain open under DD09.

| Brief slot | Proposed Djarvis content |
| --- | --- |
| Navigation rail | CP17 destinations: Today, Tasks, Calendar, Habits, Projects, Notes; Settings at the bottom service area. Seven destinations versus the reference's six icons is acceptable because the brief defers to the project. |
| Top bar — context selector | Date/day selector for the Today view (existing day snapshot); alternative: none until agreed. |
| Top bar — search | Local search across tasks, habits, projects and notes (CP07 scope). |
| Top bar — plus action | Quick create of an existing record type (task, habit, note) through existing commands. |
| Top bar — notifications | List of existing reminder notices and pending confirmations; omit if no in-app notice list is approved. |
| Top bar — profile | Not shown (owner choice, PLAN-017). |
| Assistant circle | Above the grid; reflects real session state (wake listening, listening, thinking, speaking, muted, unavailable). |
| Top cards 1–4 | Day summary items from the existing day snapshot, e.g. today's planned tasks, overdue tasks, today's habits, next calendar event. These are counts/lists of existing records, not new KPIs. |
| Large card — calendar | Calendar matrix with the selected date and existing events/placements. |
| Large card — progress | Circular progress for today's habits; two rows for day-plan progress and overdue/missed-time indicators already defined by the planner. |
| Right upper card | Day proposal review (three segments: morning/day/evening placements) — proposal only. |
| Right lower card | Two nearest upcoming items (meetings or placed tasks) with status. |

## 7. Required follow-up

1. Owner: all layout items are resolved; navigation order was accepted in ADR-013.
2. Agents: reflect the mapping in CP17 screen states after the owner review; include button states, overlay focus/Escape behavior and hidden-button mute paths in CP20 acceptance.
3. Design originals stay local; the brief must be added to the local publication exclusion list (`.git/info/exclude`) before the next commit.
