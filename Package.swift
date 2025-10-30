// swift-tools-version:6.0
//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2025 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "swift-cid",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CID",
            targets: ["CID"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swift-libp2p/swift-multibase.git", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/swift-libp2p/swift-multicodec.git", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/swift-libp2p/swift-multihash.git", .upToNextMinor(from: "0.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CID",
            dependencies: [
                .product(name: "Multihash", package: "swift-multihash"),
                .product(name: "Multibase", package: "swift-multibase"),
                .product(name: "Multicodec", package: "swift-multicodec"),
            ]
        ),
        .testTarget(
            name: "CIDTests",
            dependencies: ["CID"]
        ),
    ]
)
