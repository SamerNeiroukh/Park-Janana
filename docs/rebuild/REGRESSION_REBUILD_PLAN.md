# Regression System Clean-Room Rebuild Plan

## Branch
- Working branch: `rebuild/regression-system-37`
- Base: `origin/feat/regression-system-37`

## Ground Rules
- No cherry-pick or copy/paste from prior feature branch implementation.
- Rebuild from requirements and observed behavior only.
- Deliver in small, verifiable commits per phase.
- Keep generated artifacts out of git unless explicitly needed.

## Goals
- Rebuild regression/testability work with cleaner architecture and clearer contracts.
- Keep runtime behavior stable for end users.
- Improve test reliability and deterministic test execution.
- Provide reproducible local Firebase emulator workflow for development and testing.

## Scope
- App testability seams for bootstrap and home/profile flows.
- Model parsing hardening and serialization consistency.
- Widget and unit regression tests for critical paths.
- Firebase emulator development workflow (scripts, tasks, docs).
- Coverage summary utility and developer guidance.

## Non-Goals
- Feature redesign of product UX.
- Business logic expansion outside regression/system hardening.
- Broad refactor of unrelated modules.

## Phase Plan

## Phase 1: Planning and Specification
### Objective
Lock exact requirements, behavior contracts, and acceptance criteria before coding.

### Deliverables
- Detailed Phase 1 spec document.
- Test matrix by module and scenario.
- File ownership/change map for implementation phases.
- Risks and constraints list.

### Exit Criteria
- All target behaviors defined and testable.
- Open questions resolved or explicitly parked.

## Phase 2: Testability Seams in App Entry and Screens
### Objective
Make app bootstrap and key screens deterministic for tests.

### Target Areas
- `lib/main.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/home/personal_area_screen.dart`
- `lib/services/auth_service.dart`
- `lib/screens/splash_screen.dart`

### Deliverables
- Injectable dependencies for auth/stream/timers where required.
- Test mode flags for deterministic rendering of heavy widgets.
- Guardrails preventing async side effects in test mode.

### Exit Criteria
- App entry and route flow can be tested without live Firebase.
- No timer leaks or flaky async navigation in tests.

## Phase 3: Model Robustness and Serialization
### Objective
Harden map parsing against missing/invalid fields and ensure map symmetry.

### Target Areas
- `lib/models/attendance_model.dart`
- `lib/models/task_model.dart`
- `lib/models/shift_model.dart`

### Deliverables
- Defensive defaults and type checks.
- Stable `toMap` contracts where needed.
- Unit tests for null/missing/invalid/boundary data.

### Exit Criteria
- Models are resilient to malformed Firestore payloads.
- Unit tests cover success and failure paths.

## Phase 4: Regression Test Suite
### Objective
Build focused tests for high-value app behavior and routing.

### Test Areas
- Main flow tests (splash, auth stream branches, route fallbacks).
- Home screen role/button behavior tests.
- Profile route behavior tests.
- Worker reports and utility tests.

### Deliverables
- Organized tests under `test/widgets`, `test/models`, `test/utils`, `test/screens`.
- Clear naming and deterministic setup with mocks/fakes.

### Exit Criteria
- `flutter test` is stable and repeatable locally.
- Flaky test patterns removed.

## Phase 5: Firebase Emulator Developer Workflow
### Objective
Standardize local emulator startup and app-run workflow.

### Target Areas
- Android network security config for local emulator connectivity.
- PowerShell scripts for dev startup and e2e runner.
- VS Code tasks for common developer actions.
- Team docs for setup and troubleshooting.

### Deliverables
- Scripted startup flow with host/IP handling.
- Documented commands and troubleshooting paths.
- Optional e2e harness structure (if retained in scope).

### Exit Criteria
- New developer can follow docs and run workflow end-to-end.
- Emulator connectivity is predictable across environments.

## Phase 6: Hardening and Release Readiness
### Objective
Finalize branch quality and prepare merge candidate.

### Deliverables
- Dependency and lint checks.
- Prune generated artifacts from tracking.
- Final validation pass and summary report.

### Exit Criteria
- Clean git diff with intentional files only.
- All required tests pass.

## Risks and Mitigations
- Risk: Hidden coupling to Firebase singletons.
  - Mitigation: Inject dependencies at app boundary and service constructors.
- Risk: Flaky timer/network behavior in widget tests.
  - Mitigation: Replace delayed futures with controlled timers and test overrides.
- Risk: Emulator host differences per device.
  - Mitigation: Scripted host detection and explicit override options.
- Risk: Scope creep.
  - Mitigation: Phase gates and strict non-goals.

## Quality Gates
- Gate 1: Phase 1 spec approved.
- Gate 2: Testability seam tests pass.
- Gate 3: Model robustness tests pass.
- Gate 4: Full widget/unit suite passes.
- Gate 5: Emulator workflow validated from docs.

## Definition of Done
- Plan phases implemented with passing tests.
- Docs reflect actual workflow and commands.
- No unintended generated or secret files tracked.
- Branch ready for review with clear change narrative.

