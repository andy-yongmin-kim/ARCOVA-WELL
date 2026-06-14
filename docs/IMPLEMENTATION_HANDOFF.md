# Arcova Well Implementation Handoff

## Objective

Implement the next product iteration in this order:

1. Redesign Home as a purely metrics-first dashboard.
2. Add real Apple Health / HealthKit support on iOS.
3. Tighten Gemini prompting and output structure.

This document is intended as a direct handoff for another agent to implement.

## Locked Decisions

- Home should be purely metrics-first.
- Home should not show a briefing teaser.
- Briefing remains in its own tab and should stay focused on interpretation and actions.
- iOS HealthKit v1 should support the 4 existing core metrics:
  - sleep
  - steps
  - active minutes
  - resting heart rate
- iOS HealthKit v1 should also surface these body metrics when available from Apple Health:
  - weight
  - BMI
  - body fat percentage
- Missing optional metrics should be hidden gracefully.

## Current State Summary

- `DashboardScreen` is a flat grid-plus-actions home screen and needs stronger hierarchy.
- `BriefingScreen` overlaps with Home conceptually, but should remain separate after the redesign.
- iOS currently uses sample data instead of real Apple Health data.
- `Info.plist` does not currently include HealthKit usage strings.
- Gemini already uses Firebase AI Logic with a JSON schema, but the prompt content is too loose.

## Implementation Order

1. Home IA/UI
2. iOS HealthKit
3. Health data model and sync updates
4. Gemini prompt contract
5. Verification

## Phase 1: Home IA/UI

### Goal

Turn Home into a true Today dashboard with clear metric hierarchy and no briefing promotion.

### Intended Home Layout

Top-to-bottom layout:

1. Greeting and date
2. Compact status line
3. Core metrics section
4. Optional body metrics section
5. Mood section
6. Streak / consistency section
7. Weekly trend preview

### File-by-File Changes

- `lib/features/wellness/presentation/screens/dashboard_screen.dart`
  - Rebuild as a metrics-first Today screen.
  - Remove the primary `View Daily Briefing` CTA.
  - Keep the core 4 metrics visually dominant.
  - Add a secondary body metrics section that renders only when at least one optional metric is present.
  - Keep mood and streak below the metric sections.
  - Keep access to Weekly Summary.
  - Move or remove any UI that makes Home feel like a briefing screen.

- `lib/features/wellness/presentation/widgets/health_stat_card.dart`
  - Support denser card spacing or a compact variant suitable for iPhone.
  - Keep the card reusable for both core and optional metric sections if practical.

- `lib/features/wellness/presentation/screens/main_shell.dart`
  - Keep current bottom-nav structure unless implementation reveals a strong reason to rename labels.
  - Ensure tab roles remain clear:
    - Home = metrics/status
    - Briefing = AI interpretation/actions
    - Check-In = mood input
    - Settings = configuration

- `lib/features/wellness/presentation/screens/briefing_screen.dart`
  - Align copy with its narrower role so it clearly complements, rather than competes with, Home.

- `lib/features/wellness/presentation/screens/weekly_summary_screen.dart`
  - Optional: leave as-is initially.
  - If touched, keep it compatible with the new Home hierarchy and future optional metrics.

### UX Constraints

- Design for iPhone first.
- Keep the visual system calm, dense, and readable.
- Avoid turning Home into a list of CTAs.
- Keep briefing access off the main hierarchy of Home.

## Phase 2: iOS HealthKit

### Goal

Replace the iOS sample-data path with real Apple Health reads.

### Primary Metrics to Read

- Sleep
- Steps
- Active minutes
- Resting heart rate

### Optional Metrics to Read When Available

- Weight
- BMI
- Body fat percentage

### File-by-File Changes

- `lib/features/wellness/providers/wellness_providers.dart`
  - Stop routing iOS to `SampleHealthDataSource` by default.
  - Route iOS to a real Apple Health data source.

- `lib/features/wellness/data/services/health_data_source.dart`
  - Keep the abstraction.
  - Update docs/comments to reflect the expanded metric set and optional fields.

- `lib/features/wellness/data/services/health_connect_data_source.dart`
  - Decide whether to generalize this file into a shared device-health reader or create a separate iOS-specific reader.
  - Minimal-change option: create a new Apple Health data source file instead of overloading the Android-specific file name.

- New file likely recommended: `lib/features/wellness/data/services/apple_health_data_source.dart`
  - Implement iOS health reads through the existing `health` plugin.
  - Request permissions for the chosen HealthKit types.
  - Read the primary metrics and optional body metrics.
  - Return the same `DailyHealthData` shape expected by the repository.

- `lib/features/wellness/presentation/screens/health_permission_screen.dart`
  - Replace iOS copy that currently says health metrics are Android-only.
  - Make iOS onboarding explain Apple Health access and the specific metrics requested.

- `lib/features/wellness/presentation/screens/onboarding_screen.dart`
  - Update copy to reflect iOS health support.

- `lib/features/wellness/presentation/screens/data_disclosure_screen.dart`
  - Update disclosure text to include Apple Health access and the optional body metrics.

