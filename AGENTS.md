# Agent Guide

This repository currently contains a single planning document and no
implementation yet. The guidance below captures what is known today and
sets conventions for future code. Update this file once source code and
tooling land.

## Repository status
- Only `plan.md` exists at the time of writing.
- No `pubspec.yaml`, `lib/`, `test/`, or `analysis_options.yaml` found.
- No Cursor or Copilot rules present in this repo.
- Product intent is a Flutter + Riverpod local party game.

## Build, lint, test
Because no build system is committed yet, commands below are suggested
defaults once a Flutter project exists. Verify before running.

Always run the linter after code changes, then format the codebase.

### Bootstrap
- Install dependencies: `flutter pub get`
- Generate code (if used): `dart run build_runner build`

### Run
- Device run: `flutter run`
- Web run: `flutter run -d chrome`

### Lint
- Analyze: `flutter analyze`
- Format check: `dart format --output=none .`

### Format
- Format all: `dart format .`

### Test
- All tests: `flutter test`
- Single test file: `flutter test test/<file>_test.dart`
- Single test by name: `flutter test --name "<test name>"`

### Build
- Android APK: `flutter build apk`
- Android App Bundle: `flutter build appbundle`
- iOS (local): `flutter build ios`
- Web: `flutter build web`

If the project uses different tooling, update these commands to match
the actual scripts and CI expectations.

## Code style and conventions
These conventions align with standard Dart + Flutter guidance and the
product plan in `plan.md`.

### File layout
- `lib/` holds app code; split by feature or screen.
- `lib/models/` for immutable data classes.
- `lib/state/` for Riverpod providers and controllers.
- `lib/ui/` for screens and reusable widgets.
- `assets/` for words JSON and images.

### Imports
- Order groups: Dart SDK, Flutter SDK, third-party, local.
- Add a blank line between groups.
- Avoid wildcard exports; prefer explicit exports.

### Formatting
- Use `dart format` with default settings.
- Favor trailing commas for widget trees.
- Keep lines readable; break long argument lists.

### Types
- Prefer explicit types in public APIs and fields.
- Use type inference for obvious locals.
- Avoid `dynamic` unless there is no alternative.
- Use `enum` for phase and settings variants.

### Naming
- Files and directories: `snake_case`.
- Classes, enums, typedefs: `UpperCamelCase`.
- Methods, fields, locals: `lowerCamelCase`.
- Constants: `lowerCamelCase` with `const` and `static const`.
- Provider names should describe data or intent, not UI.

### Widgets
- Keep widgets small and focused on one concern.
- Favor composition over large build methods.
- Use `const` constructors where possible.
- Avoid side effects in `build`.

### State management (Riverpod)
- Use `StateNotifier` or `Notifier` for game state mutations.
- Keep state immutable; update via `copyWith` patterns.
- Derive UI state via providers, not direct mutation.
- Avoid provider cycles; keep dependencies explicit.

### Architecture
- Centralize game flow in a single controller per `plan.md`.
- Keep screen widgets thin; move logic into controllers/providers.
- Model transitions explicitly with a `GamePhase` enum.
- Prefer small, reusable widgets over large monoliths.

### Navigation and routing
- Keep routing simple for MVP; one screen per phase is fine.
- Avoid implicit global state changes in navigation callbacks.
- Pass identifiers through providers or route arguments, not globals.

### Error handling
- Use exceptions for programmer errors or invalid state.
- Use result objects or sealed unions for recoverable flows.
- Validate transitions in the game controller.
- Provide user-facing errors at the UI layer.

### Data and assets
- Store words in JSON with predictable schema.
- Validate word list on load; fail fast in debug.
- Keep assets declared in `pubspec.yaml`.

### Testing
- Unit-test state transitions in the game controller.
- Widget-test critical screens: start, reveal, vote, result.
- Prefer deterministic word selection in tests.
- Use descriptive test names that explain intent.

### Localization
- Keep strings in a single place once localization exists.
- Avoid hard-coded language in UI widgets.

### Accessibility
- Ensure buttons have clear labels.
- Prefer large tap targets and readable text.

### Documentation
- Update `plan.md` when product decisions change.
- Document any new assets or word list schema changes.
- Note any non-default tooling in this file.

## Product notes from plan
- One impostor per round; majority vote determines outcome.
- No timer or round-based scoring in MVP.
- Local device play; pass-the-phone reveal.
- Settings include language and categories toggles.

## Contributing workflow
- Create small, focused commits.
- Update tests when behavior changes.
- Keep `plan.md` in sync with product decisions.

## Cursor and Copilot rules
- None found in `.cursor/rules/`, `.cursorrules`, or
  `.github/copilot-instructions.md`.
- If rules are added later, mirror them here.
