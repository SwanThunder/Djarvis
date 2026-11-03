# Djarvis visual design requirements

[Русская версия](DESIGN.ru.md) · [Product definition](PRODUCT.md)

Status: this is the owner's required Djarvis visual design: visual system, sidebar/top-bar shell, assistant-above-day-panel composition, palettes, material modes, accessibility, and no background image. The owner selected Midnight Electric + Glass initially and supplied `design/Djarvis_UI_Design_v2_1_.txt` as the current visual-system refinement; density is compact without crowding. Detailed grouping still needs review. Flutter is separately selected only for UI by [ADR-001](architecture/DECISIONS.md); this document does not select the remaining architecture or authorize programming. Both local originals, including `design/design 1.0.txt`, remain unchanged; v2.1 refines visual behavior without changing product features.

## Product mapping and composition

- Use a dark, compact Bento-style dashboard with Glassmorphism surfaces and restrained depth. Do not add a background image or photograph.
- The main screen shows the futuristic circular assistant above the day panel.
- The required shell has a narrow left sidebar, a top bar, and a responsive main workspace. The sidebar has a logo at the top, section icons with an active state, and service controls at the bottom. Proposed destinations map to day/tasks, calendar, habits, projects, notes, and one settings area containing connections and appearance. Exact grouping, order, naming, and page-level block placement remain unspecified; this does not add new product features.
- Adapt the reference grid to real Djarvis tasks, habits, calendar events, projects, and notes. Preserve established names, fields, permissions, routes, and workflows. The CRM example is layout guidance only: do not add customer records, satisfaction scores, regions, invented KPIs, or demo business data.
- Keep the assistant visual above the day panel; other section content may use asymmetric Bento cards, with larger areas for primary information and compact cards for supporting details.
- Suggested first view: assistant circle, day summary, then the existing day's meetings/tasks and habit status. This is a content arrangement proposal; do not invent new metrics or change planner behavior.
- Suggested task and calendar views may use compact cards, lists, and tables for existing records. Projects and notes use the same visual tokens; their product fields and workflows remain the source of truth.
- Navigation and page headings use product language and established destinations. The top bar places context controls on the left, a search field near the center, and actions/profile controls on the right. The search scope and exact action set need definition for Djarvis; the design does not introduce CRM entities.
- The original folder contains no accompanying image or video assets; visual similarity to a video was not assessed. No screenshot UI test has been run.

## Required palettes

The listed HEX values are exact palette requirements. Assignment of primary, secondary, and accent roles is a recommendation; derived surface and text colors must preserve contrast.

| Theme ID | Palette name | Primary | Secondary | Accent |
| --- | --- | --- | --- | --- |
| `deep-blue-pink` | Deep blue / white / soft pink | `#09318D` | `#FFFFFF` | `#F59ACC` |
| `pink-orange` | Bright pink / orange / soft pink | `#DB3996` | `#FC734D` | `#F59ACC` |
| `midnight-electric` | Midnight blue / electric blue / orange | `#0A1430` | `#0297DE` | `#FC734D` |

The pink `#F59ACC` recurs in two references; orange `#FC734D` also recurs. Do not paint every card with the accent. Use semantic success, warning, danger, and other status colors for their meaning rather than replacing them with decorative theme colors. Charts must distinguish series using labels, markers, or line styles as well as color.

| Semantic use | Guidance |
| --- | --- |
| Primary | Active navigation, selected controls, and primary interactive emphasis |
| Secondary | Supporting controls and secondary data emphasis |
| Accent | Calls to action and selected focal points; use sparingly |
| Success / warning / danger | Retain recognizable meaning across all three palettes |
| Focus | Visible focus treatment with adequate contrast, independent of hover |
| Charts | Keep line/marker/label distinctions legible in both material modes |

Role mapping is a recommendation, not a reason to alter the exact palette HEX values.

## Independent surface modes

Each palette supports both material modes, for six combinations total. The transparency/material control is independent of the selected theme. Changing it must not change layout, content, interactions, or animation behavior.

| Surface behavior | Glass | Solid |
| --- | --- | --- |
| Fill | Tinted translucent surface; alpha about 0.45–0.78 is a recommendation | Fully opaque fill, alpha 1 |
| Backdrop blur | Recommended range 12–20 px | `backdrop-filter: none` |
| Borders | Light/tinted border; alpha about 0.10–0.20 is a recommendation | Opaque or moderately contrasting border |
| Depth | Soft, deeper shadow | More restrained shadow for layer separation |
| Nested surfaces | Preserve legible layering | Every applicable fill remains opaque, including nested cards, menus, dialogs, and overlays; no residual transparency |

Applicable surfaces include the main work area, cards, sidebar, top bar, menus, dialogs, tables, and floating controls.

Alpha values, derived surface colors, blur, shadows, and dimensions are recommendations, not fixed source measurements. If backdrop blur is unsupported, fall back to an opaque surface. Do not force all baseline devices into Solid solely due to the 8 GiB target; review visual-effects performance on the baseline CPU/8 GiB configuration.

## Settings and design tokens

