# QuranEngine

## Make commands

The Makefile exposes a few helpful commands:

1. Use `make build` to compile `QuranEngine-Package` with `QURAN_SYNC` disabled (or override with `make build TARGET=NoorUI`).
2. Use `make test` for package tests with `QURAN_SYNC` disabled, also honoring `TARGET` to point at another scheme/target.
3. Use `make build-example` to build the Example app with `QURAN_SYNC` disabled.
4. Run `make format-lint` for SwiftFormat checks.

Ambient `QURAN_SYNC` may be set or unset through `launchctl`, so use explicit targets when sync state matters:

- no sync: `make build-no-sync`, `make test-no-sync`, `make build-example-no-sync`
- sync enabled: `make build-sync`, `make test-sync`, `make build-example-sync`

Keeping these commands green locally should keep the CI workflow green as well.

## Architecture

- Respect target layers: `Core`/`Model` stay foundational, `Data` owns persistence/network implementations, `Domain` owns business services, `Features` own UI workflows, and `Example` wires concrete dependencies.
- Avoid dependency direction reversals. Lower layers should not import feature/app targets.
- Add new modules through the `Package.swift` target helpers and keep dependencies explicit.
- Prefer extending existing services/builders over creating parallel abstractions.
- Keep feature entry points in `*Builder` types; dependency wiring belongs in builders/container, not views.

## UI and features

- `ViewModel`, builder, and UIKit/SwiftUI presentation code should be `@MainActor` when touching UI state.
- Keep navigation through listener/navigator protocols already used by the feature.
- Views should stay mostly declarative; business logic belongs in view models/interactors/services.
- Reuse NoorUI/UIx components before adding one-off controls.
- Preserve localized strings; do not hardcode user-facing text unless existing nearby code does.

## Concurrency

- Prefer `Sendable` on models/services crossing concurrency boundaries.
- Avoid detached tasks unless there is a clear lifecycle reason.
- Prefer structured async flows; keep `Task {}` usage close to UI/event boundaries.
- Be careful with shared mutable state; use existing `Locking`, actors, or `ManagedCriticalState` patterns.

## Persistence and data

- Use existing persistence boundaries (`CoreDataPersistence`, GRDB persistence targets, test support) instead of ad hoc file/database access.
- Keep mapping between external SDK/data models and QuranEngine models in domain/data services, not features.
- Treat migrations and sync mapping as user-data-sensitive; add narrow regression coverage when changing them.

## Sync and build flags

- Code behind `QURAN_SYNC` must compile both with and without the flag.
- Any sync change should be checked with explicit sync and no-sync Make targets.
- Do not rely on ambient shell/launchctl `QURAN_SYNC`.

## Style

- Follow local `// MARK:` organization and existing access-control style.
- Prefer small files/types; split when a file grows into several responsibilities.
- Keep public API minimal; default to internal/private.
- Avoid drive-by cleanup in unrelated modules.
- Use SwiftFormat; do not hand-format around it.

## Dependencies

- New third-party dependencies need a quick health check and should be added only when they remove meaningful complexity.
- Prefer existing packages/utilities already in the repo.

## Testing guidance

- Prefer real objects whenever practical. Use real model types, services, persistence stacks, parsers, mappers, builders, and value objects instead of test doubles.
- Use fakes only at process or platform boundaries: filesystem, network/session, clock/time, bundle/resources, keychain, OAuth/auth SDK, MobileSync/external SDKs, UIKit navigation/presentation seams.
- Do not add mocks or a mocking framework. Avoid generated mocks.
- Do not introduce protocols only to make something mockable. Protocols should represent real architectural boundaries already useful in production.
- If a fake is reused across modules, put it in a dedicated `*Fake` target next to the boundary module, like `SystemDependenciesFake`, `NetworkSupportFake`, or `AuthenticationClientFake`.
- If a double is test-local and single-purpose, keep it private in that test file.
- Name test doubles by role: `Fake` for behavior/state simulation, `Spy` only when recording calls is the assertion, `Unavailable...` or `Noop...` for null behavior. Avoid `Mock`.
- Prefer asserting observable state/output over call order. Interaction assertions should be rare and mostly for delegates, navigation, analytics, or boundary effects.
- Fakes should be deterministic, small, and behavior-oriented. Do not reimplement the full production dependency.
- For persistence behavior, prefer real in-memory/temp persistence or repo test support over fakes when feasible.
- Bug fixes should include a regression test when the behavior is reachable without excessive scaffolding.
- Keep tests focused: one behavior per test, explicit setup, no hidden dependence on ambient env like `QURAN_SYNC`.
