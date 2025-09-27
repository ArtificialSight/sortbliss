# SortBliss Improvement Research

This document outlines prioritized recommendations to improve SortBliss across reliability, performance, accessibility, error handling, visual polish, and Supabase integration. Suggestions highlight relevant code hotspots and connect them with industry practices popular in mature Flutter, React, and Next.js applications.

## 1. Drag-and-drop reliability

1. **Unify drag targets and hit-testing logic.** Centralize the drag acceptance rules instead of scattering `Draggable` widgets across gameplay widgets so touch/mouse/pen input behave consistently. Adopt patterns from Flutter's `DragTarget` builder combined with pointer signal listeners (akin to React DnD's shared context providers) to resolve gesture conflicts across platforms. Conduct integration tests using `WidgetTester` to reproduce regressions automatically.
2. **Support multiple input modalities.** Replace the current `GestureDetector` tap-to-pulse implementation with a combined `LongPressDraggable`/`MouseRegion`/`FocusableActionDetector` stack so long-press, keyboard, and assistive technologies can initiate reordering. This mirrors the approach used in Next.js/React accessible drag libraries where keyboard shortcuts mirror pointer gestures.
3. **Layered feedback surfaces.** Rework drag feedback to use `OverlayEntry` with device pixel ratio scaling, enabling crisp visuals on high-density displays and ensuring compatibility with browsers that rely on HTML canvas layers. Tie animations to `TickerMode` so offscreen widgets pause animations, similar to how React Native's Reanimated pauses inactive views.
4. **Adopt a consistent reorder model.** Use a shared state container (e.g., Riverpod `StateNotifier`) to store the canonical item order and coordinate updates between `DraggableItemWidget` and `CentralPileWidget`. Back this with snapshot tests comparing expected sequences after drag events, ensuring deterministic results across web and mobile.
5. **Add browser-specific guards.** Wrap HTML5 drag detection with `kIsWeb` and `defaultTargetPlatform` checks so Safari/iPadOS can fall back to a simpler pointer-tracking implementation, following community patterns from Flutter web drag fixes.

## 2. Performance and state management

1. **Introduce layered state management.** Replace repeated `setState` calls in screens such as `MainMenu` with a unidirectional data flow (Riverpod/Bloc). Co-locate Supabase streams and local caches in providers that expose immutable models, mirroring how Redux/Next.js apps normalize data to minimize re-renders.
2. **Memoize expensive layout calculations.** Cache randomized layout math in `CentralPileWidget` and avoid recomputing scatter positions on every rebuild. Adopt `ValueListenableBuilder` or custom `InheritedModel` to recompute only when items change, similar to React's `useMemo` for derived values.
3. **Defer heavy animations.** Gate animation controllers behind `VisibilityDetector` (Flutter) so idle UI doesn't tick. This aligns with industry patterns like React's `IntersectionObserver`-driven animation triggers.
4. **Streamline asynchronous loading.** Convert `_loadDailyChallenge` into a staged pipeline (loading, success, error states) and collapse Supabase, remote config, and generated fallbacks into cancellable tasks managed by `FutureProvider`. This ensures state resets cleanly when screens are disposed, avoiding memory churn.
5. **Profile with integration tests.** Establish performance budgets using `flutter run --profile` and `TimelineSummary` exports, akin to Lighthouse audits for web apps. Automate baseline checks in CI to catch regressions.

## 3. Accessibility and responsiveness

1. **Audit responsive sizing.** Replace raw `Sizer` percentages with responsive breakpoints and `LayoutBuilder` so content scales gracefully on tablets and desktop browsers. Provide dynamic typography (Flutter `MediaQuery.textScaler`) as recommended in Material 3 and responsive React apps.
2. **Keyboard and assistive navigation.** Wrap interactive widgets in `Semantics`, `FocusableActionDetector`, and `Shortcuts` to expose accessible actions. Provide screen reader announcements and focus order metadata similar to ARIA roles in React/Next.js.
3. **High-contrast and colorblind support.** Extend `AppTheme` with semantic color tokens and ensure contrast ratios meet WCAG 2.1 AA. Offer toggles for reduced motion and high contrast, matching progressive enhancement patterns in modern SPAs.
4. **Device rotation and layout tests.** While `SystemChrome.setPreferredOrientations` locks portrait, add integration coverage for split-screen and large-screen Android/Chrome OS. Provide alternative layout rules for web builds to avoid letterboxing.

## 4. Error handling and user feedback

1. **Standardize result types.** Wrap async operations in `Result`/`Either` style classes so UI can display granular states (loading, empty, offline, unauthorized). This mirrors best practices in Next.js `useSWR` and React Query.
2. **Progressive disclosure of failures.** Expand `CustomErrorWidget` with retry controls, telemetry IDs, and context-specific actions. Surface `SnackBar`/`Banner` notifications with severity coloring, echoing Material 3 guidelines.
3. **Integrate logging and monitoring.** Connect to Crashlytics/Sentry and capture Supabase/network diagnostics with structured metadata. Provide toggles for verbose logs (`AI_DEBUG`) and tie them into a developer console accessible via gesture/keyboard shortcuts.
4. **Offline-first messaging.** Detect connectivity via `connectivity_plus` and preempt operations with inline status to avoid late failures, similar to offline heuristics in PWAs.

## 5. Visual presentation and UI polish

1. **Create a design token system.** Expand `AppTheme` into a token map consumed by widgets, bridging Flutter themes with Tailwind-like semantics used in Next.js design systems.
2. **Normalize asset usage.** Audit `assets/images` for inconsistent resolutions and convert to vector/SVG where possible. Use `AssetGenImage` or FlutterGen to avoid typos and centralize references.
3. **Enhance animation cohesion.** Replace ad-hoc `AnimationController` pulses with `ImplicitlyAnimatedWidget` or `rive` micro-interactions that respect reduced-motion settings.
4. **Design QA pipeline.** Add golden tests comparing key screens (main menu, gameplay) under light/dark themes and multiple locales, similar to Chromatic visual regression testing in React.

## 6. Supabase integration and data reliability

1. **Centralize configuration.** Expand `Environment` with explicit getters (`supabaseUrl`, `supabaseFunctionsUrl`, `supabaseDailyChallengeEndpoint`) and validation. Mirror environment schemas used in Remix/Next.js by enforcing required keys at startup.
2. **Use typed clients and retries.** Wrap Supabase REST calls in a dedicated repository using typed DTOs and exponential backoff. Align with Supabase Dart client's best practices and the resilience patterns seen in production Next.js data loaders.
3. **Secure token exchange.** Harden `SecureSupabaseClient` by caching service tokens with expiry metadata and auto-refreshing before expiration, reducing latency and matching OAuth token rotation flows in modern SPAs.
4. **Instrument database latency.** Collect metrics from Supabase (RLS performance, function timings) and feed dashboards similar to Vercel Analytics or Datadog APM used in leading web stacks.
5. **Implement contract tests.** Use integration tests that call Supabase edge functions locally via the CLI, ensuring schema changes do not break clients—akin to contract testing popularized in microservice-heavy React/Node ecosystems.

