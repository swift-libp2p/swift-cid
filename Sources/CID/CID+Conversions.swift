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

extension CID {
    /// Converts this CID to v1 in place. The multihash is preserved across versions.
    ///
    /// ```swift
    /// var cid = try CID("QmYtUc4iTCbbfVSDNKvtQqrfyezPPnFvE33wFmutw9PBBk")
    /// cid.toV1()
    /// cid.version  // .v1
    /// ```
    ///
    /// Every v0 is representable as a v1, so this can't fail. A CID that is already a v1 is left
    /// untouched.
    ///
    /// - Note: The existing `multibase` is preserved. A CIDv0 (always base58btc) therefore becomes a
    ///   v1 that still renders in base58btc rather than the conventional v1 default of base32, call
    ///   `string(base: .base32)` (or re-create with a base32 multibase) if you need the base32 form.
    public mutating func toV1() {
        if self.version == .v1 { return }
        self = try! CID(version: .v1, codec: self.codec, hash: self.multihash, multibase: self.multibase)
    }

    /// Converts this CID to v0 in place, if the spec allows it. The multihash is preserved across
    /// versions.
    ///
    /// ```swift
    /// var cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
    /// try cid.toV0()
    /// cid.version  // .v0
    /// ```
    ///
    /// Unlike ``toV1()`` this is lossy in the other direction, a v0 carries no version or codec of
    /// its own, so only a `dag-pb` CID over a full length sha2-256 multihash qualifies. A CID that
    /// is already a v0 is left untouched.
    ///
    /// - Throws:
    ///   - ``CIDError/invalidV0Codec`` if this CID's codec isn't `.dag_pb`.
    ///   - ``CIDError/invalidV0Multihash`` if its multihash isn't a 32 byte sha2-256 digest.
    ///
    /// - Note: The `multibase` becomes base58btc, the only base a v0 may be written in. The original
    ///   is left unchanged when this throws.
    public mutating func toV0() throws(CIDError) {
        if self.version == .v0 { return }
        //V0 CID's must use .dag-pb codec and base58btc encoding and multihashed with sha2_256...
        guard self.codec == .dag_pb else { throw CIDError.invalidV0Codec }
        guard self.multihash.algorithm == .sha2_256, self.multihash.digestLength == 32 else {
            throw CIDError.invalidV0Multihash
        }
        self = try CID(version: .v0, codec: self.codec, hash: self.multihash, multibase: .base58btc)
    }

    /// Returns a copy of this CID converted to v1, leaving the original unchanged.
    ///
    /// ```swift
    /// let v1 = try CID("QmYtUc4iTCbbfVSDNKvtQqrfyezPPnFvE33wFmutw9PBBk").convertedToV1()
    /// ```
    ///
    /// - Returns: The v1 form of this CID, or a copy of it if it already is one.
    ///
    /// - SeeAlso: The mutating ``toV1()`` for the base-preservation behavior.
    public func convertedToV1() -> CID {
        var copy = self
        copy.toV1()
        return copy
    }

    /// Returns a copy of this CID converted to v0, leaving the original unchanged.
    ///
    /// ```swift
    /// let v0 = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u").convertedToV0()
    /// ```
    ///
    /// - Returns: The v0 form of this CID, or a copy of it if it already is one.
    /// - Throws:
    ///   - ``CIDError/invalidV0Codec`` if this CID's codec isn't `.dag_pb`.
    ///   - ``CIDError/invalidV0Multihash`` if its multihash isn't a 32 byte sha2-256 digest.
    ///
    /// - SeeAlso: The mutating ``toV0()`` for the full set of v0 constraints.
    public func convertedToV0() throws(CIDError) -> CID {
        var copy = self
        try copy.toV0()
        return copy
    }
}
