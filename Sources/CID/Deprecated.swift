//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-libp2p open source project
//
// Copyright (c) 2022-2026 swift-libp2p project authors
// Licensed under MIT
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of swift-libp2p project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//
//
//  Deprecated.swift
//
//  Compatibility shims for the pre-0.3.0 API
//
//  - Note: The `[UInt8]` and `Data` initializer overloads are intentionally *not* shimmed. Their
//    replacements take `some Collection<UInt8>`, which accepts `[UInt8]`, `Data`, and any slice of
//    either, so existing call sites keep compiling unchanged and without a deprecation warning.
//

import Foundation
import Multibase
import Multicodec
import Multihash

// MARK: - Versions

/// - Note: Nested inside `CID` so it reads as `CID.Version` at the use site.
@available(*, deprecated, renamed: "CID.Version")
public typealias CIDVersion = CID.Version

// MARK: - Errors

extension CIDError {

    /// - Note: Renamed to line up with `MultibaseError`, the type it now carries. Because this is
    ///   an enum *case* rename, only construction can be shimmed, code that pattern matches on
    ///   `case .invalidBaseEncoding` must migrate to `case .invalidMultibase`.
    @available(*, deprecated, renamed: "invalidMultibase")
    public static func invalidBaseEncoding(_ error: MultibaseError) -> CIDError {
        .invalidMultibase(error)
    }
}

// MARK: - Byte Accessors

extension CID {

    /// - Note: `CID` is a `RandomAccessCollection<UInt8>` over its ``CID/canonicalBytes``, so any
    ///   container can be built from the CID directly. Prefer ``CID/canonicalBytes`` when a slice
    ///   will do, since it doesn't copy.
    @available(*, deprecated, message: "Use `Array(cid)`. CID is a RandomAccessCollection<UInt8>.")
    public var rawBuffer: [UInt8] {
        Array(self.canonicalBytes)
    }

    /// - Note: `CID` is a `RandomAccessCollection<UInt8>` over its ``CID/canonicalBytes``, so any
    ///   container can be built from the CID directly. Prefer ``CID/canonicalBytes`` when a slice
    ///   will do, since it doesn't copy.
    @available(*, deprecated, message: "Use `Data(cid)`. CID is a RandomAccessCollection<UInt8>.")
    public var rawData: Data {
        Data(self.canonicalBytes)
    }
}

// MARK: - Content Hashing Initializers

extension CID {

    /// - Note: The label was renamed to match `Multihash(hashing:codec:truncatedTo:)`.
    @available(*, deprecated, message: "Use `truncatedTo:`.")
    public init(
        version: CID.Version,
        codec: Codecs,
        content: some Collection<UInt8>,
        hashedWith hashFunction: Codecs,
        customByteLength: Int?
    ) throws(CIDError) {
        try self.init(
            version: version,
            codec: codec,
            content: content,
            hashedWith: hashFunction,
            truncatedTo: customByteLength
        )
    }

    /// - Note: The label was renamed to match `Multihash(hashing:codec:truncatedTo:)`.
    @available(*, deprecated, message: "Use `truncatedTo:`.")
    public init(
        version: CID.Version,
        codec: Codecs,
        content: String,
        hashedWith hashFunction: Codecs,
        using encoding: String.Encoding = .utf8,
        customByteLength: Int?
    ) throws(CIDError) {
        try self.init(
            version: version,
            codec: codec,
            content: content,
            hashedWith: hashFunction,
            using: encoding,
            truncatedTo: customByteLength
        )
    }
}
