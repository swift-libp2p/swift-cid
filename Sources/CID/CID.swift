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
import Multibase
import Multicodec
import Multihash
import VarInt

/// A self describing, content addressed identifier.
///
/// The binary form of a CIDv1 is three parts back to back:
/// ```
/// <uVarInt version><uVarInt content-type codec><multihash>
/// ```
/// A CIDv0 is the bare `<multihash>`, its version (`0`) and codec (`dag-pb`) are implicit.
///
/// ```swift
/// let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
/// cid.version                     // .v1
/// cid.codec                       // dag-pb
/// try cid.string(base: .base16)   // "f01701220…"
/// ```
///
/// CID conforms to `RandomAccessCollection` over its ``canonicalBytes``, so it can be used
/// wherever a collection of bytes is needed, without copying.
///
/// ```swift
/// Data(cid)                   // Foundation
/// buffer.writeBytes(cid)      // NIO ByteBuffer
/// ```
///
/// - Warning: Because a CID's `canonicalBytes` are a *slice* of the internal buffer, `startIndex`
///   is not necessarily `0` (it is `2` for a v0). Index using `startIndex` / `indices` rather
///   than integer literals.
public struct CID: Equatable, Sendable {

    public enum Version: Int, Sendable {
        case v0 = 0
        case v1 = 1
    }

    /// The CID buffer, always in v1 framing: `<version><codec><hash-algo><hash-length><digest>`.
    ///
    /// A CIDv0 keeps the framing internally (it is what ``prefix`` and ``asString(base:)`` describe)
    /// but exposes only the bare multihash as its canonical bytes. See ``canonicalStart``.
    let value: [UInt8]

    /// Where this CID's canonical bytes begin in ``value``.
    ///
    /// `0` for a CIDv1. For a CIDv0 it is the combined width of the synthetic version and codec
    /// prefixes, because the spec mandates the bare multihash as a v0's binary form.
    let canonicalStart: Int

    /// Integer based Enum, currently supports v0 or v1
    public let version: CID.Version

    /// The `Codec` used (ex: 'dag-pb')
    public let codec: Codecs

    /// The Multibase used for encoding (ex: 'base32')
    public let multibase: BaseEncoding

    /// The CIDs Multihash
    public let multihash: Multihash

    /// Returns the Integer code of the Codec used by this CID (ex: dag-pb' -> 112)
    public var code: Int {
        Int(self.codec.code)
    }

    /// The canonical bytes of this CID.
    ///
    /// A slice of the internal buffer, so reading it doesn't copy. When a standalone buffer is
    /// needed, wrap the CID itself (ex: `Array(cid)` or `Data(cid)`).
    ///
    /// - Note: For a CIDv0 this is the bare 34 byte multihash (`<hash-algo><hash-length><digest>`)
    ///   as mandated by the CID spec, the version and codec are implicit and are **not** encoded.
    public var canonicalBytes: ArraySlice<UInt8> {
        self.value[self.canonicalStart...]
    }

    /// Returns the CIDs Prefix (includes everything but the multihash digest)
    ///
    /// The CID prefix includes the following...
    /// - [version] [codec] [hash-algo] [hash-length]
    ///
    /// - Note: A CIDv0's prefix describes the framing this package uses internally (`00 70 …`),
    ///   not the v0's canonical bytes, which carry no version or codec.
    public var prefix: [UInt8] {
        Array(self.value.dropLast(self.multihash.digestLength))
    }

    // MARK: - Initializers

    /// Initialize a CID from a CID compliant String
    ///
    /// - Parameter cid: A CID string, either a bare base58btc CIDv0 (`Qm…`) or a multibase
    ///   prefixed CIDv1.
    /// - Throws:
    ///   - ``CIDError/invalidMultibase`` if the string isn't Multibase encoded correctly.
    ///   - ``CIDError/invalidCIDString`` if the CID itself is malformed.
    public init(_ cid: some StringProtocol) throws(CIDError) {
        // After base decoding, CID data consists of...
        // <Version 1 byte> <Codec> <Multihash>
        //
        // Note: Multibase decodes a bare `Qm…` CIDv0 as base58btc, so both shapes land here.
        let decoded: (base: BaseEncoding, bytes: [UInt8])
        do { decoded = try cid.multibase() } catch { throw CIDError.invalidMultibase(error) }

        // A multibase-encoded CID may not decode to a leading `0x12` byte. CIDv0
        // multihashes (sha2-256, aka `0x12`) are never multibase-encoded, and there is no CIDv18
        // (`0x12` = 18), so an explicit multibase prefix followed by `0x12` is ambiguous.
        // Bare base58btc "Qm..." v0 CIDs carry no explicit prefix and remain valid.
        if decoded.bytes.first == 0x12, !cid.hasPrefix("Qm") {
            throw CIDError.invalidCIDString
        }

        try self.init(decoded.bytes, base: decoded.base)
    }

