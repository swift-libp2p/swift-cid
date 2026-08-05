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

import Foundation
import Multibase
import Multicodec
import Multihash
import VarInt

public enum CIDVersion: Int, Sendable {
    case v0 = 0
    case v1 = 1
}

public enum CIDError: Error, Equatable {
    case cidStringTooShort
    case invalidCIDString
    case invalidVersion
    case invalidV0Codec
    case invalidV0Multihash
    case invalidV0Multibase
    case invalidMultihash(Error)
    case invalidBaseEncoding(Error)

    public static func == (lhs: CIDError, rhs: CIDError) -> Bool {
        switch (lhs, rhs) {
        case (.cidStringTooShort, .cidStringTooShort): return true
        case (.invalidCIDString, .invalidCIDString): return true
        case (.invalidVersion, .invalidVersion): return true
        case (.invalidV0Codec, .invalidV0Codec): return true
        case (.invalidV0Multihash, .invalidV0Multihash): return true
        case (.invalidV0Multibase, .invalidV0Multibase): return true
        case (.invalidMultihash(let l), .invalidMultihash(let r)):
            return l.localizedDescription == r.localizedDescription
        case (.invalidBaseEncoding(let l), .invalidBaseEncoding(let r)):
            return l.localizedDescription == r.localizedDescription
        default:
            return false
        }
    }
}

extension CIDError: CustomStringConvertible, LocalizedError {
    public var description: String {
        switch self {
        case .invalidMultihash(let e):
            return "Failed to instantiate Multihash: \(e)"
        case .cidStringTooShort:
            return "Raw CID String is too short"
        case .invalidCIDString:
            return "Unable to parse raw CID String"
        case .invalidVersion:
            return "Unable to parse raw CID String Version"
        case .invalidBaseEncoding(let e):
            return "Failed to decode Multibase: \(e)"
        case .invalidV0Codec:
            return "CID v0 only supports the 'dag-pb' codec (112 - 0x70)"
        case .invalidV0Multihash:
            return "CID v0 only supports 32 byte 'sha2_256' multihashes"
        case .invalidV0Multibase:
            return "CID v0 only supports base58btc encoding"
        }
    }

    /// Surfaces `description` through the standard `Error.localizedDescription` machinery.
    public var errorDescription: String? { self.description }
}

public struct CID: Equatable, Sendable {
    /// CID Value [version, codec, hash-algo, hash-length, hash-digest]
    private let value: [UInt8]

    /// Integer based Enum, currently supports v0 or v1
    public let version: CIDVersion
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

    /// Returns the CID in the base that it was initialized in...
    public var toBaseEncodedString: String {
        if self.version == .v0 {
            return self.multihash.asString(base: .base58btc)  //self.multibase)
        }
        return self.value.asString(base: self.multibase, withMultibasePrefix: true)
    }

    /// Returns the CID in the base specified...
    public func toBaseEncodedString(_ base: BaseEncoding) throws -> String {
        if self.version == .v0 {
            guard base == .base58btc else { throw CIDError.invalidV0Multibase }
            return self.multihash.asString(base: .base58btc)
        }
        return self.value.asString(base: base, withMultibasePrefix: true)
    }

    /// Returns the canonical, multibase-prefixed CID string encoded in the requested `base`.
    ///
    /// This is the public, spec-compliant way to render a CID in an arbitrary base. For a CIDv0
    /// only `.base58btc` is permitted (any other base throws `CIDError.invalidV0Multibase`).
    public func string(base: BaseEncoding) throws -> String {
        try self.toBaseEncodedString(base)
    }

    /// Returns the entirety of the CID as a UInt8 Array / Buffer (Prefixs and Multihash Digest)
    ///
    /// - Note: For a CIDv0 this is the bare 34 byte multihash (`<hash-algo><hash-length><digest>`)
    ///   as mandated by the CID spec — the version and codec are implicit and are **not** encoded.
    public var rawBuffer: [UInt8] {
        self.version == .v0 ? Array(self.multihash.value) : self.value
    }

