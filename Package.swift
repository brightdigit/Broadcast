// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// AtLeast integration branch: combines non-Apple build support (#10) with watchOS support (#9)
// using a single platform-conditional strategy.
//
// Broadcast requires Swift 6.0+: it uses `Synchronization.Mutex` and, on non-Apple platforms,
// `Foundation.FormatStyle` — both of which only exist in the Swift 6.0 toolchain on Linux.
//
// Boutique (and its Bodega/SQLite/swift-collections chain) imports `CryptoKit` and does not
// support watchOS, so its *target* dependency is gated to Apple platforms excluding watchOS
// with `.when(platforms:)`. SwiftPM still resolves Boutique there but never compiles it, and
// `MultiSessionLogger` (guarded by `#if canImport(Boutique)`) compiles to nothing on watchOS
// and non-Apple platforms. `ConsoleLogger` is likewise gated on `#if canImport(OSLog)`.
//
// `swiftLanguageModes: [.v5]` keeps Swift 5 language mode so existing `static var` globals do
// not become hard concurrency errors under Swift 6 mode. watchOS/tvOS/visionOS floors match
// `Synchronization.Mutex`.
let package = Package(
	name: "Broadcast",
	platforms: [
		.iOS("18.0"),
		.macOS("15.0"),
		.watchOS("11.0"),
		.tvOS("18.0"),
		.visionOS("2.0")
	],
	products: [
		.library(
			name: "Broadcast",
			targets: ["Broadcast"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/mergesort/Boutique", from: Version(3, 0, 2)),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: Version(1, 0, 0))
	],
	targets: [
		.target(
			name: "Broadcast",
			dependencies: [
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS, .tvOS, .visionOS])
				)
			]
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: [
				"Broadcast",
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS, .tvOS, .visionOS])
				)
			]
		)
	],
	swiftLanguageModes: [.v5]
)