- Put appearance controls in one local appearance section within the existing settings, not in a duplicate settings screen.
- Show three theme choices with names and color swatches, plus a separate “Interface transparency” Glass/Solid control.
- Apply selections immediately, persist them locally, and restore them after restart. The owner-confirmed initial combination is `midnight-electric` + Glass; all other combinations remain available.
- Use one semantic token layer for `surface`, `surface-elevated`, `text`, `text-muted`, `border`, `primary`, `secondary`, `accent`, `focus`, `success`, `warning`, `danger`, and `chart-*`. Map tokens to the exact palette while deriving accessible foreground and surface colors.
- Use the same tokens and state behavior across navigation, cards, charts, tables, menus, and dialogs. Provide a fallback for unavailable blur.
- Derived surface, foreground, and border colors are implementation values; test them against the chosen palette and the contrast targets below.
- Keep Glass translucency and blur as separate properties. Translucency alone does not guarantee readable text.
- The settings view must expose both controls together without creating a second settings location. A change is visible immediately and remains selected after application restart.

## Interaction, accessibility, and responsive behavior

- Preserve keyboard access, clear labels, visible focus, and default/hover/pressed/focus/disabled states. Never use color as the sole status indicator.
- Target WCAG AA contrast: at least 4.5:1 for normal text and 3:1 for large text. Verify every palette and both surface modes; do not use white text on bright pink, soft pink, or orange without measuring contrast.
- Honor system reduced motion through Flutter; the source's CSS `prefers-reduced-motion` expresses intent rather than selecting a web stack. Do not add hover lift to every card or chart entrance purely for decoration.
- Support desktop, tablet, and mobile layouts without shrinking text to unreadable sizes. Suggested breakpoints: desktop at 1200 px and above; tablet 768–1199 px; mobile below 768 px. Suggested sidebar width 52–68 px, card radius 16–24 px, and card gap 12–18 px; adapt these to the actual interface.
- Theme and material changes should preserve the same geometry and behavior in all six combinations. Review all combinations and saved-setting restoration before accepting the design.

## Recommended geometry and typography

The following are adaptation ranges, not pixel-perfect requirements. Keep the assistant/day panel relationship and content readable over these suggestions.

| Element | Suggested range |
| --- | --- |
| Sidebar width | 52–68 px |
| Outer spacing | 12–24 px |
| Card padding | 16–24 px |
| Card gap | 12–18 px |
| Large card radius | 16–24 px |
| Button/field radius | 10–16 px or pill |
| Border | 1 px |
| Main icon | 16–20 px |
| Compact control height | 30–40 px with an adequate accessible hit area |
| Page heading | 22–30 px |
| Supporting text | 10–13 px, subject to readability |

Use a neutral modern sans-serif. Suggested weights are 400 for body text, 500–600 for labels/actions, and 600–700 for prominent values. Tabular numerals may help align dates and counts. Long body text has a suggested width of 65 characters; never shrink text just to fit one line. Density is compact without crowding. Flutter maps these ranges to logical pixels and checks system scaling; source ranges are not immutable physical pixels.

## Recommended interaction details

- Before adding motion, identify its purpose and frequency: feedback, spatial continuity, or state indication. Very frequent actions, keyboard commands and switches are immediate; do not animate every data refresh or container entrance.
- v2.1 timing guides: press 100–160 ms, small popover 125–200 ms, menu 150–250 ms, dialog 200–300 ms; up to 500 ms only for justified gesture interaction. Motion normally fits within 300 ms and never delays input.
- Entrance/exit uses ease-out, movement ease-in-out; source curve guides are (0.23, 1, 0.32, 1), (0.77, 0, 0.175, 1), and drawer (0.32, 0.72, 0, 1). These guide Flutter rather than requiring example libraries.
- Repeated commands interrupt motion without jumps. Do not use scale(0) entrance, ease-in entrance, transition: all, endless decorative loops or per-frame blur animation. The assistant circle may indicate actual activity without introducing perpetual decorative motion.
- Feedback starts on press; hover is limited to suitable pointers rather than every surface. After the first tooltip opens, neighboring tooltips avoid a repeated delay. Menus/popovers preserve focus, Escape and their invocation anchor.
- Prefer transform/opacity equivalents without per-frame rebuilding of complex layouts. Springs require a justified gesture/drag use case. Do not promise frame rates without measurement.
- Glass and Solid share focus, hover, pressed, disabled, and selection behavior; only surface material and related depth effects vary.
- Status labels and icons accompany any status colors, including task completion, overdue states, and habit tracking.

## Review checklist for the visual design

- Inspect all three exact palettes in both Glass and Solid (six combinations), including nested menus, dialogs, tables, and charts.
- Check immediate changes, local persistence, and restoration after restart.
- Review text and chart contrast, keyboard focus, reduced motion, and the opaque blur fallback.
- Review desktop, tablet, and mobile layouts with real product data and existing routes/workflows.
- Measure visual-effects performance on the CPU/8 GiB target. This is a review requirement, not evidence that the target has been validated.
- No screenshot UI test or visual comparison has been run as part of this document task.

## Boundaries and open design details

The originals contain web terms and examples; these do not establish a running application or select a framework or dependencies. v2.1 defines only geometry, material and interaction. Content, routes, APIs and permissions come from the project. Do not create destinations, demo records or controls solely for styling. Programming remains unapproved; visual checks have not run.

Open for review: sidebar grouping and labels; exact top-bar contents; placement of task, calendar, habit, project and note panels; derived surface colors and concrete token values within v2.1. Initial theme/material and density direction are settled. Remaining details must preserve the required shell, HEX values, six combinations, opaque Solid behavior, accessibility and assistant-above-day-panel composition.
