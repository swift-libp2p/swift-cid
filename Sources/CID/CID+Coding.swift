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

import Multibase
import Multicodec
import Multihash
import VarInt

// MARK: - Decoding

extension CID {

    /// Decodes a CID at the front of `bytes`, returning whatever follows it.
    ///
    /// ```swift
    /// let (cid, rest) = try CID.decode(prefixed: buffer)
    /// ```
    ///
    /// Mirrors `Multihash.decode(prefixed:)` and `Codecs.decode(prefixed:)`.
    ///
    /// - Parameters:
    ///   - bytes: A buffer beginning with a CID.
    ///   - base: The base to render the decoded CID in. Defaults to base58btc for a v0 and base32
    ///     for a v1.
    /// - Returns: The CID, and a slice of everything after it.
    /// - Throws:
    ///   - ``CIDError/cidStringTooShort`` if `bytes` is empty or ends part way through the version
    ///   - ``CIDError/invalidVersion`` if the version isn't a minimally encoded `0` or `1`
    ///   - ``CIDError/invalidMulticodec(_:)`` if the content-type codec can't be decoded
    ///   - ``CIDError/invalidMultihash(_:)`` if the multihash can't be decoded.
    public static func decode<Bytes: Collection<UInt8>>(
        prefixed bytes: Bytes,
        base: BaseEncoding? = nil
    ) throws(CIDError) -> (cid: CID, remaining: Bytes.SubSequence) {
        // A CIDv0 is a bare 34 byte sha2-256 multihash, its version and codec are implicit.
        //
        // This can't shadow a v1 CID, version 1 leads with the VarInt `0x01`, whereas a bare v0
        // always leads with the sha2-256 code `0x12` (== 18), and there is no CIDv18.
        if let (multihash, remaining) = try? Multihash.decode(prefixed: bytes),
            multihash.algorithm == .sha2_256,
            multihash.digestLength == 32
        {
            return (try CID(v0WithMultihash: multihash), remaining)
        }

        // Otherwise we have an explicitly framed CID: <Version> <Codec> <Multihash>
        let (version, afterVersion) = try CID.decodeVersion(bytes)

        let codec: Codecs
        let framedMultihash: Bytes.SubSequence
        do {
            (codec, framedMultihash) = try Codecs.decode(prefixed: bytes[afterVersion...])
        } catch let error as MulticodecError {
            throw CIDError.invalidMulticodec(error)
        } catch {
            throw CIDError.invalidCIDString
        }

        let multihash: Multihash
        let remaining: Bytes.SubSequence
        do { (multihash, remaining) = try Multihash.decode(prefixed: framedMultihash) } catch {
            throw CIDError.invalidMultihash(error)
        }

        let cid = try CID(
            version: version,
            codec: codec,
            hash: multihash,
            multibase: base ?? (version == .v0 ? .base58btc : .base32)
        )
        return (cid, remaining)
    }

    /// Reads the CID version uVarInt at the front of `bytes`.
    ///
    /// Decoded as a uVarInt rather than as a single byte so that a non-minimally encoded version
    /// (`0x81 0x00` for `1`) is rejected, as the spec requires.
    static func decodeVersion<Bytes: Collection<UInt8>>(
        _ bytes: Bytes
    ) throws(CIDError) -> (version: CID.Version, end: Bytes.Index) {
        let decoded: (value: UInt64, end: Bytes.Index)
        do { decoded = try VarInt.decode(bytes) } catch VarIntError.needsMoreBytes {
            // The buffer was empty, or ended part way through the version
            throw CIDError.cidStringTooShort
        } catch {
            // The version wasn't a valid, minimally encoded 64 bit uVarInt
            throw CIDError.invalidVersion
        }

        // v2 and v3 are reserved but not used yet.
        guard decoded.value <= 1, let version = CID.Version(rawValue: Int(decoded.value)) else {
            throw CIDError.invalidVersion
        }
        return (version, decoded.end)
    }
}

extension Collection<UInt8> {

    /// The CID at the front of this buffer, and the bytes that follow it.
    ///
    /// ```swift
    /// let (cid, rest) = try buffer.cid()
    /// ```
    ///
    /// - Returns: The CID, and a slice of this buffer after it.
    /// - Throws:
    ///   - ``CIDError/cidStringTooShort`` if `bytes` is empty or ends part way through the version
    ///   - ``CIDError/invalidVersion`` if the version isn't a minimally encoded `0` or `1`
    ///   - ``CIDError/invalidMulticodec(_:)`` if the content-type codec can't be decoded
    ///   - ``CIDError/invalidMultihash(_:)`` if the multihash can't be decoded.
    public func cid() throws(CIDError) -> (cid: CID, bytes: SubSequence) {
        let (cid, remaining) = try CID.decode(prefixed: self)
        return (cid: cid, bytes: remaining)
    }
}

// MARK: - Encoding

extension CID {
    /// Returns the CID in the base that it was initialized in...
    public var toBaseEncodedString: String {
        if self.version == .v0 {
            return self.multihash.asString(base: .base58btc)  //self.multibase)
        }
        return self.canonicalBytes.asString(base: self.multibase, withMultibasePrefix: true)
    }

    /// Returns the CID in the base specified...
    public func toBaseEncodedString(_ base: BaseEncoding) throws(CIDError) -> String {
        if self.version == .v0 {
            guard base == .base58btc else { throw CIDError.invalidV0Multibase }
            return self.multihash.asString(base: .base58btc)
        }
        return self.canonicalBytes.asString(base: base, withMultibasePrefix: true)
    }

    /// Returns the canonical, multibase-prefixed CID string encoded in the requested `base`.
    ///
    /// This is the public, spec-compliant way to render a CID in an arbitrary base. For a CIDv0
    /// only `.base58btc` is permitted (any other base throws `CIDError.invalidV0Multibase`).
    public func string(base: BaseEncoding) throws(CIDError) -> String {
        try self.toBaseEncodedString(base)
    }

    /// Returns the entirety of the CID (prefixs and Multihash digest) as a base encoded string without the Multibase prefix
    /// - Warning: Use CID.toBaseEncodedString to ensure you receive a proper CID compliant string. This method should only be used for debugging purposes...
    func asString(base: BaseEncoding) throws(CIDError) -> String {
        if base != .base58btc && self.version == .v0 { throw CIDError.invalidV0Multibase }
        return self.value.asString(base: base)
    }

    /// Returns the entirety of the CID (prefixs and Multihash digest) as a base encoded string with the Multibase prefix
    /// - Warning: Use CID.toBaseEncodedString to ensure you receive a proper CID compliant string. This method should only be used for debugging purposes...
    func asMultibase(_ base: BaseEncoding) throws(CIDError) -> String {
        if base != .base58btc && self.version == .v0 { throw CIDError.invalidV0Multibase }
        return self.value.asString(base: base, withMultibasePrefix: true)
    }
}
