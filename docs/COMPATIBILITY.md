# Compatibility

Pinned on 9 November 2026.

| Piece | Pin |
| --- | --- |
| iOS | iOS 27.3 beta (24C5037i), seeded 3 November 2026 |
| Xcode | Xcode 27.3 beta (27C5020n), seeded 3 November 2026 |
| Swift | Swift 6 language mode. The Xcode 27.3 beta release notes say the toolchain includes Swift 6.4 |
| Package platforms | iOS 27.3 and macOS 27.3 in `Package.swift` |

This is the **first** iOS 27.3 beta. Apple's releases page labels it "iOS 27.3 beta" and "Xcode 27.3 beta" and does not list an iOS 27.3 beta 2. A numbered beta 2 was not on that page on 9 November 2026. Press coverage of the 3 November seed calls it the first beta.

## Sources

Build numbers are copied from Apple's releases list. They are not guessed.

- [Releases - Apple Developer](https://developer.apple.com/news/releases/) lists, dated 3 November 2026: Xcode 27.3 beta (27C5020n), iOS 27.3 beta (24C5037i), iPadOS 27.3 beta (24C5037i), macOS 27.3 beta (26C5035r), tvOS 27.3 beta (24K5286g), visionOS 27.3 beta (24N5286r), watchOS 27.3 beta (24S5284h).
- [Get ready with the latest beta releases](https://developer.apple.com/news/?id=6gpufove) (3 November 2026) says the 27.3 betas are available and to build with Xcode 27.3.
- [Xcode 27.3 Beta Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes) say Xcode 27.3 beta includes Swift 6.4 and the iOS 27.3 SDK, and that it requires macOS Tahoe 26.6 or later.
- [Latest News - Apple Developer](https://developer.apple.com/news/) (3 November 2026, "Siri AI is now open to all developers") describes the Developer Preview: tool intents, app skills, and Spotlight entities that do not have to match an existing schema. Customer release is "in a few months." App Store submission opens in the spring.
- [Orchestrating complex actions with app skills](https://developer.apple.com/documentation/appintents/orchestrating-complex-actions-with-app-skills) documents `Skills.skillsbundle`, `SKILL.md`, and the `name` / `description` front matter.
- [ToolIntent](https://developer.apple.com/documentation/appintents/toolintent) documents `@AppIntent(.tool)` and parameter titles and descriptions.
- [Making app entities available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight) documents `IndexedEntity`, `indexAppEntities(_:priority:)`, `IndexedEntityQuery`, and `@ComputedProperty(indexingKey:)`.

## What is stable in this package, and what is preview

Stable enough to call directly, behind `#if canImport` and availability:

- `AppIntent`, `@Parameter`, `IntentDialog`, `IntentDescription`, `requestConfirmation(dialog:)`, `requestDisambiguation(among:dialog:)`.
- `AppEntity`, `EntityQuery`, `EntityStringQuery`, `OpenIntent`, `AppShortcutsProvider`.
- `IndexedEntity`, `CSSearchableIndex.indexAppEntities(_:priority:)`, `deleteAppEntities(identifiedBy:ofType:)`, `deleteAppEntities(ofType:)`, and `CSSearchableItem` for content that is not an entity.
- `@ComputedProperty(indexingKey:)` on the sample entity, as in Apple's Spotlight article.

Preview, and easy to get wrong while the 27.3 SDK is moving:

- `@AppIntent(.tool)` is a compile-time macro trait. The sample compiles it only when `SKILLSTRAND_IOS_27_3_SDK` is set, which CI does after it finds an Xcode whose version is 27.3. `#available` cannot hide a macro the toolchain does not have.
- `IndexedEntityQuery` and `CSSearchableIndexDescription` are in the iOS 27 SDK. The example query adopts them only when the compiler is Swift 6.4 or newer, which is the toolchain in the Xcode 27.3 beta. The iOS 18 `EntityStringQuery` and `attributeSet` stay available without that compiler.
- `GenerableEntity` and `@AppEntity(.generable)` are named in the preview docs for transient values the model can fill without a query. The protocol requirements were not fully spelled out on the pages above, so the package does not conform to it. The paid template pack includes a `GenerableDraft.swift` reference that shows the documented shape and is not part of this package's build.
- Property visibility `.internal` is recorded in `PropertyConvention` as `internalOnly` and is not passed to a symbol.
- A skill body is guidance. The system does not have to run the listed tools in order.

`requestValue` and `requestDisambiguation(among:dialog:)` are called on a parameter projection (`$title.requestValue(...)`, `$item.requestDisambiguation(among:dialog:)`). `ValueRequestGuide` and `DisambiguationRequestGuide` record those calls. There is no free-function wrapper, because the projection only exists inside an intent. `requestConfirmation(dialog:)` is the method on `AppIntent` itself.

## Linux and CI

`swift test` on Linux builds the planners, the skill-file validator, the index sync coordinator, and the shortcut source renderer. Apple frameworks are behind `#if canImport(AppIntents)` and `#if canImport(CoreSpotlight)`.

GitHub Actions on macOS selects an installed iPhone simulator at run time and falls back to `generic/platform=iOS Simulator`. It does not hardcode a device name or a runtime identifier. The sample's signing team is empty and signing is turned off so the build does not wait for a team.

Building the sample and the Apple-only types needs Xcode. The pinned SDK is the Xcode 27.3 beta. A runner that only has an older Xcode can still run `swift test` and can build the sample without `SKILLSTRAND_IOS_27_3_SDK`. It cannot compile `@AppIntent(.tool)`.
