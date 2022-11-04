import XCTest
@testable import CID
import Multihash
import Multicodec
import Multibase

final class CIDTests: XCTestCase {
    func testVersion0_B58_String() throws {
        let mhStr = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid = try CID(mhStr)
        
        XCTAssertEqual(cid.codec, .dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, try Multihash(b58String: "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"))
        XCTAssertEqual(cid.multihash.asString(base: .base58btc), mhStr)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertEqual(cid.toBaseEncodedString, mhStr)
    }
    
    func testVersion0_UInt8Array() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let mhStr = "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4"
        let cid = try CID(mh.value)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multihash.asString(base: .base58btc), mhStr)
        XCTAssertEqual(cid.multibase, .base58btc)

        XCTAssertEqual(cid.toBaseEncodedString, mhStr)
        print(cid.rawBuffer.map { "\($0)" }.joined(separator: " "))
    }
    
    func testVersion0_CreateByParts() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: .dag_pb, multihash: mh)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
    }
    
    func testVersion0_CreateByPartsIntCodec() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: try Codecs(112), multihash: mh)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
    }
    
    func testVersion0_CreateByV0Multihash() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
    }
    
    func testVersion0_InvalidB58String() throws {
        XCTAssertThrowsError(try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII"), "Invalid B58 String") { error in
            print(error)
        }
    }
    
    func testVersion0_NonDAG_PB_Version0() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        XCTAssertThrowsError(try CID(version: .v0, codec: .dag_cbor, multihash: mh), "Invalid V0 Codec") { error in
            print(error)
        }
    }
    
    /// - TODO: We dont support specifiying the base...
    //it('throws on trying to create a CIDv0 with a base other than base58btc', () => {
    //  expect(
    //    () => new CID(0, 'dag-pb', hash, 'base32')
    //  ).to.throw("multibaseName must be 'base58btc' for CIDv0")
    //})
    
    func testVersion0_PreventNonB58Encodings() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertThrowsError(try cid.toBaseEncodedString(.base16), "V0 CIDs can only be encoded as base58btc", { error in
            print(error)
        })
    }

    func testVersion0_Prefix() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertEqual(cid.prefix.toHexString(), "00701220")
        XCTAssertEqual(cid.prefix.asString(base: .base16), "00701220")
    }
    
    /// - TODO: CID.Bytes should return Multihash value???
    func testVersion0_RawBytes() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(v0WithMultihash: mh)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertEqual(cid.multihash.asString(base: .base16), "1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
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
    
    func testVersion1_MultibaseEncodedString() throws {
        let cidString = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        let cid = try CID(cidString)

        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertNotNil(cid.multihash)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertEqual(cid.toBaseEncodedString, cidString)
    }
    
    
    func testVersion1_NonMultibaseEncodedString() throws {
        let cidString = "bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u"
        let cidBuf = try Data(decoding: "017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5", as: .base16)

        let cid = try CID(Array(cidBuf))
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertNotNil(cid.multihash)
        XCTAssertEqual(cid.multibase, .base32)
        
        XCTAssertEqual(cid.toBaseEncodedString, cidString)
    }
    
    
    func testVersion1_PeerIdString() throws {
        let peerIdStr = "k51qzi5uqu5dj16qyiq0tajolkojyl9qdkr254920wxv7ghtuwcz593tp69z9m"

        let cid = try CID(peerIdStr)
        
        XCTAssertEqual(cid.codec, .libp2p_key)
        XCTAssertEqual(cid.code, 114)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertNotNil(cid.multihash)
        XCTAssertEqual(cid.multibase, .base36)
        
        XCTAssertEqual(cid.toBaseEncodedString, peerIdStr)
    }
    
    func testVersion1_CreateByParts() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        
        XCTAssertEqual(cid.codec, .dag_cbor)
        XCTAssertEqual(cid.code, 113)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base32)
        
        print(cid.toBaseEncodedString)
    }
    
    func testVersion1_RoundTrip() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)
        
        XCTAssertEqual(cid1.codec, .dag_cbor)
        XCTAssertEqual(cid1.code, 113)
        XCTAssertEqual(cid1.version, .v1)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base32)
        
        XCTAssertEqual(cid1.codec, cid2.codec)
        XCTAssertEqual(cid1.code, cid2.code)
        XCTAssertEqual(cid1.version, cid2.version)
        XCTAssertEqual(cid1.multihash, cid2.multihash)
        XCTAssertEqual(cid1.multibase, cid2.multibase)
    }
    
    func testVersion1_MultiByteCodecCodes() throws {
        let ethBlockHash = try Data(decoding: "8a8e84c797605fbe75d5b5af107d4220a2db0ad35fd66d9be3d38d87c472b26d", as: .base16)
        let mh = try Multihash(raw: ethBlockHash, hashedWith: .keccak_256)
        let cid1 = try CID(version: .v1, codec: .eth_block, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)
        
        XCTAssertEqual(cid1.codec, .eth_block)
        XCTAssertEqual(cid1.code, 144)
        XCTAssertEqual(cid1.version, .v1)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base32)
        
        XCTAssertEqual(cid1.codec, cid2.codec)
        XCTAssertEqual(cid1.code, cid2.code)
        XCTAssertEqual(cid1.version, cid2.version)
        XCTAssertEqual(cid1.multihash, cid2.multihash)
        XCTAssertEqual(cid1.multibase, cid2.multibase)
    }
    
    func testVersion1_MultiByteCodecCodes2() throws {
        let p2pHash = try Data(decoding: "8a8e84c797605fbe75d5b5af107d4220a2db0ad35fd66d9be3d38d87c472b26d", as: .base16)
        let mh = try Multihash(raw: p2pHash, hashedWith: .keccak_256)
        let cid1 = try CID(version: .v1, codec: .p2p, multihash: mh)
        let cid2 = try CID(cid1.toBaseEncodedString)
        let cid3 = try CID(version: .v1, codec: .ipfs, multihash: mh)
        
        XCTAssertEqual(cid1.codec, .p2p)
        XCTAssertEqual(cid1.code, 0x01a5)
        XCTAssertEqual(cid1.version, .v1)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base32)
        
        XCTAssertEqual(cid1.codec, cid2.codec)
        XCTAssertEqual(cid1.code, cid2.code)
        XCTAssertEqual(cid1.version, cid2.version)
        XCTAssertEqual(cid1.multihash, cid2.multihash)
        XCTAssertEqual(cid1.multibase, cid2.multibase)
        
        /// P2P =/= IPFS Interop (Name is different, code is different)
        XCTAssertNotEqual(cid1.codec, cid3.codec) // .ipfs  != .p2p
        XCTAssertNotEqual(cid1.code, cid3.code)      // 0x01a5 == 0x01a5
        XCTAssertEqual(cid1.version, cid3.version)
        XCTAssertEqual(cid1.multihash, cid3.multihash)
        XCTAssertEqual(cid1.multibase, cid3.multibase)
        
    }
    
    func testVersion1_Prefix() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        
        XCTAssertEqual(cid1.codec, .dag_cbor)
        XCTAssertEqual(cid1.code, 113)
        XCTAssertEqual(cid1.version, .v1)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base32)
        
        print(cid1.rawBuffer.map { "\($0)" }.joined(separator: " "))
        print(cid1.rawBuffer.toHexString())
        XCTAssertEqual(cid1.prefix.asString(base: .base16), "01711220")
    }
    
    
    func testVersion1_Identity() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .identity)
        
        let cid1 = try CID(version: .v0, codec: .dag_pb, multihash: mh)
        XCTAssertEqual(cid1.codec, .dag_pb)
        XCTAssertEqual(cid1.code, 112)
        XCTAssertEqual(cid1.version, .v0)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base58btc)
        XCTAssertEqual(cid1.multihash.b58String, "161g3c")
        
        let cid2 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        XCTAssertEqual(cid2.codec, .dag_cbor)
        XCTAssertEqual(cid2.code, 113)
        XCTAssertEqual(cid2.version, .v1)
        XCTAssertEqual(cid2.multihash, mh)
        XCTAssertEqual(cid2.multibase, .base32)
        XCTAssertEqual(cid2.toBaseEncodedString, "bafyqaa3bmjrq")
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
    func testVersion1_RawBytes() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        
        let cid1 = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        
        XCTAssertEqual(cid1.codec, .dag_cbor)
        XCTAssertEqual(cid1.code, 113)
        XCTAssertEqual(cid1.version, .v1)
        XCTAssertEqual(cid1.multihash, mh)
        XCTAssertEqual(cid1.multibase, .base32)
        XCTAssertEqual(cid1.rawBuffer.toHexString(), "01711220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(cid1.rawBuffer.asString(base: .base16), "01711220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
    
    func testVersion1_UnknownCodec() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        XCTAssertThrowsError(try CID(version: .v1, codec: try Codecs(10000), multihash: mh), "Unknown Codec") { error in
            print(error)
        }
    }
    
    func testVersion1_UnknownCodec2() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        XCTAssertThrowsError(try CID(version: .v1, codec: try Codecs("this-codec-does-not-exist"), multihash: mh), "Unknown Codec") { error in
            print(error)
        }
    }
    
    
    
    func testToString_CIDString() throws {
        let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
        
        let cid = try CID(mh.value)
        
        XCTAssertEqual(cid.toBaseEncodedString, "QmatYkNGZnELf8cAGdyJpUca2PyY4szai3RHyyWofNY1pY")
    }
    
    func testToString_SameBase_Base64() throws {
        let base64Str = "mAXASIOnrbGCADfkPyOI37VMkbzluh1eaukBqqnl2oFaFnuIt"
        let cid = try CID(base64Str)
        XCTAssertEqual(cid.toBaseEncodedString, "mAXASIOnrbGCADfkPyOI37VMkbzluh1eaukBqqnl2oFaFnuIt")
    }
    
    func testToString_SameBase_Base16() throws {
        let base16Str = "f01701220e9eb6c60800df90fc8e237ed53246f396e87579aba406aaa7976a056859ee22d"
        let cid = try CID(base16Str)
        XCTAssertEqual(cid.toBaseEncodedString, "f01701220e9eb6c60800df90fc8e237ed53246f396e87579aba406aaa7976a056859ee22d")
    }
    
    func testToString_SpecificBaseOutput() throws {
        let base58Str = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        let base64URLStr = "uAXASIHJSUj5lkfuP5VPWf_VahvhARLRqPkF24QxY-lKaSqvV"
        let cid = try CID(base58Str)
        XCTAssertEqual(cid.toBaseEncodedString, base58Str)
        XCTAssertEqual(cid.rawBuffer.asString(base: .base64Url, withMultibasePrefix: true), base64URLStr)
    }
    
    /// - MARK: Utilities
    func testUtilities_Equality() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let h2 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1o"
        
        let cid1 = try CID(h1)
        let cid2 = try CID(h2)
        
        XCTAssertEqual(cid1, cid1)
        XCTAssertEqual(cid1 == cid1, true)
        
        XCTAssertNotEqual(cid1, cid2)
        XCTAssertEqual(cid1 == cid2, false)
    }
    
    func testUtilities_EqualityVersionShift() throws {
        let h1 = "zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS"
        
        let cidV1 = try CID(h1)
        var cidV0 = cidV1
        try cidV0.toV0()
        
        XCTAssertNotEqual(cidV0, cidV1)
        XCTAssertEqual(cidV0 == cidV1, false)
        XCTAssertNotEqual(cidV1, cidV0)
        XCTAssertEqual(cidV1 == cidV0, false)
    
        XCTAssertEqual(cidV0.multihash, cidV1.multihash)
    }
    
    func testUtilities_EqualityStringVsBuffer() throws {
        let cidStr = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        
        let cid = try CID(cidStr)
        let cidA = try CID(version: cid.version, codec: cid.codec, hash: cid.multihash.value)
        let cidB = try CID(cidStr)
    
        XCTAssertEqual(cidA, cidB)
    }
    
    /// - MARK: Invalid Inputs
    func testInvalidInputs() throws {
        let invalidInputs = [
            "hello world",
            "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L",
            "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT",
            "uAXASIHJSUj5lkfuP5VPWf_VahvhARLRqPkF24QxY-lKaSqvV24"
        ]
        for i in invalidInputs {
            //As string
            XCTAssertThrowsError(try CID(i))
            
            //As Data
            XCTAssertThrowsError(try CID(Data(i.utf8)))
            
            //As UInt8 Array
            XCTAssertThrowsError(try CID(Array(i.utf8)))
            
            //As string with parts...
            XCTAssertThrowsError(try CID(version: .v0, codec: .dag_pb, hash: i))
            
            //As string with parts...
            XCTAssertThrowsError(try CID(version: .v1, codec: .dag_pb, hash: i))
        }
        
        /// Enforce Supported Versions only...
        for i in (-2...3) {
            let ver = CIDVersion(rawValue: i)
            switch i {
            case 0, 1:
                XCTAssertNotNil(ver)
            default:
                XCTAssertNil(ver)
            }
        }
    }
    
    /// - MARK: Version Shifting...
    func testVersionShifting_V0ToV1() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v0, codec: .dag_pb, multihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        cid.toV1()
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
    }
    
    func testVersionShifting_V1ToV0() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base32)
        
        try cid.toV0()
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
    }
    
    func testVersionShifting_V1ToV0ThrowsIfWrongCodec() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        var cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_cbor)
        XCTAssertEqual(cid.code, 113)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base32)
        
        XCTAssertThrowsError(try cid.toV0(), "Invalid Codec For V0 conversion") { error in
            print(error)
        }
    }
    
    func testVersionShifting_V1ToV0ThrowsIfWrongHashAlgo() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_512)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base32)
        
        XCTAssertThrowsError(try cid.toV0(), "Invalid Hash Algorithm For V0 conversion") { error in
            print(error)
        }
    }
    
    func testVersionShifting_V1ToV0ThrowsIfWrongHashLength() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256, customByteLength: 31)
        var cid = try CID(version: .v1, codec: .dag_pb, multihash: mh)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base32)
        
        XCTAssertThrowsError(try cid.toV0(), "Invalid Hash Algorithm For V0 conversion") { error in
            print(error)
        }
    }
    
    /// CIDs are structs so they copy by default, they'll never point to the same memory...
    func testIdempotence() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid1 = try CID(h1)
        let cid2 = CID(cid1)
        
        XCTAssertTrue(cid1 == cid2)
        let cid1Pointer = withUnsafePointer(to: cid1) { "\($0)" }
        let cid2Pointer = withUnsafePointer(to: cid2) { "\($0)" }
        XCTAssertNotEqual(cid1Pointer, cid2Pointer)
    }
    
    /// CIDs are structs so they copy by default, they'll never point to the same memory...
    func testIdempotence2() throws {
        let h1 = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
        let cid1 = try CID(h1)
        let cid2 = cid1
        
        XCTAssertTrue(cid1 == cid2)
        let cid1Pointer = withUnsafePointer(to: cid1) { "\($0)" }
        let cid2Pointer = withUnsafePointer(to: cid2) { "\($0)" }
        XCTAssertNotEqual(cid1Pointer, cid2Pointer)
    }
    
    
    
    
    
    
    func testExampleTwo() throws {
        let mh = try Multihash(raw: "hello world", hashedWith: .sha2_256)
        let cid = try CID("z1CBaeXvdXThAxmycy1Ezp73CEFDiJ54MoSSjXodtViWzEyEAU")
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, mh)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        XCTAssertEqual(try cid.asMultibase(.base58btc), "z1CBaeXvdXThAxmycy1Ezp73CEFDiJ54MoSSjXodtViWzEyEAU")
    }
    
    func testExample2() throws {
        let cid = try CID("zdj7Wd8AMwqnhJGQCbFxBVodGSBG84TM7Hs1rcJuQMwTyfEDS")
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertNotNil(cid.multihash)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        print(cid.toBaseEncodedString)
    }
    
    func testExample3() throws {
        let cid = try CID("bafybeidskjjd4zmr7oh6ku6wp72vvbxyibcli2r6if3ocdcy7jjjusvl2u")
        //let cidBuf = uint8ArrayFromString('017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5', 'base16')
        //let buf = try BaseEncoding.decode("017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5", as: .base16)
        let buf = try Array<UInt8>(decoding: "017012207252523e6591fb8fe553d67ff55a86f84044b46a3e4176e10c58fa529a4aabd5", as: .base16)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v1)
        XCTAssertNotNil(cid.multihash)
        XCTAssertEqual(cid.multibase, .base32)
        
        XCTAssertEqual(cid.rawBuffer, buf)
        
        print(cid.toBaseEncodedString)
    }
    
    func testExample4() throws {
        let cid = try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash.asString(base: .base58btc), "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
        XCTAssertEqual(cid.multibase, .base58btc)
        
        //XCTAssertEqual(cid.rawBuffer, buf)
        print(cid.toBaseEncodedString)
    }
    
    /// const cid = new CID(0, 'dag-pb', hash)

    /// expect(cid).to.have.property('codec', 'dag-pb')
    /// expect(cid).to.have.property('code', 112)
    /// expect(cid).to.have.property('version', 0)
    /// expect(cid).to.have.property('multihash')
    /// expect(cid).to.have.property('multibaseName', 'base58btc')
    func testExample5() throws {
        let multi = try Multihash(raw: "abc", hashedWith: .sha2_256)
        let cid = try CID(version: .v0, codec: .dag_pb, multihash: multi)
        
        XCTAssertEqual(cid.codec, Codecs.dag_pb)
        XCTAssertEqual(cid.code, 112)
        XCTAssertEqual(cid.version, .v0)
        XCTAssertEqual(cid.multihash, multi)
        XCTAssertEqual(cid.multibase, .base58btc)
        
        //XCTAssertEqual(cid.rawBuffer, buf)
        print(cid.toBaseEncodedString)
    }
    
    func testThrowsInvalidMultihash() throws {
        XCTAssertThrowsError(try CID("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zIII"), "Threw Error") { error in
            print(error)
        }
    }
    
    static var allTests = [
        ("testVersion0_B58_String", testVersion0_B58_String),
        ("testVersion0_UInt8Array", testVersion0_UInt8Array),
        ("testVersion0_CreateByParts", testVersion0_CreateByParts),
        ("testVersion0_CreateByPartsIntCodec", testVersion0_CreateByPartsIntCodec),
        ("testVersion0_CreateByV0Multihash", testVersion0_CreateByV0Multihash),
        ("testVersion0_InvalidB58String", testVersion0_InvalidB58String),
        ("testVersion0_NonDAG_PB_Version0", testVersion0_NonDAG_PB_Version0),
        ("testVersion0_PreventNonB58Encodings", testVersion0_PreventNonB58Encodings),
        ("testVersion0_Prefix", testVersion0_Prefix),
        ("testVersion0_RawBytes", testVersion0_RawBytes),
        ("testVersion1_MultibaseEncodedString", testVersion1_MultibaseEncodedString),
        ("testVersion1_NonMultibaseEncodedString", testVersion1_NonMultibaseEncodedString),
        ("testVersion1_PeerIdString", testVersion1_PeerIdString),
        ("testVersion1_CreateByParts", testVersion1_CreateByParts),
        ("testVersion1_RoundTrip", testVersion1_RoundTrip),
        ("testVersion1_MultiByteCodecCodes", testVersion1_MultiByteCodecCodes),
        ("testVersion1_MultiByteCodecCodes2", testVersion1_MultiByteCodecCodes2),
        ("testVersion1_Prefix", testVersion1_Prefix),
        ("testVersion1_Identity", testVersion1_Identity),
        ("testVersion1_RawBytes", testVersion1_RawBytes),
        ("testVersion1_UnknownCodec", testVersion1_UnknownCodec),
        ("testVersion1_UnknownCodec2", testVersion1_UnknownCodec2),
        ("testToString_CIDString", testToString_CIDString),
        ("testToString_SameBase_Base64", testToString_SameBase_Base64),
        ("testToString_SameBase_Base16", testToString_SameBase_Base16),
        ("testToString_SpecificBaseOutput", testToString_SpecificBaseOutput),
        ("testUtilities_Equality", testUtilities_Equality),
        ("testUtilities_EqualityVersionShift", testUtilities_EqualityVersionShift),
        ("testUtilities_EqualityStringVsBuffer", testUtilities_EqualityStringVsBuffer),
        ("testInvalidInputs", testInvalidInputs),
        ("testVersionShifting_V0ToV1", testVersionShifting_V0ToV1),
        ("testVersionShifting_V1ToV0", testVersionShifting_V1ToV0),
        ("testVersionShifting_V1ToV0ThrowsIfWrongCodec", testVersionShifting_V1ToV0ThrowsIfWrongCodec),
        ("testVersionShifting_V1ToV0ThrowsIfWrongHashAlgo", testVersionShifting_V1ToV0ThrowsIfWrongHashAlgo),
        ("testVersionShifting_V1ToV0ThrowsIfWrongHashLength", testVersionShifting_V1ToV0ThrowsIfWrongHashLength),
        ("testIdempotence", testIdempotence),
        ("testIdempotence2", testIdempotence2),
        ("testExampleTwo", testExampleTwo),
        ("testExample2", testExample2),
        ("testExample3", testExample3),
        ("testExample4", testExample4),
        ("testExample5", testExample5),
        ("testThrowsInvalidMultihash", testThrowsInvalidMultihash)
    ]
}
