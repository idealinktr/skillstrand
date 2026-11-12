# Getting started

Add Skillstrand to an app, then add one skills bundle.

## Overview

The planners build on Linux. App Intents, Spotlight, and the sample app need Xcode, pinned to the Xcode 27.3 beta. See the repository `docs/COMPATIBILITY.md` for the build numbers and the source URLs.

## Add the package

Depend on the package and link the `Skillstrand` product. The signing team in the sample is empty on purpose.

## Add a skills bundle

Create `Skills.skillsbundle` and put it in Copy Bundle Resources. An app target gets one bundle. Each skill is a directory of lowercase letters, digits, and single hyphens, containing only `SKILL.md`.

The front matter allows `name` and `description`. The name must match the directory. The description is one line, at most 1024 characters. ``SkillBundleValidator`` enforces those rules.

## Register shortcuts

Phrases have to include the application name. Write that token as `{applicationName}` in a `ShortcutBlueprint`, then as `\(.applicationName)` inside an `AppShortcutsProvider`. `AppShortcutsSource` renders the provider.

## Turn on the tool trait

`@AppIntent(.tool)` compiles only when the target defines `SKILLSTRAND_IOS_27_3_SDK`. That flag means the toolchain is the Xcode 27.3 beta. Availability checks cannot hide a missing macro.
