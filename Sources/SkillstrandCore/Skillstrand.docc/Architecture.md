# Architecture

Planners stay free of system frameworks. Bridges compile only when those frameworks exist.

## Overview

`SkillstrandCore` holds the skill file model, dialog values, and the step trace.

`SkillstrandIntents` holds the parameter builder and `SkillErrorMapping`. With App Intents linked, `SkillIntentResults` builds an `IntentDialog`, and `AppIntent.confirm(_:)` calls `requestConfirmation(dialog:)`.

`SkillstrandEntities` holds `PropertyConvention` and `EntityQueryScaffold`. `internalOnly` is the package's name for the preview visibility `.internal`. The symbol is not called.

`SkillstrandSpotlight` holds `IndexSyncCoordinator` and `EntitySpotlightBridge`. The bridge uses a named `CSSearchableIndex`, `indexAppEntities(_:priority:)`, and `deleteAppEntities(identifiedBy:ofType:)`.

`SkillstrandShortcuts` checks phrases and renders a provider.

`SkillstrandExamples` is the four skills plus the App Intent types the sample registers. Those types are behind `canImport`.

## What a skill does not do

The assistant reads the Markdown and chooses tools. The package does not pretend the body is a script. The planners exist so the questions inside that body — a missing title, two matches, a confirmation — have one tested outcome.
