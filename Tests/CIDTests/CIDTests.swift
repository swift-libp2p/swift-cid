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
import Testing

@testable import CID

@Suite("CID Tests")
struct CIDTests {
    @Test func testVersion0_B58_String() throws {
        let mhStr = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid = try CID(mhStr)

        #expect(cid.codec == .dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(try cid.multihash == Multihash(b58String: "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"))
        #expect(cid.multihash.asString(base: .base58btc) == mhStr)
        #expect(cid.multibase == .base58btc)

        #expect(cid.toBaseEncodedString == mhStr)
    }

    @Test func testVersion0_UInt8Array() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let mhStr = "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4"
        let cid = try CID(mh.value)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multihash.asString(base: .base58btc) == mhStr)
        #expect(cid.multibase == .base58btc)

        #expect(cid.toBaseEncodedString == mhStr)
        //print(cid.rawBuffer.map { "\($0)" }.joined(separator: " "))
    }

    @Test func testVersion0_CreateByParts() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: .dag_pb, multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
    }

    @Test func testVersion0_CreateByPartsIntCodec() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: try Codecs(112), multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
    }

    @Test func testVersion0_CreateByV0Multihash() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
    }

    @Test func testVersion0_InvalidB58String() throws {
        // Invalid B58 String
        #expect(throws: CIDError.self) {
            try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII")
        }
    }

    @Test func testVersion0_NonDAG_PB_Version0() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        #expect(throws: CIDError.invalidV0Codec) {
            try CID(version: .v0, codec: .dag_cbor, multihash: mh)
        }
    }

    /// - TODO: We dont support specifiying the base...
    //it('throws on trying to create a CIDv0 with a base other than base58btc', () => {
    //  expect(
    //    () => new CID(0, 'dag-pb', hash, 'base32')
    //  ).to.throw("multibaseName must be 'base58btc' for CIDv0")
    //})

    @Test func testVersion0_PreventNonB58Encodings() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multibase == .base58btc)

        #expect(throws: CIDError.invalidV0Multibase) {
            try cid.toBaseEncodedString(.base16)
        }
    }

    @Test func testVersion0_Prefix() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)

        #expect(cid.prefix.toHexString() == "00701220")
        #expect(cid.prefix.asString(base: .base16) == "00701220")
    }

    /// - TODO: CID.Bytes should return Multihash value???
    @Test func testVersion0_RawBytes() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)

        #expect(
            cid.multihash.asString(base: .base16)
                == "1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    /// - TODO: Support Instantiating CIDs from CIDs...
    //it('should construct from an old CID without a multibaseName', () => {
    //  const cidStr = 'QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n'

    //  const oldCid = new CID(cidStr)
    //  delete oldCid.multibaseName // Fake it

    //  const newCid = new CID(oldCid)

    //  expect(newCid.multibaseName).to.equal('base58btc')
    //  expect(newCid.toString()).to.equal(cidStr)
    //})

    @Test func testVersion1_MultibaseEncodedString() throws {
        let cidString = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        let cid = try CID(cidString)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multibase == .base58btc)

        #expect(cid.toBaseEncodedString == cidString)
    }

    @Test func testVersion1_NonMultibaseEncodedString() throws {
        let cidString = "bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u"
        let cidBuf = try Data(
            decoding: "017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5",
            as: .base16
        )

        let cid = try CID(Array(cidBuf))

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multibase == .base32)

        #expect(cid.toBaseEncodedString == cidString)
    }

    @Test func testVersion1_PeerIdString() throws {
        let peerIdStr = "k51qzi5uqu5dj16qyiq0tajolkojyl9qdkr254920wxv7ghtuwcz593tp69z9m"

        let cid = try CID(peerIdStr)

        #expect(cid.codec == .libp2p_key)
        #expect(cid.code == 114)
        #expect(cid.version == .v1)
        #expect(cid.multibase == .base36)

        #expect(cid.toBaseEncodedString == peerIdStr)
    }

    @Test func testVersion1_CreateByParts() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

        #expect(cid.codec == .dag_cbor)
        #expect(cid.code == 113)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base32)

        #expect(cid.toBaseEncodedString == "bafyreif2pall7dybz7vecqka3zo24irdwabwdi4wc55jznaq75q7eaavvu")
    }

    @Test func testVersion1_RoundTrip() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)

        #expect(cid1.codec == .dag_cbor)
        #expect(cid1.code == 113)
        #expect(cid1.version == .v1)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base32)

        #expect(cid1.codec == cid2.codec)
        #expect(cid1.code == cid2.code)
        #expect(cid1.version == cid2.version)
        #expect(cid1.multihash == cid2.multihash)
        #expect(cid1.multibase == cid2.multibase)
    }

    @Test func testVersion1_MultiByteCodecCodes() throws {
        let ethBlockHash = try Data(
            decoding: "8a8e84c797605fbe75d5b5af107d4220a2db0ad35fd66d9be3d38d87c472b26d",
            as: .base16
        )
        let mh = try Multihash(raw: ethBlockHash, hashedWith: .keccak_256)
        let cid1 = try CID(version: .v1, codec: .eth_block, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)

        #expect(cid1.codec == .eth_block)
        #expect(cid1.code == 144)
        #expect(cid1.version == .v1)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base32)

        #expect(cid1.codec == cid2.codec)
        #expect(cid1.code == cid2.code)
        #expect(cid1.version == cid2.version)
        #expect(cid1.multihash == cid2.multihash)
        #expect(cid1.multibase == cid2.multibase)
    }

    @Test func testVersion1_MultiByteCodecCodes2() throws {
        let p2pHash = try Data(
            decoding: "8a8e84c797605fbe75d5b5af107d4220a2db0ad35fd66d9be3d38d87c472b26d",
            as: .base16
        )
        let mh = try Multihash(raw: p2pHash, hashedWith: .keccak_256)
        let cid1 = try CID(version: .v1, codec: .p2p, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)
        let cid3 = try CID(version: .v1, codec: .ipfs, multihash: mh)

        #expect(cid1.codec == .p2p)
        #expect(cid1.code == 0x01a5)
        #expect(cid1.version == .v1)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base32)

        #expect(cid1.codec == cid2.codec)
        #expect(cid1.code == cid2.code)
        #expect(cid1.version == cid2.version)
        #expect(cid1.multihash == cid2.multihash)
        #expect(cid1.multibase == cid2.multibase)

        /// P2P =/= IPFS Interop (Name is different, code is different)
        #expect(cid1.codec != cid3.codec)  // .ipfs  != .p2p
        #expect(cid1.code != cid3.code)  // 0x01a5 == 0x01a5
        #expect(cid1.version == cid3.version)
        #expect(cid1.multihash == cid3.multihash)
        #expect(cid1.multibase == cid3.multibase)
    }

    @Test func testVersion1_Prefix() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

        #expect(cid1.codec == .dag_cbor)
        #expect(cid1.code == 113)
        #expect(cid1.version == .v1)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base32)

        //print(cid1.rawBuffer.map { "\($0)" }.joined(separator: " "))
        //print(cid1.rawBuffer.toHexString())
        #expect(cid1.prefix.asString(base: .base16) == "01711220")
    }

    @Test func testVersion1_Identity() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .identity)

        let cid1 = try CID(version: .v0, codec: .dag_pb, multihash: mh)
        #expect(cid1.codec == .dag_pb)
        #expect(cid1.code == 112)
        #expect(cid1.version == .v0)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base58btc)
        #expect(cid1.multihash.b58String == "161g3c")

        let cid2 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        #expect(cid2.codec == .dag_cbor)
        #expect(cid2.code == 113)
        #expect(cid2.version == .v1)
        #expect(cid2.multihash == mh)
        #expect(cid2.multibase == .base32)
        #expect(cid2.toBaseEncodedString == "bafyqaa3bmjrq")
    }

    /// - TODO: CID.Bytes should return Multihash value???
    //it('.bytes', () => {
    //  const codec = 'dag-cbor' // Invalid codec will cause an error: Issue #46
    //  const cid = new CID(1, codec, hash)
    //  const bytes = cid.bytes
    //  expect(bytes).to.exist()
    //  const str = uint8ArrayToString(bytes, 'base16')
    //  expect(str).to.equals('01711220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
    //})
    @Test func testVersion1_RawBytes() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)

        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

        #expect(cid1.codec == .dag_cbor)
        #expect(cid1.code == 113)
        #expect(cid1.version == .v1)
        #expect(cid1.multihash == mh)
        #expect(cid1.multibase == .base32)
        #expect(
            cid1.rawBuffer.toHexString() == "01711220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
        #expect(
            cid1.rawBuffer.asString(base: .base16)
                == "01711220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test func testVersion1_UnknownCodec() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        // TODO: Make MulticodecError public and specialize this
        #expect(throws: Error.self) {
            try CID(version: .v1, codec: try Codecs(10000), multihash: mh)
        }
    }

    @Test func testVersion1_UnknownCodec2() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        // TODO: Make MulticodecError public and specialize this
        #expect(throws: Error.self) {
            try CID(version: .v1, codec: try Codecs("this-codec-does-not-exist"), multihash: mh)
        }
    }

    @Test func testToString_CIDString() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)

        let cid = try CID(mh.value)

        #expect(cid.toBaseEncodedString == "QmatYkNGZnELf8cAGdyJpUca2PyY4szai3RHyyWofNY1pY")
    }

    @Test func testToString_SameBase_Base64() throws {
        let base64Str = "mAXASIOnrbGCADfkPyOI37VMkbzluh1eaukBqqnl2oFaFnuIt"
        let cid = try CID(base64Str)
        #expect(cid.toBaseEncodedString == "mAXASIOnrbGCADfkPyOI37VMkbzluh1eaukBqqnl2oFaFnuIt")
    }

    @Test func testToString_SameBase_Base16() throws {
        let base16Str = "f01701220e9eb6c60800df90fc8e237ed53246f396e87579aba406aaa7976a056859ee22d"
        let cid = try CID(base16Str)
        #expect(
            cid.toBaseEncodedString == "f01701220e9eb6c60800df90fc8e237ed53246f396e87579aba406aaa7976a056859ee22d"
        )
    }

    @Test func testToString_SpecificBaseOutput() throws {
        let base58Str = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        let base64URLStr = "uAXASIHJSUj5lkfuP5VPWf_VahvhARLRqPkF24QxY-lKaSqvV"
        let cid = try CID(base58Str)
        #expect(cid.toBaseEncodedString == base58Str)
        #expect(cid.rawBuffer.asString(base: .base64Url, withMultibasePrefix: true) == base64URLStr)
    }

    /// - MARK: Utilities
    @Test func testUtilities_Equality() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let h2 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1o"

        let cid1 = try CID(h1)
        let cid2 = try CID(h2)

        #expect(cid1 == cid1)
        #expect(cid2 == cid2)
        #expect(cid1 != cid2)
    }

    @Test func testUtilities_EqualityVersionShift() throws {
        let h1 = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"

        let cidV1 = try CID(h1)
        var cidV0 = cidV1
        try cidV0.toV0()

        #expect(cidV0 != cidV1)
        #expect(cidV1 != cidV0)

        #expect(cidV0.multihash == cidV1.multihash)
    }

    @Test func testUtilities_EqualityStringVsBuffer() throws {
        let cidStr = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"

        let cid = try CID(cidStr)
        let cidA = try CID(version: cid.version, codec: cid.codec, hash: cid.multihash.value)
        let cidB = try CID(cidStr)

        #expect(cidA == cidB)
    }

    /// - MARK: Invalid Inputs
    @Test func testInvalidInputs() throws {
        let invalidInputs = [
            "",
            "\n",
            "😀",
            "hello world",
            "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L",
            "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT",
            "uAXASIHJSUj5lkfuP5VPWf_VahvhARLRqPkF24QxY-lKaSqvV24",
        ]
        for i in invalidInputs {
            //As string
            #expect(throws: CIDError.self) { try CID(i) }

            //As Data
            #expect(throws: CIDError.self) { try CID(Data(i.utf8)) }

            //As UInt8 Array
            #expect(throws: CIDError.self) { try CID(Array(i.utf8)) }

            //As string with invalid codec and v0...
            #expect(throws: CIDError.self) { try CID(version: .v0, codec: .dag_pb, hash: i) }

            //As string with invalid codec and v1...
            #expect(throws: CIDError.self) { try CID(version: .v1, codec: .dag_pb, hash: i) }
        }
    }

    @Test func testInvalidVersions() {
        /// Enforce Supported Versions only...
        for i in (-2...3) {
            let ver = CIDVersion(rawValue: i)
            switch i {
            case 0, 1:
                #expect(ver != nil)
            default:
                #expect(ver == nil)
            }
        }
    }

    /// - MARK: Version Shifting...
    @Test func testVersionShifting_V0ToV1() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v0, codec: .dag_pb, multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)

        cid.toV1()
        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
    }

    @Test func testVersionShifting_V1ToV0() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base32)

        try cid.toV0()
        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
    }

    @Test func testVersionShifting_V1ToV0ThrowsIfWrongCodec() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

        #expect(cid.codec == Codecs.dag_cbor)
        #expect(cid.code == 113)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base32)

        #expect(throws: CIDError.invalidV0Codec) {
            try cid.toV0()
        }
    }

    @Test func testVersionShifting_V1ToV0ThrowsIfWrongHashAlgo() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_512)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base32)

        #expect(throws: CIDError.invalidV0Multihash) {
            try cid.toV0()
        }
    }

    @Test func testVersionShifting_V1ToV0ThrowsIfWrongHashLength() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256, customByteLength: 31)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base32)

        #expect(throws: CIDError.invalidV0Multihash) {
            try cid.toV0()
        }
    }

    /// CIDs are structs so they should adopt Copy on Write behavior
    @Test func testIdempotence() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid1 = try CID(h1)
        var cid2 = CID(cid1)

        #expect(cid1 == cid2)
        // Shares the same pointer until we modify the struct
        let cid1Pointer = withUnsafePointer(to: cid1) { "\($0)" }
        let cid2Pointer = withUnsafePointer(to: cid2) { "\($0)" }
        #if DEBUG
        // Copy on Write is disabled in DEBUG mode
        #expect(cid1Pointer != cid2Pointer)
        #endif

        #if Release
        // They share the same pointer until we modify one
        #expect(cid1Pointer == cid2Pointer)

        // Copy on Write
        cid2.toV1()
        let cid2PointerCoW = withUnsafePointer(to: cid2) { "\($0)" }
        #expect(cid1Pointer != cid2PointerCoW)
        #endif
    }

    /// CIDs are structs so they should adopt Copy on Write behavior
    @Test func testIdempotence2() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid1 = try CID(h1)
        var cid2 = cid1

        #expect(cid1 == cid2)
        let cid1Pointer = withUnsafePointer(to: cid1) { "\($0)" }
        let cid2Pointer = withUnsafePointer(to: cid2) { "\($0)" }
        #if DEBUG
        // Copy on Write is disabled in DEBUG mode
        #expect(cid1Pointer != cid2Pointer)
        #endif

        #if Release
        // They share the same pointer until we modify one
        #expect(cid1Pointer == cid2Pointer)

        // Copy on Write
        cid2.toV1()
        let cid2PointerCoW = withUnsafePointer(to: cid2) { "\($0)" }
        #expect(cid1Pointer != cid2PointerCoW)
        #endif
    }

    @Test func testExampleTwo() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let str = "z1CBaeXvdXThAxmycy1Ezp73CEFDiJ54MoSSjXodtViWzEyEAU"
        let cid = try CID(str)
        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == mh)
        #expect(cid.multibase == .base58btc)
        #expect(try cid.asMultibase(.base58btc) == str)
    }

    @Test func testExample2() throws {
        let str = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        let cid = try CID(str)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multibase == .base58btc)
        #expect(cid.toBaseEncodedString == str)
    }

    @Test func testExample3() throws {
        let str = "bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u"
        let cid = try CID(str)
        //let cidBuf = uint8ArrayFromString('017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5', 'base16')
        //let buf = try BaseEncoding.decode("017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5", as: .base16)
        let buf = try [UInt8](
            decoding: "017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5",
            as: .base16
        )

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v1)
        #expect(cid.multibase == .base32)
        #expect(cid.rawBuffer == buf)
        #expect(cid.toBaseEncodedString == str)
    }

    @Test func testExample4() throws {
        let str = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid = try CID(str)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash.asString(base: .base58btc) == str)
        #expect(cid.multibase == .base58btc)
        #expect(cid.toBaseEncodedString == str)
    }

    /// const cid = new CID(0, 'dag-pb', hash)

    /// expect(cid).to.have.property('codec', 'dag-pb')
    /// expect(cid).to.have.property('code', 112)
    /// expect(cid).to.have.property('version', 0)
    /// expect(cid).to.have.property('multihash')
    /// expect(cid).to.have.property('multibaseName', 'base58btc')
    @Test func testExample5() throws {
        let multi = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: .dag_pb, multihash: multi)

        #expect(cid.codec == Codecs.dag_pb)
        #expect(cid.code == 112)
        #expect(cid.version == .v0)
        #expect(cid.multihash == multi)
        #expect(cid.multibase == .base58btc)
        #expect(cid.toBaseEncodedString == "QmatYkNGZnELf8cAGdyJpUca2PyY4szai3RHyyWofNY1pY")
    }

    @Test func testThrowsInvalidMultihash() throws {
        #expect(throws: CIDError.self) {
            try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII")
        }
    }

    /// - MARK: Raw Bytes (Spec compliance & interop)

    /// A CIDv0's binary form is the bare 34 byte multihash (`<hash-algo><hash-length><digest>`);
    /// the version and codec are implicit and must NOT be encoded into the raw bytes.
    @Test func testVersion0_RawBufferIsCanonical34ByteMultihash() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")

        #expect(cid.version == .v0)
        #expect(cid.rawBuffer == Array(cid.multihash.value))
        #expect(cid.rawData == Data(cid.multihash.value))
        #expect(cid.rawBuffer.count == 34)
        // Canonical CIDv0 multihash begins with sha2-256 (0x12) and length 32 (0x20)
        #expect(Array(cid.rawBuffer.prefix(2)) == [0x12, 0x20])
    }

    /// - MARK: Re-basing (toBaseEncodedString(_:))

    /// A v1 CID must honor the base requested via toBaseEncodedString(_:), not its original multibase.
    @Test func testVersion1_ToBaseEncodedStringHonorsRequestedBase() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(cid.multibase == .base32)

        let base16 = try cid.toBaseEncodedString(.base16)
        #expect(
            base16 == "f017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5"
        )
        // Re-basing actually changed the output (regression guard for the ignored-argument bug)
        #expect(base16 != cid.toBaseEncodedString)

        // Round trips back to the same CID regardless of the transport base
        #expect(try CID(base16) == cid)
    }

    /// - MARK: Prefix

    /// `prefix` must not crash for a small / identity multihash.
    @Test func testPrefix_IdentityMultihashDoesNotCrash() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .identity)
        let cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

        // version (0x01) + codec dag-cbor (0x71) + multihash prefix (identity 0x00, length 0x03)
        #expect(cid.prefix.asString(base: .base16) == "01710003")
    }

    /// - MARK: Binary Round Trips

    @Test func testRoundTrip_V0Binary() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        let rt = try CID(cid.rawData)

        #expect(rt.version == .v0)
        #expect(rt == cid)
        #expect(rt.rawData == cid.rawData)
    }

    @Test func testRoundTrip_V1SingleByteCodec() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        let rt = try CID(cid.rawData)

        #expect(rt.version == .v1)
        #expect(rt.codec == .dag_cbor)
        #expect(rt == cid)
    }

    @Test func testRoundTrip_V1MultiByteCodec() throws {
        let ethHash = try Data(
            decoding: "8a8e84c797605fbe75d5b5af107d4220a2db0ad35fd66d9be3d38d87c472b26d",
            as: .base16
        )
        let mh = try Multihash(raw: ethHash, hashedWith: .keccak_256)
        let cid = try CID(version: .v1, codec: .eth_block, multihash: mh)
        let rt = try CID(cid.rawData)

        #expect(rt.version == .v1)
        #expect(rt.codec == .eth_block)
        #expect(rt == cid)
    }

    /// - MARK: Spec / Negative cases

    /// A raw sha2-256 multihash that is explicitly multibase-encoded (here base16, 'f' prefix)
    /// must be rejected: CIDv0 multihashes may not be multibase-encoded (there is no CIDv18).
    @Test func testMultibaseEncodedMultihashWithLeading0x12Throws() throws {
        let explicitlyEncodedMultihash =
            "f1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        #expect(throws: CIDError.self) {
            try CID(explicitlyEncodedMultihash)
        }
    }

    /// Reserved CID versions (v2 = 0x02, v3 = 0x03) are not supported.
    @Test func testReservedVersionsThrow() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        for reserved: UInt8 in [0x02, 0x03] {
            var bytes: [UInt8] = [reserved, 0x71]  // reserved version + dag-cbor
            bytes.append(contentsOf: mh.value)
            #expect(throws: CIDError.invalidVersion) {
                try CID(bytes)
            }
        }
    }

    /// A valid v1 frame (version + codec) wrapping a truncated multihash must throw.
    @Test func testTruncatedMultihashThrows() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        var bytes: [UInt8] = [0x01, 0x71]  // v1 + dag-cbor
        bytes.append(contentsOf: mh.value.dropLast(4))  // chop 4 digest bytes
        #expect(throws: CIDError.self) {
            try CID(bytes)
        }
    }

    /// - MARK: Hashable

    /// Equal CIDs (including those differing only by presentation multibase) hash equally and de-dupe.
    @Test func testHashable_EqualCIDsShareHashAndDeDupe() throws {
        let cidBase32 = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        // Same CID re-created from its raw bytes (multibase defaults may differ, equality must not)
        let cidFromBytes = try CID(cidBase32.rawData)

        #expect(cidBase32 == cidFromBytes)
        #expect(cidBase32.hashValue == cidFromBytes.hashValue)

        let set: Set<CID> = [cidBase32, cidFromBytes]
        #expect(set.count == 1)

        // A genuinely different CID is a distinct set member
        let other = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        #expect(Set([cidBase32, other]).count == 2)
    }

    /// - MARK: Codable

    @Test func testCodable_RoundTripV1() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")

        let data = try JSONEncoder().encode(cid)
        // Encoded as the single canonical string value
        #expect(
            String(decoding: data, as: UTF8.self)
                == "\"bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u\""
        )

        let decoded = try JSONDecoder().decode(CID.self, from: data)
        #expect(decoded == cid)
    }

    @Test func testCodable_RoundTripV0() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        let data = try JSONEncoder().encode(cid)
        let decoded = try JSONDecoder().decode(CID.self, from: data)

        #expect(decoded.version == .v0)
        #expect(decoded == cid)
        #expect(decoded.toBaseEncodedString == "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
    }

    /// - MARK: string(base:)

    @Test func testStringBase_MatchesToBaseEncodedStringAndThrowsForV0() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        #expect(
            try cid.string(base: .base16)
                == "f017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5"
        )

        let v0 = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        #expect(throws: CIDError.invalidV0Multibase) {
            try v0.string(base: .base16)
        }
    }

    /// - MARK: Content-hashing initializers

    @Test func testContentInit_MatchesManualMultihash() throws {
        let manual = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let expected = try CID(version: .v1, codec: .dag_pb, multihash: manual)

        let fromString = try CID(version: .v1, codec: .dag_pb, content: "hello world", hashedWith: .sha2_256)
        let fromBytes = try CID(
            version: .v1,
            codec: .dag_pb,
            content: Array("hello world".utf8),
            hashedWith: .sha2_256
        )
        let fromData = try CID(
            version: .v1,
            codec: .dag_pb,
            content: Data("hello world".utf8),
            hashedWith: .sha2_256
        )

        #expect(fromString == expected)
        #expect(fromBytes == expected)
        #expect(fromData == expected)
        #expect(fromString.multihash == manual)
    }

    @Test func testContentInit_V0() throws {
        // sha2-256 of "hello world" as a v0 CID
        let cid = try CID(version: .v0, codec: .dag_pb, content: "hello world", hashedWith: .sha2_256)
        #expect(cid.version == .v0)
        #expect(cid.toBaseEncodedString == "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4")
    }

    /// - MARK: Non-mutating version converters

    @Test func testConvertedToV1_LeavesReceiverUnchanged() throws {
        let v0 = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        let v1 = v0.convertedToV1()

        #expect(v0.version == .v0)  // receiver untouched
        #expect(v1.version == .v1)
        #expect(v1.multihash == v0.multihash)
    }

    @Test func testConvertedToV0_LeavesReceiverUnchangedAndThrowsForNonDagPb() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let v1 = try CID(version: .v1, codec: .dag_pb, multihash: mh)
        let v0 = try v1.convertedToV0()

        #expect(v1.version == .v1)  // receiver untouched
        #expect(v0.version == .v0)
        #expect(v0.multihash == mh)

        let cbor = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        #expect(throws: CIDError.invalidV0Codec) {
            try cbor.convertedToV0()
        }
    }

    /// - MARK: CIDError presentation

    @Test func testCIDError_LocalizedDescriptionIsSurfaced() throws {
        let error = CIDError.invalidV0Multibase
        #expect(error.errorDescription == "CID v0 only supports base58btc encoding")
        #expect((error as Error).localizedDescription == "CID v0 only supports base58btc encoding")
    }
}
