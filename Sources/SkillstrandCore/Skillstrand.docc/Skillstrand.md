# ``SkillstrandCore``

@Metadata {
    @DisplayName("Skillstrand")
}

Skillstrand is an open-source starter kit for multi-step assistant skills in an iOS app.

The package is pinned to the iOS 27.3 beta and the matching Xcode 27.3 beta. A skill file is guidance for the system assistant. The planners in this package are what you test: confirmation, disambiguation, and a Spotlight diff.

## Overview

Import `Skillstrand` to re-export every module, or import the module you need.

- ``SkillDocumentParser`` checks a `SKILL.md` file against the front matter rules.
- `IntentBlueprint` describes a tool without linking App Intents.
- `EntityQueryScaffold` is the in-memory stand-in for an entity query.
- `IndexSyncSession` plans index, update, and delete batches.
- `AppShortcutsSource` renders an `AppShortcutsProvider`.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:TemplatesPro>

### Skills

- <doc:CaptureToTask>
- <doc:SearchAndOpen>
- <doc:SummarizeAndShare>
- <doc:ScheduledReminder>