    /// Initialize a CID from a CID compliant byte collection
    ///
    /// ```swift
    /// let cid = try CID(buffer)
    /// ```
    ///
    /// - Parameters:
    ///   - cid: The CID bytes, and nothing else.
    ///   - base: The base to render this CID in. Defaults to base58btc for a v0 and base32 for a v1.
    /// - Throws:
    ///   - ``CIDError/trailingBytes`` if anything follows the CID.
    ///
    /// - Note: Use ``decode(prefixed:base:)`` when the CID is embedded in a larger buffer.
    public init(_ cid: some Collection<UInt8>, base: BaseEncoding? = nil) throws(CIDError) {
        let (decoded, remaining) = try CID.decode(prefixed: cid, base: base)
        guard remaining.isEmpty else { throw CIDError.trailingBytes }
        self = decoded
    }

    /// Initialize a new Version 0 CID with a Multihash compliant byte collection
    ///
    /// ```swift
    /// let cid = try CID(v0WithMultihash: multihashBytes)
    /// ```
    ///
    /// - Parameter multihash: The Multihash bytes (`<hash-algo><hash-length><digest>`), prefixes
    ///   included, and nothing else.
    /// - Throws:
    ///   - ``CIDError/invalidMultihash(_:)`` if `multihash` isn't exactly one well formed Multihash.
    public init(v0WithMultihash multihash: some Collection<UInt8>) throws(CIDError) {
        let mh: Multihash
        do { mh = try Multihash(multihash) } catch { throw CIDError.invalidMultihash(error) }
        try self.init(v0WithMultihash: mh)
    }

