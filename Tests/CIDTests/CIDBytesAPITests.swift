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
import Testing

@testable import CID

@Suite("CID Bytes Based API")
struct CIDBytesBasedAPITests {

    static let trailer: [UInt8] = [0xde, 0xad, 0xbe, 0xef]

    // - MARK: Framed decoding

    /// A v1 CID embedded in a larger buffer decodes, and hands back the exact trailing slice.
    @Test func testDecodePrefixed_V1ReturnsTrailingSlice() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        let buffer = Array(cid) + Self.trailer

        let (decoded, remaining) = try CID.decode(prefixed: buffer)
        #expect(decoded == cid)
        #expect(decoded.version == .v1)
        #expect(Array(remaining) == Self.trailer)
        // The remainder is a slice of the input, positioned right after the CID
        #expect(remaining.startIndex == cid.canonicalBytes.count)
    }

    /// A bare v0 multihash embedded in a larger buffer decodes the same way.
    @Test func testDecodePrefixed_V0ReturnsTrailingSlice() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        let buffer = Array(cid) + Self.trailer

        let (decoded, remaining) = try CID.decode(prefixed: buffer)
        #expect(decoded == cid)
        #expect(decoded.version == .v0)
        #expect(Array(remaining) == Self.trailer)
    }

    /// `init(_:)` is the "exactly one CID and nothing else" spelling, so trailing bytes are rejected.
    @Test func testInitRejectsTrailingBytes() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(throws: CIDError.trailingBytes) {
            try CID(Array(cid) + Self.trailer)
        }
    }

    /// The `Collection<UInt8>.cid()` sugar matches `CID.decode(prefixed:)`.
    @Test func testByteCollectionCIDExtension() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        let buffer = Data(Array(cid) + Self.trailer)

        let (decoded, bytes) = try buffer.cid()
        #expect(decoded == cid)
        #expect(Array(bytes) == Self.trailer)
    }

    /// Two CIDs back to back read out one after the other, which is the point of `decode(prefixed:)`.
    @Test func testDecodePrefixed_ConsecutiveCIDs() throws {
        let first = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        let second = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")

        let (a, afterA) = try CID.decode(prefixed: Array(first) + Array(second))
        let (b, afterB) = try CID.decode(prefixed: afterA)

        #expect(a == first)
        #expect(b == second)
        #expect(afterB.isEmpty)
    }

    // - MARK: Canonical bytes / Collection conformance

    @Test(arguments: [
        "bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u",
        "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n",
    ])
    func testCanonicalBytesMatchCollectionConformance(_ string: String) throws {
        let cid = try CID(string)
        let expected = Array(cid.canonicalBytes)

        // Wrapping the CID itself yields the canonical bytes, which is what replaced the old
        // `rawBuffer` / `rawData` accessors.
        #expect(Array(cid) == expected)
        #expect(Data(cid) == Data(expected))
        #expect(cid.count == expected.count)
        #expect(cid.elementsEqual(expected))
        // ContiguousBytes sees the same bytes
        #expect(cid.withUnsafeBytes { Array($0) } == expected)
        // ...and so does the bulk-copy fast path `Array(cid)` / `Data(cid)` go through.
        #expect(cid.withContiguousStorageIfAvailable { Array($0) } == expected)
    }

    /// A v0's canonical bytes are a slice past the implicit version and codec, so like an
    /// `ArraySlice` its `startIndex` is not `0`.
    @Test func testV0StartIndexIsPastTheImplicitFraming() throws {
        let v0 = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        #expect(v0.startIndex == 2)  // <version 0x00> <dag-pb 0x70>
        #expect(v0.count == 34)
        #expect(v0[v0.startIndex] == 0x12)  // sha2-256
        #expect(v0.first == 0x12)

        let v1 = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(v1.startIndex == 0)
        #expect(v1.first == 0x01)
    }

    // - MARK: Generic initializers

    @Test func testInitFromArraySlice() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        let padded: [UInt8] = [0xff] + Array(cid)

        #expect(try CID(padded.dropFirst()) == cid)
    }

    @Test func testInitFromDataSubSequence() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        let padded = Data([0xff] + Array(cid))

        #expect(try CID(padded.dropFirst()) == cid)
    }

    /// A CID is itself a `Collection<UInt8>`, so it can seed a new one.
    @Test func testInitFromAnotherCIDsBytes() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(try CID(cid.canonicalBytes) == cid)
    }

    @Test func testInitFromSubstring() throws {
        let padded = "xbafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u"
        let cid = try CID(padded.dropFirst())

        #expect(cid.version == .v1)
        #expect(cid.toBaseEncodedString == "bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
    }

    /// The `HashFunction` content initializer can't fail on an uncomputable algorithm.
    @Test func testHashingInitMatchesCodecSpelling() throws {
        let expected = try CID(version: .v1, codec: .dag_pb, content: "hello world".utf8, hashedWith: .sha2_256)
        let cid = try CID(version: .v1, codec: .dag_pb, hashing: "hello world".utf8, with: .sha2_256)

        #expect(cid == expected)
        #expect(cid.toBaseEncodedString == expected.toBaseEncodedString)
    }

    @Test func testHashingInitTruncatesDigest() throws {
        let cid = try CID(
            version: .v1,
            codec: .dag_pb,
            hashing: "hello world".utf8,
            with: .sha2_256,
            truncatedTo: 16
        )
        #expect(cid.multihash.digestLength == 16)
    }

    // - MARK: Typed throws

    /// The initializers are `throws(CIDError)`, so a `catch` binds a `CIDError` with no cast.
    @Test func testTypedThrowsBindsCIDErrorDirectly() throws {
        do {
            _ = try CID("")
            Issue.record("expected an empty string to throw")
        } catch {
            // `error` is a CIDError here
            #expect(error == CIDError.invalidMultibase(.unknownBase))
        }
    }

    /// A well formed v1 frame carrying a code that isn't in the multicodec table surfaces the
    /// underlying `MulticodecError`.
    @Test func testUnknownCodecSurfacesMulticodecError() throws {
        let mh = try Multihash(hashing: "abc", codec: .sha2_256)
        try #require(Codecs(rawValue: 0x1F_FFFF) == nil)

        // v1, then 0x1FFFFF as a 3 byte uVarInt, then a valid multihash
        var bytes: [UInt8] = [0x01, 0xFF, 0xFF, 0x7F]
        bytes.append(contentsOf: mh.value)

        #expect(throws: CIDError.invalidMulticodec(.unknownCodecId)) {
            try CID(bytes)
        }
    }
}
