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

import Foundation

/// Equatable
///
/// - Note: Two CIDs are equal when their canonical bytes (``CID/canonicalBytes``, version, codec
///   and multihash) match. The `multibase` used for string presentation is intentionally **not**
///   part of equality, so the same CID rendered in different bases compares equal.
public func == (lhs: CID, rhs: CID) -> Bool {
    lhs.canonicalBytes.elementsEqual(rhs.canonicalBytes)
}

/// Hashable
///
/// Hashes the same canonical bytes that `==` compares, so equal CIDs always share a hash value
/// (safe for use as `Set` members / `Dictionary` keys).
extension CID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.count)
        self.withUnsafeBytes { hasher.combine(bytes: $0) }
    }
}

extension CID: RandomAccessCollection {
    public typealias Element = UInt8
    public typealias Index = Int

    /// - Warning: An index into the internal buffer, so not necessarily `0` based. It is `2` for a
    ///   CIDv0, whose canonical bytes start past the implicit version and codec.
    public var startIndex: Int { self.canonicalStart }

    /// - Warning: An index into the internal buffer, so not necessarily `0` based.
    public var endIndex: Int { self.value.endIndex }

    public subscript(position: Int) -> UInt8 { self.value[position] }

    /// Hands out the backing storage directly, so `Array(cid)`, `Data(cid)`, and anything else
    /// built on `Sequence` bulk copy instead of walking the CID element by element.
    ///
    /// - Note: The buffer holds the ``CID/canonicalBytes`` in order and is `0` based, unlike this
    ///   collection's own `startIndex`.
    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<UInt8>) throws -> R
    ) rethrows -> R? {
        try self.canonicalBytes.withContiguousStorageIfAvailable(body)
    }
}

extension CID: ContiguousBytes {
    /// Calls `body` with a contiguous view of this CID's ``canonicalBytes``.
    ///
    /// - Note: The pointer is only valid for the duration of the call.
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try self.canonicalBytes.withUnsafeBytes(body)
    }
}

/// Codable
///
/// A CID is encoded as its single canonical, multibase-prefixed string (via `toBaseEncodedString`)
/// and decoded back through `init(_ cid: String)`.
extension CID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toBaseEncodedString)
    }
}

extension CID: CustomStringConvertible {
    public var description: String {
        """
        CID (\(self.version)):
         - Base: \(self.multibase) (\(self.multibase.prefixBytes), \(self.multibase.prefix))
         - Codec: \(self.codec.name) (\(self.code))
         - Hash: \(self.multihash)
        """
    }
}
