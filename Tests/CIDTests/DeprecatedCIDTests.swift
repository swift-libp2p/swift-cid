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
// Pins the pre-0.3.0 spellings kept in `Sources/CID/Deprecated.swift` so downstream packages keep
// compiling. The deprecation warnings this file emits are expected.
//

import Foundation
import Multibase
import Multicodec
import Multihash
import Testing

@testable import CID

@Suite("Deprecated CID Tests")
struct DeprecatedCIDTests {

    /// `CIDVersion` still names the (now nested) `CID.Version`.
    @Test func testCIDVersionTypealias() throws {
        let version: CIDVersion = .v1
        #expect(version == CID.Version.v1)
        #expect(CIDVersion(rawValue: 0) == .v0)
    }

    /// `.invalidBaseEncoding` still constructs, as `.invalidMultibase`.
    @Test func testInvalidBaseEncodingFactory() throws {
        #expect(CIDError.invalidBaseEncoding(.unknownBase) == .invalidMultibase(.unknownBase))
    }

    /// `customByteLength:` still means `truncatedTo:`.
    @Test func testCustomByteLengthLabel() throws {
        let expected = try CID(
            version: .v1,
            codec: .dag_pb,
            content: "hello world".utf8,
            hashedWith: .sha2_256,
            truncatedTo: 16
        )

        let fromBytes = try CID(
            version: .v1,
            codec: .dag_pb,
            content: Array("hello world".utf8),
            hashedWith: .sha2_256,
            customByteLength: 16
        )
        let fromString = try CID(
            version: .v1,
            codec: .dag_pb,
            content: "hello world",
            hashedWith: .sha2_256,
            customByteLength: 16
        )

        #expect(fromBytes == expected)
        #expect(fromString == expected)
        #expect(fromBytes.multihash.digestLength == 16)
    }

    /// The `[UInt8]` / `Data` initializers were subsumed by `some Collection<UInt8>` rather than
    /// shimmed, so these call sites keep working *without* a deprecation warning.
    @Test func testConcreteBufferTypesStillInitialize() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")

        let fromArray = try CID(Array(cid))
        let fromData = try CID(Data(cid))
        #expect(fromArray == cid)
        #expect(fromData == cid)

        let v0 = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        #expect(try CID(v0WithMultihash: Array(v0.multihash.value)) == v0)
        #expect(try CID(v0WithMultihash: Data(v0.multihash.value)) == v0)

        let mh = try Multihash(hashing: "abc", codec: .sha2_256)
        #expect(
            try CID(version: .v1, codec: .dag_cbor, multihash: Array(mh.value))
                == CID(version: .v1, codec: .dag_cbor, multihash: mh)
        )
    }

    /// `rawBuffer` / `rawData` still return the canonical bytes, and still agree with the
    /// `Collection` conformance that replaced them.
    @Test func testRawBufferAndRawData() throws {
        let v1 = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(v1.rawBuffer == Array(v1))
        #expect(v1.rawData == Data(v1))

        // A v0 exposes the bare 34 byte multihash, so the slice offset has to survive the copy.
        let v0 = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        #expect(v0.rawBuffer == Array(v0))
        #expect(v0.rawData == Data(v0))
        #expect(v0.rawBuffer.count == 34)
    }
}