    /// Initialize a new Version 0 CID with a Multihash
    ///
    /// A v0's codec (`dag-pb`) and presentation base (base58btc) are implicit, so the Multihash is
    /// all that's needed.
    ///
    /// - Parameter multihash: The Multihash to address, conventionally a 32 byte sha2-256 digest.
    ///
    /// - Note: The hash function isn't checked here, so an out of spec v0 can be built. Use
    ///   ``toV0()`` / ``convertedToV0()`` when the 32 byte sha2-256 constraint should be enforced.
    public init(v0WithMultihash multihash: Multihash) throws(CIDError) {
        try self.init(version: .v0, codec: .dag_pb, hash: multihash, multibase: .base58btc)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash compliant String
    ///
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - multihash: A string whose UTF8 bytes *are* the Multihash, prefixes included. This is a
    ///     byte carrying string, not a base encoded one, so a base16 / base58btc Multihash string
    ///     won't parse here. Decode it into bytes (or a `Multihash`) first.
    /// - Throws:
    ///   - ``CIDError/invalidV0Codec`` if `version` is `.v0` and `codec` isn't `.dag_pb`.
    ///   - ``CIDError/invalidMultihash(_:)`` if the string's bytes aren't exactly one well formed
    ///   Multihash.
    ///
    /// - Note: Delegates to `init(version:codec:multihash:)`'s byte collection overload.
    public init(version: CID.Version, codec: Codecs, multihash: some StringProtocol) throws(CIDError) {
        try self.init(version: version, codec: codec, multihash: multihash.utf8)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash compliant byte collection
    ///
    /// The presentation's multibase encoding is base58btc for a v0 and base32 for a v1.
    ///
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - multihash: The Multihash bytes (`<hash-algo><hash-length><digest>`), prefixes included,
    ///     and nothing else.
    /// - Throws:
    ///   - ``CIDError/invalidV0Codec`` if `version` is `.v0` and `codec` isn't `.dag_pb`.
    ///   - ``CIDError/invalidMultihash(_:)`` if `multihash` isn't exactly one well formed Multihash.
    public init(version: CID.Version, codec: Codecs, multihash: some Collection<UInt8>) throws(CIDError) {
        if version == .v0 && codec != .dag_pb { throw CIDError.invalidV0Codec }

        let mh: Multihash
        do { mh = try Multihash(multihash) } catch { throw CIDError.invalidMultihash(error) }
        try self.init(version: version, codec: codec, hash: mh, multibase: version == .v0 ? .base58btc : .base32)
    }

    /// Initialize a new CID by hashing raw `content` in a single step.
    ///
    /// This is a convenience over building a `Multihash` yourself, the `content` is hashed with the
    /// supplied `hashFunction` (e.g. `.sha2_256`) to produce the CID's multihash.
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - content: The raw bytes to hash.
    ///   - hashFunction: The multihash hash function to hash `content` with (e.g. `.sha2_256`).
    ///   - length: Keep only the leading `length` bytes of the digest. `nil` keeps the whole digest.
    /// - Throws:
    ///   - ``CIDError/invalidMultihash(_:)`` if `hashFunction` isn't a hash function this
    ///   package can compute. Use ``init(version:codec:hashing:with:truncatedTo:)`` to rule that
    ///   out at compile time.
    public init(
        version: CID.Version,
        codec: Codecs,
        content: some Collection<UInt8>,
        hashedWith hashFunction: Codecs,
        truncatedTo length: Int? = nil
    ) throws(CIDError) {
        let mh: Multihash
        do { mh = try Multihash(hashing: content, codec: hashFunction, truncatedTo: length) } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(version: version, codec: codec, multihash: mh)
    }

    /// Initialize a new CID by hashing raw `content` with a `HashFunction` in a single step.
    ///
    /// Unlike ``init(version:codec:content:hashedWith:truncatedTo:)`` this can't fail on an
    /// uncomputable hash function, because `HashFunction` only spells the ones this package
    /// supports.
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - content: The raw bytes to hash.
    ///   - function: The hash function to hash `content` with (e.g. `.sha2_256`).
    ///   - length: Keep only the leading `length` bytes of the digest. `nil` keeps the whole digest.
    public init(
        version: CID.Version,
        codec: Codecs,
        hashing content: some Collection<UInt8>,
        with function: HashFunction,
        truncatedTo length: Int? = nil
    ) throws(CIDError) {
        try self.init(
            version: version,
            codec: codec,
            multihash: Multihash(hashing: content, with: function, truncatedTo: length)
        )
    }

    /// Initialize a new CID by hashing the `content` String's encoded bytes in a single step.
    ///
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the content being addressed (e.g. `.dag_pb`).
    ///   - content: The string to hash.
    ///   - hashFunction: The hash function to hash `content` with (e.g. `.sha2_256`).
    ///   - encoding: The String encoding to use when converting the string to bytes (default UTF8).
    ///   - length: Keep only the leading `length` bytes of the digest. `nil` keeps the whole digest.
    /// - Throws:
    ///   - ``CIDError/invalidMultihash(_:)`` if `hashFunction` isn't a hash function this
    ///   package can compute.
    ///
    /// - Note: Delegates to `init(version:codec:content:hashedWith:truncatedTo:)`.
    public init(
        version: CID.Version,
        codec: Codecs,
        content: String,
        hashedWith hashFunction: Codecs,
        using encoding: String.Encoding = .utf8,
        truncatedTo length: Int? = nil
    ) throws(CIDError) {
        let mh: Multihash
        do {
            mh = try Multihash(
                hashing: content,
                codec: hashFunction,
                using: encoding,
                truncatedTo: length
            )
        } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(version: version, codec: codec, multihash: mh)
    }

    /// Initialize a copy of an existing CID, preserving its presentation `multibase`.
    ///
    /// - Note: This concrete overload is what keeps `CID(someCID)` meaning "copy" now that `CID` is
    ///   itself a `Collection<UInt8>` and would otherwise also match ``init(_:base:)``.
    public init(_ cid: CID) {
        try! self.init(version: cid.version, codec: cid.codec, hash: cid.multihash, multibase: cid.multibase)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash
    ///
    /// ```swift
    /// let cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)
    /// ```
    ///
    /// The presentation's multibase encoding is base58btc for a v0 and base32 for a v1.
    ///
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - multihash: The Multihash to address.
    /// - Throws:
    ///   - ``CIDError/invalidV0Codec`` if `version` is `.v0` and `codec` isn't `.dag_pb`.
    ///
    /// - Note: A v0's hash function isn't checked here, so an out of spec v0 can be built. Use
    ///   ``toV0()`` / ``convertedToV0()`` when the 32 byte sha2-256 constraint should be enforced.
    public init(version: CID.Version, codec: Codecs, multihash: Multihash) throws(CIDError) {
        try self.init(version: version, codec: codec, hash: multihash, multibase: version == .v0 ? .base58btc : .base32)
    }

    /// The single actual initializer, all other inits flow through here.
    init(version: CID.Version, codec: Codecs, hash: Multihash, multibase: BaseEncoding) throws(CIDError) {
        if version == .v0 && codec != .dag_pb { throw CIDError.invalidV0Codec }
        self.version = version
        self.codec = codec
        self.multibase = multibase
        self.multihash = hash

        // Both prefixes MUST be uVarInts so multi byte codec codes (eth-block == 0x90) round-trip.
        let versionPrefix = UInt64(version.rawValue).varIntBytes
        let codecPrefix = codec.asVarInt

        var v = [UInt8]()
        v.reserveCapacity(versionPrefix.count + codecPrefix.count + hash.count)
        v.append(contentsOf: versionPrefix)
        v.append(contentsOf: codecPrefix)
        v.append(contentsOf: hash.value)
        self.value = v

        // A CIDv0's canonical form is the bare multihash, so skip past the framing we just wrote.
        self.canonicalStart = version == .v0 ? versionPrefix.count + codecPrefix.count : 0
    }
}
