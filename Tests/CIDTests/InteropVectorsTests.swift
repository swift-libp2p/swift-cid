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
// Cross-implementation test vectors ported from the reference CID implementations and specs:
//   - Go:    github.com/ipfs/go-cid              (cid_test.go)
//   - Rust:  github.com/multiformats/rust-cid    (tests/lib.rs, src/cid.rs)
//   - JS:    github.com/multiformats/js-multiformats & js-cid
//   - Spec:  github.com/multiformats/cid README (human-readable CID example)
//   - libp2p: github.com/libp2p/specs peer-ids.md (libp2p-key CID example)
//

import Foundation
import Multibase
import Multicodec
import Multihash
import Testing

@testable import CID

@Suite("CID Interop Vectors")
struct CIDInteropVectorsTests {

    /// A parsed-CID fixture: the canonical string, its expected decomposition, and the full
    /// multihash (in base16, i.e. `<algo><len><digest>`).
    struct Vector: Sendable {
        let string: String
        let version: CID.Version
        let code: Int
        let base: BaseEncoding
        let multihashHex: String
        let origin: String
    }

    static let vectors: [Vector] = [
        // Spec README "human readable CID" example: base58btc / cidv1 / raw / sha2-256-256
        Vector(
            string: "zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA",
            version: .v1,
            code: 85,
            base: .base58btc,
            multihashHex: "12206e6ff7950a36187a801613426e858dce686cd7d7e3c0fc42ee0330072d245c95",
            origin: "multiformats/cid spec README"
        ),
        // go-cid canonical v1 Raw/sha2-256 base32 fixture
        Vector(
            string: "bafkreie5qrjvaw64n4tjm6hbnm7fnqvcssfed4whsjqxzslbd3jwhsk3mm",
            version: .v1,
            code: 85,
            base: .base32,
            multihashHex: "12209d8453505bdc6f269678e16b3e56c2a2948a41f2c792617cc9611ed363c95b63",
            origin: "ipfs/go-cid TestHexDecode / ExampleDecode"
        ),
        // rust-cid to_string / test_base32 fixture: Raw + sha2-256("foo")
        Vector(
            string: "bafkreibme22gw2h7y2h7tg2fhqotaqjucnbc24deqo72b6mkl2egezxhvy",
            version: .v1,
            code: 85,
            base: .base32,
            multihashHex: "12202c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
            origin: "multiformats/rust-cid test_base32"
        ),
        // go-cid TestReadCidsFromBuffer: base36 (k prefix) v1
        Vector(
            string: "k2cwueckqkibutvhkr4p2ln2pjcaxaakpd9db0e7j7ax1lxhhxy3ekpv",
            version: .v1,
            code: 85,
            base: .base36,
            multihashHex: "12209d8453505bdc6f269678e16b3e56c2a2948a41f2c792617cc9611ed363c95b63",
            origin: "ipfs/go-cid TestReadCidsFromBuffer"
        ),
        // go-cid TestReadCidsFromBuffer: base58btc (z prefix) v1
        Vector(
            string: "zb2rhZi1JR4eNc2jBGaRYJKYM8JEB4ovenym8L1CmFsRAytkz",
            version: .v1,
            code: 85,
            base: .base58btc,
            multihashHex: "12202d876a27fd2c513e92058338f19cf43c197e80a02fb02848e78fceeb00009af3",
            origin: "ipfs/go-cid TestReadCidsFromBuffer"
        ),
        // go-cid TestReadCidsFromBuffer: v0
        Vector(
            string: "Qmf5Qzp6nGBku7CEn2UQx4mgN8TW69YUok36DrGa6NN893",
            version: .v0,
            code: 112,
            base: .base58btc,
            multihashHex: "1220f8af76216f91afcda2f19fc249f7bf7bc808c3f7bcfb1980ebca8796a14bca46",
            origin: "ipfs/go-cid TestReadCidsFromBuffer"
        ),
        // libp2p peer-id encoded as a CID: v1 / libp2p-key (0x72) / base32
        Vector(
            string: "bafzbeie5745rpv2m6tjyuugywy4d5ewrqgqqhfnf445he3omzpjbx5xqxe",
            version: .v1,
            code: 114,
            base: .base32,
            multihashHex: "12209dff3b17d74cf4d38a50d8b6383e92d181a10395a5e73a726dcccbd21bf6f0b9",
            origin: "libp2p/specs peer-ids.md"
        ),
        // rust-cid test_into_v1 source (v0)
        Vector(
            string: "QmTPcW343HGMdoxarwvHHoPhkbo5GfNYjnZkyW5DBtpvLe",
            version: .v0,
            code: 112,
            base: .base58btc,
            multihashHex: "12204b0cae2ac1e55a20222619e98efadb91fd5534ab0adc6954d46c033a0c8a7aaf",
            origin: "multiformats/rust-cid test_into_v1"
        ),
    ]