    /// Returns the entirety of the CID as Data (Prefixs and Multihash Digest)
    ///
    /// - Note: For a CIDv0 this is the bare 34 byte multihash (see `rawBuffer`).
    public var rawData: Data {
        Data(self.rawBuffer)
    }

    /// Returns the CIDs Prefix (includes everything but the multihash digest)
    ///
    /// The CID prefix includes the following...
    /// - [version] [codec] [hash-algo] [hash-length]
    public var prefix: [UInt8] {
        guard let digestLength = self.multihash.length else { return [] }
        return Array(self.value.dropLast(digestLength))
    }

    /// Returns the entirety of the CID (prefixs and Multihash digest) as a base encoded string without the Multibase prefix
    /// - Warning: Use CID.toBaseEncodedString to ensure you receive a proper CID compliant string. This method should only be used for debugging purposes...
    func asString(base: BaseEncoding) throws -> String {
        if base != .base58btc && self.version == .v0 { throw CIDError.invalidV0Multibase }
        return self.value.asString(base: base)
    }

    /// Returns the entirety of the CID (prefixs and Multihash digest) as a base encoded string with the Multibase prefix
    /// - Warning: Use CID.toBaseEncodedString to ensure you receive a proper CID compliant string. This method should only be used for debugging purposes...
    func asMultibase(_ base: BaseEncoding) throws -> String {
        if base != .base58btc && self.version == .v0 { throw CIDError.invalidV0Multibase }
        return self.value.asString(base: base, withMultibasePrefix: true)
    }

    /// Initialize a CID from a CID compliant String
    public init(_ cid: String) throws {

        if let d = try? BaseEncoding.decode(cid) {
            // After base decoding, CID data consists of...
            // <Version 1 byte> <Codec> <Multihash>
            //
            // Spec guard: a multibase-encoded CID may not decode to a leading `0x12` byte. CIDv0
            // multihashes (sha2-256, `0x12`) are never multibase-encoded, and there is no CIDv18
            // (`0x12` = 18), so an explicit multibase prefix followed by `0x12` is ambiguous.
            // Bare base58btc "Qm..." v0 CIDs carry no explicit prefix and remain valid.
            if !cid.hasPrefix("Qm"), d.data.first == 0x12 {
                throw CIDError.invalidCIDString
            }
            try self.init(d.data, base: d.base)
        } else {
            //Base Decoding Failed... Assuming CID String is a V0 base58btc string...
            let decoded: (base: BaseEncoding, data: Data)
            do { decoded = try BaseEncoding.decode(BaseEncoding.base58btc.charPrefix + cid) } catch {
                throw CIDError.invalidBaseEncoding(error)
            }
            try self.init(v0WithMultihash: decoded.data)
        }
    }

    /// Initialize a CID from CID compliant Data
    public init(_ cid: Data, base: BaseEncoding? = nil) throws {
        try self.init(Array(cid), base: base)
    }

    /// Initialize a CID from a CID compliant UInt8 Array
    public init(_ cid: [UInt8], base: BaseEncoding? = nil) throws {
        if let mh = try? Multihash(cid), mh.algorithm == .sha2_256, mh.length == 32 {
            //We have a non base encoded version 0 CID...
            try self.init(v0WithMultihash: mh)
        } else {  //We have a version 1+ CID, lets attempt deconstruct it... <Version 1 byte> <Codec> <Multihash>
            guard let v = cid.first else { throw CIDError.cidStringTooShort }
            guard let ver = CIDVersion(rawValue: Int(v)) else { throw CIDError.invalidVersion }

            let multicodec = try Array(cid[1...]).extractCodec()

            //Init Multihash...
            let hash: Multihash
            do { hash = try Multihash(multicodec.bytes) } catch {
                throw CIDError.invalidMultihash(error)
            }

            try self.init(
                version: ver,
                codec: multicodec.codec,
                hash: hash,
                multibase: base ?? (ver == .v0 ? .base58btc : .base32)
            )
        }
    }

