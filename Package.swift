// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
]

let package = Package(
    name: "Skillstrand",
    platforms: [
        .iOS("27.3"),
        .macOS("27.3"),
    ],
    products: [
        .library(name: "Skillstrand", targets: ["Skillstrand"]),
        .library(name: "SkillstrandCore", targets: ["SkillstrandCore"]),
        .library(name: "SkillstrandIntents", targets: ["SkillstrandIntents"]),
        .library(name: "SkillstrandEntities", targets: ["SkillstrandEntities"]),
        .library(name: "SkillstrandSpotlight", targets: ["SkillstrandSpotlight"]),
        .library(name: "SkillstrandShortcuts", targets: ["SkillstrandShortcuts"]),
        .library(name: "SkillstrandExamples", targets: ["SkillstrandExamples"]),
    ],
    targets: [
        .target(
            name: "SkillstrandCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SkillstrandIntents",
            dependencies: ["SkillstrandCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SkillstrandEntities",
            dependencies: ["SkillstrandCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SkillstrandSpotlight",
            dependencies: ["SkillstrandCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SkillstrandShortcuts",
            dependencies: ["SkillstrandCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SkillstrandExamples",
            dependencies: [
                "SkillstrandCore",
                "SkillstrandIntents",
                "SkillstrandEntities",
                "SkillstrandShortcuts",
                "SkillstrandSpotlight",
            ],
            resources: [
                .copy("Skills"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Skillstrand",
            dependencies: [
                "SkillstrandCore",
                "SkillstrandIntents",
                "SkillstrandEntities",
                "SkillstrandSpotlight",
                "SkillstrandShortcuts",
                "SkillstrandExamples",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SkillstrandCoreTests",
            dependencies: ["SkillstrandCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SkillstrandExamplesTests",
            dependencies: ["SkillstrandExamples", "SkillstrandSpotlight", "SkillstrandShortcuts"],
            swiftSettings: swiftSettings
        ),
    ]
)
