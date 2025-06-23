import ProjectDescription

let project = Project(
    name: "ClaudeCodeReviewer",
    options: .options(
        automaticSchemesOptions: .enabled()
    ),
    packages: [
        .local(path: "tuist/"),
    ],
    settings: .settings(
        base: [
            // Enforces Swift 6 concurrency checks across the project.
            "SWIFT_STRICT_CONCURRENCY": "complete"
        ],
        configurations: [
            .debug(name: "Debug", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"]),
            .release(name: "Release", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "RELEASE"]),
        ]
    ),
    targets: [
        .target(
            name: "ClaudeCodeReviewer",
            destinations: .macOS,
            product: .app,
            bundleId: "com.example.ClaudeCodeReviewer",
            infoPlist: .default,
            sources: ["Sources/App/**"],
            resources: ["Sources/App/Resources/**"],
            dependencies: [
                .target(name: "CodeReviewKit")
            ]
        ),
        .target(
            name: "CodeReviewKit",
            destinations: .macOS,
            product: .framework,
            bundleId: "com.example.CodeReviewKit",
            sources: ["Sources/CodeReviewKit/**"],
            dependencies: [
            ]
        ),
        .target(
            name: "CodeReviewKitTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.example.CodeReviewKitTests",
            sources: ["Tests/CodeReviewKitTests/**"],
            dependencies: [
                .target(name: "CodeReviewKit")
            ],
            // Correctly enable the Swift Testing framework.
            settings: .settings(base: ["ENABLE_TESTING_FRAMEWORK": "YES"])
        ),
    ]
)