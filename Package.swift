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
// Windows carve-out: `.when(platforms:)` gates *linking*, not *resolution* — SwiftPM still
// checks out Boutique/Bodega everywhere. Bodega commits generated DocC docs whose filenames
// contain characters illegal on Windows/NTFS (e.g. `(_:_:).json`), so `git checkout` fails
// during dependency resolution on Windows. The manifest is compiled per-host, so we drop the
// Boutique *package* declaration entirely under `#if os(Windows)`; `MultiSessionLogger` is
// already `#if canImport(Boutique)`-guarded, so no source needs to change.
//
// `swiftLanguageModes: [.v5]` keeps Swift 5 language mode so existing `static var` globals do
// not become hard concurrency errors under Swift 6 mode. watchOS/tvOS/visionOS floors match
// `Synchronization.Mutex`.
#if os(Windows)
let boutiquePackageDependencies: [Package.Dependency] = []
let boutiqueTargetDependencies: [Target.Dependency] = []
#else
let boutiquePackageDependencies: [Package.Dependency] = [
	.package(url: "https://github.com/mergesort/Boutique", from: Version(3, 0, 2))
]
let boutiqueTargetDependencies: [Target.Dependency] = [
	.product(
		name: "Boutique",
		package: "Boutique",
		condition: .when(platforms: [.iOS, .macOS, .tvOS, .visionOS])
	)
]
#endif

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
	dependencies: boutiquePackageDependencies + [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: Version(1, 0, 0))
	],
	targets: [
		.target(
			name: "Broadcast",
			dependencies: boutiqueTargetDependencies
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: ["Broadcast"] + boutiqueTargetDependencies
		)
	],
	swiftLanguageModes: [.v5]
)