    /// Initialize a new Version 0 CID with a Multihash compliant UInt8 Array
    /// - Note: This delegates the initialization to
    /// ```
    /// CID.init(v0WithMultihash multihash:Multihash)
    /// ```
    public init(v0WithMultihash multihash: [UInt8]) throws {
        try self.init(v0WithMultihash: Data(multihash))
    }

    /// Initialize a new Version 0 CID with a Multihash compliant Data object
    /// - Note: This delegates the initialization to
    /// ```
    /// CID.init(v0WithMultihash multihash:Multihash)
    /// ```
    public init(v0WithMultihash multihash: Data) throws {
        let mh: Multihash
        do { mh = try Multihash(multihash: multihash) } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(v0WithMultihash: mh)
    }

    /// Initialize a new Version 0 CID with a Multihash
    public init(v0WithMultihash multihash: Multihash) throws {
        try self.init(version: .v0, codec: .dag_pb, hash: multihash, multibase: .base58btc)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash compliant String
    /// - Note: This delegates the initialization to
    /// ```
    /// CID.init(version:CIDVersion, codec:Codecs, hash:String)
    /// ```
    public init(version: CIDVersion, codec: Codecs, hash: String) throws {
        try self.init(version: version, codec: codec, hash: Array(hash.utf8))
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and Multihash compliant Data
    /// - Note: This delegates the initialization to
    /// ```
    /// CID.init(version:CIDVersion, codec:Codecs, hash:[UInt8])
    /// ```
    public init(version: CIDVersion, codec: Codecs, hash: Data) throws {
        try self.init(version: version, codec: codec, hash: Array(hash))
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash compliant UInt8 Array
    public init(version: CIDVersion, codec: Codecs, hash: [UInt8]) throws {
        if version == .v0 && codec != .dag_pb { throw CIDError.invalidV0Codec }

        let mh: Multihash
        do { mh = try Multihash(hash) } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(version: version, codec: codec, hash: mh, multibase: version == .v0 ? .base58btc : .base32)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash
    public init(version: CIDVersion, codec: Codecs, multihash: Multihash) throws {
        try self.init(version: version, codec: codec, hash: multihash, multibase: version == .v0 ? .base58btc : .base32)
    }

    /// Initialize a new CID by hashing raw `content` in a single step.
    ///
    /// This is a convenience over building a `Multihash` yourself: the `content` is hashed with the
    /// supplied `hashFunction` (e.g. `.sha2_256`) to produce the CID's multihash.
    /// - Parameters:
    ///   - version: The CID version to create.
    ///   - codec: The content-type codec of the data being addressed (e.g. `.dag_pb`).
    ///   - content: The raw bytes to hash.
    ///   - hashFunction: The multihash hash function to hash `content` with (e.g. `.sha2_256`).
    ///   - customByteLength: An optional truncated digest length, forwarded to `Multihash`.
    public init(
        version: CIDVersion,
        codec: Codecs,
        content: [UInt8],
        hashedWith hashFunction: Codecs,
        customByteLength: Int? = nil
    ) throws {
        let mh: Multihash
        do {
            mh = try Multihash(raw: content, hashedWith: hashFunction, customByteLength: customByteLength)
        } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(version: version, codec: codec, multihash: mh)
    }

    /// Initialize a new CID by hashing raw `content` Data in a single step.
    /// - Note: Delegates to `init(version:codec:content:hashedWith:customByteLength:)`.
    public init(
        version: CIDVersion,
        codec: Codecs,
        content: Data,
        hashedWith hashFunction: Codecs,
        customByteLength: Int? = nil
    ) throws {
        try self.init(
            version: version,
            codec: codec,
            content: Array(content),
            hashedWith: hashFunction,
            customByteLength: customByteLength
        )
    }

    /// Initialize a new CID by hashing the `content` String's encoded bytes in a single step.
    /// - Note: Delegates to `init(version:codec:content:hashedWith:customByteLength:)`.
    public init(
        version: CIDVersion,
        codec: Codecs,
        content: String,
        hashedWith hashFunction: Codecs,
        using encoding: String.Encoding = .utf8,
        customByteLength: Int? = nil
    ) throws {
        let mh: Multihash
        do {
            mh = try Multihash(
                raw: content,
                hashedWith: hashFunction,
                using: encoding,
                customByteLength: customByteLength
            )
        } catch {
            throw CIDError.invalidMultihash(error)
        }
        try self.init(version: version, codec: codec, multihash: mh)
    }

    public init(_ cid: CID) {
        try! self.init(version: cid.version, codec: cid.codec, hash: cid.multihash, multibase: cid.multibase)
    }

    /// Initialize a new CID by specifiying the CID Version, Codec and a Multihash compliant String
    private init(version: CIDVersion, codec: Codecs, hash: Multihash, multibase: BaseEncoding) throws {
        if version == .v0 && codec != .dag_pb { throw CIDError.invalidV0Codec }
        self.version = version
        self.codec = codec
        self.multibase = multibase
        self.multihash = hash

        var v: [UInt8] = putUVarInt(UInt64(self.version.rawValue))
        v.append(contentsOf: putUVarInt(self.codec.code))
        v.append(contentsOf: self.multihash.value)
        self.value = v
    }
}

/// Equatable
///
/// - Note: Two CIDs are equal when their canonical bytes (`rawBuffer` — version, codec and
///   multihash) match. The `multibase` used for string presentation is intentionally **not**
///   part of equality, so the same CID rendered in different bases compares equal.
public func == (lhs: CID, rhs: CID) -> Bool {
    lhs.rawBuffer == rhs.rawBuffer
}

/// Hashable
///
/// Hashes the same canonical bytes that `==` compares, so equal CIDs always share a hash value
/// (safe for use as `Set` members / `Dictionary` keys).
extension CID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawBuffer)
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
         - Base: \(self.multibase) (\(self.multibase.bytePrefix), \(self.multibase.charPrefix))
         - Codec: \(self.codec.name) (\(self.code))
         - Hash: \(self.multihash)
        """
    }
}

/// Utilities
extension CID {
    /// Converts this CID to v1 in place. The multihash is preserved across versions.
    ///
    /// - Note: The existing `multibase` is preserved. A CIDv0 (always base58btc) therefore becomes a
    ///   v1 that still renders in base58btc rather than the conventional v1 default of base32; call
    ///   `string(base: .base32)` (or re-create with a base32 multibase) if you need the base32 form.
    public mutating func toV1() {
        if self.version == .v1 { return }
        self = try! CID(version: .v1, codec: self.codec, hash: self.multihash, multibase: self.multibase)
    }

    public mutating func toV0() throws {
        if self.version == .v0 { return }
        //V0 CID's must use .dag-pb codec and base58btc encoding and multihashed with sha2_256...
        guard self.codec == .dag_pb else { throw CIDError.invalidV0Codec }
        guard self.multihash.algorithm == .sha2_256, self.multihash.length == 32 else {
            throw CIDError.invalidV0Multihash
        }
        self = try CID(version: .v0, codec: self.codec, hash: self.multihash, multibase: .base58btc)
    }

    /// Returns a copy of this CID converted to v1, leaving the receiver unchanged.
    /// - SeeAlso: The mutating `toV1()` for the base-preservation behavior.
    public func convertedToV1() -> CID {
        var copy = self
        copy.toV1()
        return copy
    }

    /// Returns a copy of this CID converted to v0, leaving the receiver unchanged.
    /// - Throws: `CIDError.invalidV0Codec` / `.invalidV0Multihash` if the CID can't be represented as v0.
    public func convertedToV0() throws -> CID {
        var copy = self
        try copy.toV0()
        return copy
    }
}
