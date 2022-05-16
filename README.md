# CID (Content IDentifier) Specification

[![](https://img.shields.io/badge/made%20by-Breth-blue.svg?style=flat-square)](https://breth.app)
[![](https://img.shields.io/badge/project-multiformats-blue.svg?style=flat-square)](https://github.com/multiformats/multiformats)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-blue.svg?style=flat-square)](https://github.com/apple/swift-package-manager)
![Build & Test (macos and linux)](https://github.com/swift-libp2p/swift-cid/actions/workflows/build+test.yml/badge.svg)

> Self-describing content-addressed identifiers for distributed systems

## Table of Contents

- [Overview](#overview) 
- [Install](#install)
- [Usage](#usage)
  - [Examples](#examples)
  - [API](#api)
- [More Info](#more-info) 
  - [What is it?](#what-is-it)
  - [How does it work?](#how-does-it-work)
  - [Design Considerations](#design-considerations)
  - [Human Readable CIDs](#human-readable-cids)
  - [Versions](#versions)
    - [CIDv0](#cidv0)
    - [CIDv1](#cidv1)
  - [Decoding Algorithm](#decoding-algorithm)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)


## Overview
A CID is a self-describing content-addressed identifier. It uses cryptographic hashes to achieve content addressing. It uses several [multiformats](https://github.com/multiformats/multiformats) to achieve flexible self-description, namely [multihash](https://github.com/multiformats/multihash) for hashes, [multicodec](https://github.com/multiformats/multicodec) for data content types, and [multibase](https://github.com/multiformats/multibase) to encode the CID itself into strings.


## Install

To use CID in your swift project simply include the package as a dependency in your Package.swift
```swift
let package = Package(
    ...
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swift-libp2p/swift-cid.git", .upToNextMajor(from: "0.0.1")),
        ...
    ],
    ...
        .target(
            ...
            dependencies: [
                ...
                .product(name: "CID", package: "swift-cid"),
            ]),
    ...
)
```

## Usage

### Examples
Initialize a v0 CID from a v0 CID String
```swift
import CID

let mhStr = "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
let cid = try CID(mhStr)

cid.codec => .dag_pb
cid.code => 112
cid.version => .v0
cid.multibase => .base58btc
cid.toBaseEncodedString => "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
cid.multihash.asString(base: .base58btc) => "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"
```

Initialize a v1 CID from a Multibase encoded v1 CID String
```swift
let peerIdStr = "k51qzi5uqu5dj16qyiq0tajolkojyl9qdkr254920wxv7ghtuwcz593tp69z9m" //LibP2P peerID
let cid = try CID(peerIdStr)

cid.codec => .libp2p_key
cid.code => 114
cid.version => .v1
cid.multibase => .base36
cid.toBaseEncodedString => "k51qzi5uqu5dj16qyiq0tajolkojyl9qdkr254920wxv7ghtuwcz593tp69z9m"
```

Initialize a v1 CID from parts
```swift
let mh = try Multihash(raw: "abc", hashedWith: .sha2_256)
let cid = try CID(version: .v1, codec: .dag_cbor, multihash: mh)

cid.codec => .dag_cbor
cid.code => 113
cid.version => .v1
cid.multibase => .base32
cid.toBaseEncodedString => "bafyreif2pall7dybz7vecqka3zo24irdwabwdi4wc55jznaq75q7eaavvu"
```

Check out [CIDTests.swift](https://github.com/SwiftEthereum/CID/blob/main/Tests/CIDTests/CIDTests.swift) for more examples on how you can instantiate and use CIDs

### API
```swift

/// Initializers
/// Specify the version, codec and hash
CID.init(version:CIDVersion, codec:Codecs, hash:[UInt8])
CID.init(version:CIDVersion, codec:Codecs, hash:String)

/// From a Multihash
CID.init(v0WithMultihash multihash:Multihash)

/// From a CID compliant String / Data
CID.init(_ cid:String)


/// Properties
/// Integer based Enum, currently supports v0 or v1
CID.version:CIDVersion

/// The `Codec` used (ex: 'dag-pb')
CID.codec:Codecs

/// The Multibase used for encoding (ex: 'base32')
CID.multibase:BaseEncoding

/// The CIDs Multihash
CID.multihash:Multihash

/// Returns the Integer code of the Codec used by this CID (ex: dag-pb' -> 112)
CID.code:Int 

/// Returns the entirety of the CID as Bytes (Prefixs and Multihash Digest)
CID.rawBuffer:[UInt8] 
    
/// Returns the entirety of the CID as Data (Prefixs and Multihash Digest)
CID.rawData:Data
    
/// Returns the CIDs Prefix (includes everything but the multihash digest)
///
/// The CID prefix includes the following...
/// - [version] [codec] [hash-algo] [hash-length]
CID.prefix:[UInt8]


/// Convert between CID versions
CID.toV1()
CID.toV0()

```

## More Info

### What is it?

[**CID**](https://github.com/ipld/cid) is a format for referencing content in distributed information systems, like [IPFS](https://ipfs.io). It leverages [content addressing](https://en.wikipedia.org/wiki/Content-addressable_storage), [cryptographic hashing](https://simple.wikipedia.org/wiki/Cryptographic_hash_function), and [self-describing formats](https://github.com/multiformats/multiformats). It is the core identifier used by [IPFS](https://ipfs.io) and [IPLD](https://ipld.io). It uses a [multicodec](https://github.com/multiformats/multicodec) to indicate its version, making it fully self describing.

**You can read an in-depth discussion on why this format was needed in IPFS here: https://github.com/ipfs/specs/issues/130 (first post reproduced [here](./original-rfc.md))**

A CID is a self-describing content-addressed identifier. It uses cryptographic hashes to achieve content addressing. It uses several [multiformats](https://github.com/multiformats/multiformats) to achieve flexible self-description, namely [multihash](https://github.com/multiformats/multihash) for hashes, [multicodec](https://github.com/multiformats/multicodec) for data content types, and [multibase](https://github.com/multiformats/multibase) to encode the CID itself into strings.

Concretely, it's a *typed* content address: a tuple of `(content-type, content-address)`.

### How does it work?

Current version: CIDv1

A CIDv1 has four parts:

```sh
<cidv1> ::= <mb><multicodec-cidv1><mc><mh>
# or, expanded:
<cidv1> ::= <multibase-prefix><multicodec-cidv1><multicodec-content-type><multihash-content-address>
```

Where

- `<multibase-prefix>` is a [multibase](https://github.com/multiformats/multibase) code (1 or 2 bytes), to ease encoding CIDs into various bases. **NOTE:** *Binary* (not text-based) protocols and formats may omit the multibase prefix when the encoding is unambiguous.
- `<multicodec-cidv1>` is a [multicodec](https://github.com/multiformats/multicodec) representing the version of CID, here for upgradability purposes.
- `<multicodec-content-type>` is a [multicodec](https://github.com/multiformats/multicodec) code representing the content type or format of the data being addressed.
- `<multihash-content-address>` is a [multihash](https://github.com/multiformats/multihash) value, representing the cryptographic hash of the content being addressed. Multihash enables CIDs to use many different cryptographic hash function, for upgradability and protocol agility purposes.

That's it!

### Design Considerations

CIDs design takes into account many difficult tradeoffs encountered while building [IPFS](https://ipfs.io). These are mostly coming from the multiformats project.

- Compactness: CIDs are binary in nature to ensure these are as compact as possible, as they're meant to be part of longer path identifiers or URIs.
- Transport friendliness (or "copy-pastability"): CIDs are encoded with multibase to allow choosing the best base for transporting. For example, CIDs can be encoded into base58btc to yield shorter and easily-copy-pastable hashes.
- Versatility: CIDs are meant to be able to represent values of any format with any cryptographic hash.
- Avoid Lock-in: CIDs prevent lock-in to old, potentially-outdated decisions.
- Upgradability: CIDs encode a version to ensure the CID format itself can evolve.

### Human Readable CIDs

It is advantageous to have a human readable description of a CID, solely for the purposes of debugging and explanation. We can easily transform a CID to a "Human Readable CID" as follows:

```
<hr-cid> ::= <hr-mbc> "-" <hr-cid-mc> "-" <hr-mc> "-" <hr-mh>
```
Where each sub-component is represented with its own human-readable form:

- `<hr-mbc>` is a human-readable multibase code (eg `base58btc`)
- `<hr-cid-mc>` is the string `cidv#` (eg `cidv1` or `cidv2`)
- `<hr-mc>` is a human-readable multicodec code (eg `cbor`)
- `<hr-mh>` is a human-readable multihash (eg `sha2-256-256-abcdef0123456789...`)

For example:

```
# example CID
zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA
# corresponding human readable CID
base58btc - cidv1 - raw - sha2-256-256-6e6ff7950a36187a801613426e858dce686cd7d7e3c0fc42ee0330072d245c95
```

See: https://cid.ipfs.io/#zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA

### Versions

#### CIDv0

CIDv0 is a backwards-compatible version, where:
- the `multibase` of the string representation is always `base58btc` and implicit (not written)
- the `multicodec` is always `dag-pb` and implicit (not written)
- the `cid-version` is always `cidv0` and implicit (not written)
- the `multihash` is written as is but is always a full (length 32) sha256 hash.

```
cidv0 ::= <multihash-content-address>
```

#### CIDv1

A CIDv1 has four parts:

```sh
<cidv1> ::= <mb><multicodec-cidv1><mc><mh>
# or, expanded:
<cidv1> ::= <multibase-prefix><multicodec-cidv1><multicodec-content-type><multihash-content-address>
```

### Decoding Algorithm

To decode a CID, follow the following algorithm:

1. If it's a string (ASCII/UTF-8):
  * If it is 46 characters long and starts with `Qm...`, it's a CIDv0. Decode it as base58btc and continue to step 2.
  * Otherwise, decode it according to the multibase spec and:
    * If the first decoded byte is 0x12, return an error. CIDv0 CIDs may not be multibase encoded and there will be no CIDv18 (0x12 = 18) to prevent ambiguity with decoded CIDv0s.
    * Otherwise, you now have a binary CID. Continue to step 2.
2. Given a (binary) CID (`cid`):
   * If it's 34 bytes long with the leading bytes `[0x12, 0x20, ...]`, it's a CIDv0.
     * The CID's multihash is `cid`.
     * The CID's multicodec is DagProtobuf
     * The CID's version is 0.
   * Otherwise, let `N` be the first varint in `cid`. This is the CID's version.
     * If `N == 0x01` (CIDv1):
       * The CID's multicodec is the second varint in `cid`
       * The CID's multihash is the rest of the `cid` (after the second varint).
       * The CID's version is 1.
     * If `N == 0x02` (CIDv2), or `N == 0x03` (CIDv3), the CID version is reserved.
     * If `N` is equal to some other multicodec, the CID is malformed.


## Contributing

Contributions are welcomed! This code is very much a proof of concept. I can guarantee you there's a better / safer way to accomplish the same results. Any suggestions, improvements, or even just critques, are welcome! 

Let's make this code better together! 🤝

## Credits

- [krzyzanowskim - CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [multiformats](https://github.com/multiformats/multiformats)
- [CID](https://github.com/ipld/cid)
- [IPFS](https://ipfs.io)

## License

[MIT](LICENSE) © 2022 Breth Inc.
