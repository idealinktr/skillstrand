# Skillstrand

Skillstrand is an open-source Swift starter kit for multi-step assistant skills in an iOS app. It targets the system assistant in the iOS 27.3 developer preview (Siri AI, reached through App Intents). The product name and the logo do not use Apple marks.

The open-source package is MIT. A paid template pack is sold separately and is not part of this repository. Buyers get access to a private repository after a Stripe checkout.

## Names

**Skillstrand** is the name used here.

Two other original names were clear of well-known Swift packages and products:

- **Shuttlemark.** ShuttleX is a different macOS SSH menu app.
- **Futtock.** A ship's curved rib. No Swift package or product by that name turned up.

These were set aside because something else already uses them: Lumenstep, Skeinworks, Quillwright, Tidemark (a Swift markdown package), Cordwainer, and Heddle. The Swift package `strand` is a Postgres workflow engine, which is why this one is Skillstrand.

## Pin

iOS 27.3 beta (24C5037i) and Xcode 27.3 beta (27C5020n), both seeded 3 November 2026. That is the first 27.3 beta. Apple's releases list had no 27.3 beta 2 on 9 November 2026. Build numbers and links are in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Package

| Module | What it holds |
| --- | --- |
| `SkillstrandCore` | Skill-file parser and the step trace |
| `SkillstrandIntents` | Intent and parameter builders, dialogs, error mapping |
| `SkillstrandEntities` | Entity property conventions and an in-memory query |
| `SkillstrandSpotlight` | Fingerprint diff, batch plan, `CSSearchableIndex` bridge |
| `SkillstrandShortcuts` | Phrase checks and an `AppShortcutsProvider` renderer |
| `SkillstrandExamples` | Four skills, their `SKILL.md` files, and the App Intent types |
| `Skillstrand` | Re-exports the modules above |

Apple frameworks are behind `canImport`. `@AppIntent(.tool)` is compiled only when the sample is built with `SKILLSTRAND_IOS_27_3_SDK`, because that macro exists in the pinned Xcode beta and `#available` cannot hide it.

## Skills

- **capture-to-task** confirms the title, then asks about a due date.
- **search-and-open** opens one match and asks when several titles match.
- **summarize-and-share** shortens a note, picks a destination, and confirms.
- **scheduled-reminder** turns "Friday" into one confirmed time.

`swift test` covers each path.

## Run the tests

Swift 6.0 or later. On Linux this runs the planners, the skill-file checks, and the index coordinator. It does not compile App Intents.

```sh
swift test
```

## Sample app

Needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen). The deployment target is iOS 27.3. The signing team is empty and signing is off so a simulator build does not ask for a team. Put a team in before a device run.

```sh
brew install xcodegen
cd Examples/SampleApp
xcodegen generate
xcodebuild -project SkillstrandSample.xcodeproj -scheme SkillstrandSample \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The app walks every example and shows the Spotlight diff. `SampleShortcuts` registers phrases that include the application name.

## Docs site

Static files live in `site/` and can be deployed on Vercel from the repository root (`vercel.json` publishes that directory). DocC sources are in `Sources/SkillstrandCore/Skillstrand.docc/`. Building the DocC archive needs the DocC tool from a Swift or Xcode toolchain:

```sh
swift package generate-documentation --target SkillstrandCore
```

Preview the site locally:

```sh
python3 -m http.server 47231 --directory site
```

## Template pack

A paid template pack (sold separately, not in this repository) adds three more skills, three Xcode file templates, and a `GenerableEntity` reference that is not compiled. Launch price is $49 until 14 December 2026, then $79, one-time. Checkout is a hosted Stripe Payment Link. `api/stripe-webhook.mjs` listens for `checkout.session.completed` and invites the buyer's GitHub username to the private pack repository with read access. No card data touches this repo or the site.

## What needs Xcode

- `AppIntent`, `AppEntity`, `EntityQuery`, `IndexedEntity`, and `AppShortcutsProvider`
- The sample app, including the skills bundle and the shortcut provider
- `@AppIntent(.tool)`, and only with the Xcode 27.3 beta
- A DocC archive, if `docc` is not installed with the Linux toolchain

## CI

`.github/workflows/ci.yml` runs `swift test` on Linux and, on macOS, picks an installed iPhone simulator at run time. If none is installed it uses `generic/platform=iOS Simulator`. It does not hardcode a device name or a runtime. When an Xcode 27.3 beta is installed, the sample build also defines `SKILLSTRAND_IOS_27_3_SDK`.