    /// Every vector must parse with the expected version/codec/multibase/multihash and round-trip
    /// back to its canonical string.
    @Test func testParseAndDecomposeAllVectors() throws {
        for v in Self.vectors {
            let cid = try CID(v.string)
            #expect(cid.version == v.version, "\(v.origin): version")
            #expect(cid.code == v.code, "\(v.origin): codec code")
            #expect(cid.multibase == v.base, "\(v.origin): multibase")
            #expect(cid.multihash.asString(base: .base16) == v.multihashHex, "\(v.origin): multihash")
            // Round-trips back to the exact input string
            #expect(cid.toBaseEncodedString == v.string, "\(v.origin): round-trip")
        }
    }

    /// The single sha2-256("foo") + Raw CID rendered across every base the reference impls assert.
    /// (rust-cid `to_string`, `to_string_of_base32`, `to_string_of_base64`, `to_string_of_base58_v0`.)
    @Test func testRawFooRenderedAcrossBases() throws {
        let mh = try Multihash(hashing: "foo", codec: .sha2_256)
        let v1 = try CID(version: .v1, codec: try Codecs(name: "raw"), multihash: mh)

        #expect(v1.code == 85)
        #expect(v1.toBaseEncodedString == "bafkreibme22gw2h7y2h7tg2fhqotaqjucnbc24deqo72b6mkl2egezxhvy")
        #expect(try v1.string(base: .base32) == "bafkreibme22gw2h7y2h7tg2fhqotaqjucnbc24deqo72b6mkl2egezxhvy")
        #expect(try v1.string(base: .base64) == "mAVUSICwmtGto/8aP+ZtFPB0wQTQTQi1wZIO/oPmKXohiZueu")

        // The same digest as a CIDv0 (dag-pb) renders to a distinct base58btc string
        let v0 = try CID(version: .v0, codec: .dag_pb, multihash: mh)
        #expect(v0.toBaseEncodedString == "QmRJzsvyCQyizr73Gmms8ZRtvNxmgqumxc2KUp71dfEmoj")
    }

    /// js-multiformats reuses sha2-256("abc") heavily: v1 / dag-pb / base32.
    @Test func testAbcDagPbV1Base32() throws {
        let mh = try Multihash(hashing: "abc", codec: .sha2_256)
        let cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)
        #expect(cid.toBaseEncodedString == "bafybeif2pall7dybz7vecqka3zo24irdwabwdi4wc55jznaq75q7eaavvu")
    }

    /// rust-cid `test_into_v1`: a v0 CID upgraded to v1 renders to the expected base32 string, and
    /// the multihash is preserved across the conversion.
    @Test func testV0ToV1ConversionVector() throws {
        let v0 = try CID("QmTPcW343HGMdoxarwvHHoPhkbo5GfNYjnZkyW5DBtpvLe")
        let v1 = v0.convertedToV1()

        #expect(v1.version == .v1)
        #expect(v1.multihash == v0.multihash)
        #expect(try v1.string(base: .base32) == "bafybeiclbsxcvqpfliqcejqz5ghpvw4r7vktjkyk3ruvjvdmam5azct2v4")
    }

    /// Spec "human readable CID" decomposition of `zb2rhe5P4...`.
    /// base58btc - cidv1 - raw - sha2-256-256-6e6ff795...245c95
    @Test func testHumanReadableSpecExample() throws {
        let cid = try CID("zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA")
        #expect(cid.multibase == .base58btc)
        #expect(cid.version == .v1)
        #expect(cid.codec == .raw)
        #expect(cid.code == 85)
        #expect(
            cid.multihash.asString(base: .base16)
                == "12206e6ff7950a36187a801613426e858dce686cd7d7e3c0fc42ee0330072d245c95"
        )
    }

    // - MARK: Negative vectors

    /// js-multiformats "rejects non-minimally encoded varint prefix": the CIDv1 version `0x01`
    /// re-encoded as the non-minimal two-byte varint `0x81 0x00` must be rejected.
    @Test func testNonMinimalVarintVersionThrows() throws {
        let bytes = try BaseEncoding.decode(
            "81007012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5".utf8,
            as: .base16
        )
        #expect(throws: CIDError.self) {
            try CID(bytes)
        }
    }

    /// go-cid / rust-cid / js all reject the corrupted CIDv0 base58 string (contains `III`).
    @Test func testCorruptedV0StringThrows() throws {
        #expect(throws: CIDError.self) {
            try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII")
        }
    }

    // - MARK: Documented divergence

    /// KNOWN DIVERGENCE from rust-cid's `explicit_v0_is_disallowed`.
    ///
    /// rust-cid rejects a binary CID that begins with an explicit `0x00` version byte
    /// (`00 70 12 20 …`). This package instead *accepts* that framing and parses it as a CIDv0,
    /// because it uses the same `<version><codec><multihash>` framing internally for v0 (see
    /// `canonicalBytes`). This test pins the current, intentional behavior so the divergence is
    /// explicit;
    /// if we ever decide to match rust and reject explicit-v0, update this test deliberately.
    @Test func testExplicitV0BytesAreAcceptedAsV0() throws {
        let bytes = try BaseEncoding.decode(
            "00701220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad".utf8,
            as: .base16
        )
        let cid = try CID(bytes)
        #expect(cid.version == .v0)
        #expect(cid.codec == .dag_pb)
        // Canonical v0 bytes drop the explicit version/codec framing (34-byte multihash)
        #expect(cid.canonicalBytes.count == 34)
    }
}
