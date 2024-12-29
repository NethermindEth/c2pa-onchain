//! Ported from https://github.com/contentauth/c2pa-rs/blob/main/sdk/src/claim.rs

/// A `Claim` gathers together all the `Assertion`s about an asset
/// from an actor at a given time, and may also include one or more
/// hashes of the asset itself, and a reference to the previous `Claim`.
///
/// It has all the same properties as an `Assertion` including being
/// assigned a label (`c2pa.claim.v1`) and being either embedded into the
/// asset or in the cloud. The claim is cryptographically hashed and
/// that hash is signed to produce the claim signature.
/// 
/// NOTE that some fields from the reference definition are omitted since
/// they do not contribute to the signature, or commented out in case
/// only default values (None) are supported at the moment.
#[derive(Drop, Copy, Debug, Serde)]
pub struct Claim {
    /// Title for this claim, generally the name of the containing asset [dc:title]
    pub title: Option<@ByteArray>,

    /// MIME format of document containing this claim [dc:format]
    pub format: @ByteArray,

    /// Instance Id of document containing this claim [instanceID]
    pub instance_id: @ByteArray,

    /// Generator of this claim
    pub claim_generator: @ByteArray,

    // Detailed generator info of this claim (not supported)
    // pub claim_generator_info: Option<Span<ClaimGeneratorInfo>>,

    /// Link to signature box
    pub signature: @ByteArray,

    /// List of assertion hashed URIs
    pub assertions: Span<HashedUri>,

    // List of redacted assertions (not supported)
    // pub redacted_assertions: Option<Span<ByteArray>>,

    // Hashing algorithm, SHA256 by default (sha256 supported only)
    // pub alg: Option<ByteArray>,

    // Hashing algorithm for soft bindings (sha256 supported only)
    // pub alg_soft: Option<ByteArray>,

    // Claim generator hints (not supported)
    // pub claim_generator_hints: Option<Span<(ByteArray, ByteArray)>>,

    // Metadata (not supported)
    // pub metadata: Option<Span<Metadata>>,
}

#[derive(Drop, Copy, Debug, Serde)]
pub struct HashedUri {
    /// URI stored as tagged CBOR
    pub url: @ByteArray,

    // Hashing algorithm, SHA256 by default (sha256 supported only)
    // pub alg: Option<ByteArray>,

    /// Hash stored as CBOR byte string
    pub hash: @ByteArray,
}

/// `Serde` trait implementation for `ByteArray`.
pub impl ByteArraySnapSerde of Serde<@ByteArray> {
    fn serialize(self: @@ByteArray, ref output: Array<felt252>) {
        (*self).serialize(ref output);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<@ByteArray> {
        match Serde::deserialize(ref serialized) {
            Option::Some(res) => Option::Some(@res),
            Option::None => Option::None,
        }
    }
}