- `ios/Runner/Info.plist`
  - Add:
    - `NSHealthShareUsageDescription`
    - `NSHealthUpdateUsageDescription`

- `ios/Runner.xcodeproj/project.pbxproj`
  - Enable HealthKit capability for the Runner target.

- `ios/Runner.entitlements`
  - Add if created by Xcode during capability setup.

- `ios/Runner/AppDelegate.swift`
  - Likely no code change needed.
  - Verify plugin registration remains correct.

### Notes

- No new package should be required unless the implementation decides to upgrade the existing `health` package.
- If the package is upgraded, `pubspec.yaml` and `pubspec.lock` will also change.

## Phase 3: Health Data Model and Sync

### Goal

Expand the daily health model to carry optional body metrics while preserving the current 4-metric core.

### Data Modeling Decision

Store body metrics as nullable fields on the existing daily health snapshot model.

This is the simplest implementation path. If richer body-history behavior is needed later, it can be split into a separate model.

### File-by-File Changes

- `lib/features/wellness/data/models/daily_health_data.dart`
  - Add nullable fields for:
    - `weight`
    - `bodyMassIndex`
    - `bodyFatPercentage`
  - Keep the current core fields intact.

- `lib/features/wellness/data/models/daily_health_data.g.dart`
  - Regenerate Hive adapter after model changes.

- `lib/features/wellness/data/repositories/wellness_repository.dart`
  - Persist the new fields.
  - Update snapshot creation logic if any averages or summaries should reference optional metrics.
  - Keep optional values null-safe.

- `lib/core/services/sync_service.dart`
  - Add the new fields to Firestore serialization/deserialization.

- `lib/features/wellness/data/services/health_data_source.dart`
  - Keep the fetch contract compatible when optional metrics are missing.

- `lib/main.dart`
  - Likely no logic change needed.
  - Verify Hive adapter registration remains correct after regeneration.

## Phase 4: Gemini Prompt Contract

### Goal

Keep Firebase AI Logic, but make the prompt input structured and deterministic.

### Prompt Contract Requirements

- Retain the existing system role as a supportive wellness coach.
- Do not allow diagnosis or medical advice.
- Use only provided data.
- Handle missing data explicitly but briefly.
- Return strict JSON.
- Require exactly:
  - 1 `summary`
  - 3 `insights`
  - 3 `recommendations`

### Input Shape

Pass a structured payload containing:

- today metrics
- 7-day averages
- mood/check-in data
- missing-data flags
- optional body metrics when available

### File-by-File Changes

- `lib/features/wellness/data/services/gemini_briefing_service.dart`
  - Replace the loose text prompt with a structured payload.
  - Include optional body metrics only when present.
  - Keep schema validation strict.

- `lib/features/wellness/data/services/briefing_generator.dart`
  - Keep fallback behavior aligned with the same effective input shape and tone.

- `lib/features/wellness/data/services/briefing_service.dart`
  - Likely no major logic change needed unless prompt assembly is extracted.

- `lib/features/wellness/data/models/daily_briefing.dart`
  - Likely unchanged unless the implementation wants to store richer metadata.

- New helper file optional: `lib/features/wellness/data/services/gemini_prompt_builder.dart`
  - Recommended if extracting prompt assembly improves clarity and testability.

## Phase 5: Tests and Verification

### Files to Update

- `test/smoke_test.dart`
  - Update first-frame expectations after Home redesign.
  - Remove assumptions tied to the current Home CTA.

- `test/widget_test.dart`
  - Update or extend briefing-generator coverage as needed.

- New test file optional
  - If prompt construction is extracted, add a focused test for the structured prompt payload and exact output-count requirements.

### Commands

Run after implementation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

### Manual Validation

- Verify Home layout on iPhone-sized viewport.
- Verify iOS onboarding copy reflects Apple Health support.
- Verify Apple Health permission flow appears correctly on iOS.
- Verify missing optional body metrics do not create empty cards.
- Verify briefing generation still falls back locally on remote errors.

## Suggested Execution Checklist

1. Redesign `DashboardScreen` and `HealthStatCard`.
2. Update Home-related smoke tests.
3. Add optional body metric fields to `DailyHealthData`.
4. Regenerate Hive adapters.
5. Update repository and sync mapping.
6. Implement Apple Health data source.
7. Switch iOS provider selection to real health data.
8. Update onboarding, permission, and disclosure copy.
9. Add iOS HealthKit capability and plist keys.
10. Tighten Gemini prompt structure.
11. Add or update prompt-related tests.
12. Run build, analyze, and tests.

## Risk Notes

- HealthKit capability setup may create Xcode-managed file changes outside Dart.
- Body metrics may be sparse or absent for many users; the UI must not reserve empty space for them.
- Prompt tightening must not break fallback behavior or JSON parsing.
- Hive model changes require adapter regeneration and careful backward compatibility with existing stored data.

## Definition of Done

- Home is metrics-first and no longer briefing-led.
- iOS reads real Apple Health metrics instead of sample data.
- Optional body metrics appear only when available.
- Firebase AI Logic prompt uses structured input and strict JSON output.
- Tests and analyzer pass.
- Manual iOS health-permission flow is validated.
