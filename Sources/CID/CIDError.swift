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

public enum CIDError: Error, Hashable, Sendable {
    case cidStringTooShort
    case invalidCIDString
    case trailingBytes
    case invalidVersion
    case invalidV0Codec
    case invalidV0Multihash
    case invalidV0Multibase
    case invalidMultihash(MultihashError)
    case invalidMultibase(MultibaseError)
    case invalidMulticodec(MulticodecError)
}

extension CIDError: CustomStringConvertible, LocalizedError {
    public var description: String {
        switch self {
        case .invalidMultihash(let e):
            return "failed to instantiate Multihash: \(e)"
        case .cidStringTooShort:
            return "raw CID String is too short"
        case .invalidCIDString:
            return "unable to parse raw CID String"
        case .trailingBytes:
            return "the CID buffer contained trailing bytes"
        case .invalidVersion:
            return "unable to parse raw CID String Version"
        case .invalidMultibase(let e):
            return "failed to decode Multibase: \(e)"
        case .invalidMulticodec(let e):
            return "failed to decode Multicodec: \(e)"
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
