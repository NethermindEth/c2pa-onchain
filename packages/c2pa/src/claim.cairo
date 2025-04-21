use crate::cbor::{CborSerde, write_map_field, write_map_field_opt, write_map_header};
use crate::cbor_types::{
    OptionCborSerde, SnapCborSerde, SnapSerde, SpanCborSerde, String, StringCborSerde,
};
use crate::hashed_uri::HashedUri;
use crate::word_array::WordArray;

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
/// they do not contribute to the signature.
/// Some fields have Option<()> type which means that they are not supported
/// at the moment (but correcly serialized in case of default values).
#[derive(Drop, Copy, Debug, Serde)]
pub struct Claim {
    /// Title for this claim, generally the name of the containing asset
    pub title: Option<String>,
    /// MIME format of document containing this claim
    pub format: String,
    /// Instance Id of document containing this claim
    pub instance_id: String,
    /// Generator of this claim
    pub claim_generator: String,
    // Detailed generator info of this claim
    pub claim_generator_info: Option<()>, // not supported
    /// Link to signature box
    pub signature: String,
    /// List of assertion hashed URIs
    pub assertions: Span<HashedUri>,
    /// List of redacted assertions
    pub redacted_assertions: Option<()>, // not supported
    /// Hashing algorithm, SHA256 by default
    pub alg: Option<String>,
    /// Hashing algorithm for soft bindings
    pub alg_soft: Option<()>, // not supported
    /// Claim generator hints
    pub claim_generator_hints: Option<()>, // not supported
    /// Metadata
    pub metadata: Option<()> // not supported
}

/// CBOR serialization implementation for Claim
impl ClaimCborSerde of CborSerde<Claim> {
    fn cbor_serialize(self: @Claim, ref output: WordArray) {
        let mut num_fields = 6;
        if self.title.is_some() {
            num_fields += 1; // #[serde(skip_serializing_if = "Option::is_none")]
        }
        if self.alg.is_some() {
            num_fields += 1; // #[serde(skip_serializing_if = "Option::is_none")]
        }
        write_map_header(ref output, num_fields);
        write_map_field_opt("dc:title", *self.title, ref output);
        write_map_field("dc:format", *self.format, ref output);
        write_map_field("instanceID", *self.instance_id, ref output);
        write_map_field("claim_generator", *self.claim_generator, ref output);
        write_map_field("claim_generator_info", self.claim_generator_info, ref output);
        write_map_field("signature", *self.signature, ref output);
        write_map_field("assertions", self.assertions, ref output);
        write_map_field_opt("alg", *self.alg, ref output);
    }
}

#[cfg(test)]
mod tests {
    use crate::word_array::hex::words_to_hex;
    use crate::word_array::{WordArray, WordArrayTrait};
    use super::{Claim, ClaimCborSerde};

    #[test]
    fn test_claim_serialization() {
        let claim = Claim {
            title: Option::None,
            format: @"",
            instance_id: @"",
            claim_generator: @"adobe unit test",
            claim_generator_info: Option::None,
            signature: @"self#jumbf=/c2pa/adobe:urn:uuid:721dc504-0ee3-4f16-a2ad-7b33522321c7/c2pa.signature",
            assertions: array![].span(),
            redacted_assertions: Option::None,
            alg: Option::Some(@"sha256"),
            alg_soft: Option::None,
            claim_generator_hints: Option::None,
            metadata: Option::None,
        };

        let mut output: WordArray = Default::default();
        ClaimCborSerde::cbor_serialize(@claim, ref output);

        let res = words_to_hex(output.span());
        let expected: ByteArray =
            "a76964633a666f726d6174606a696e7374616e63654944606f636c61696d5f67656e657261746f726f61646f626520756e6974207465737474636c61696d5f67656e657261746f725f696e666ff6697369676e6174757265785373656c66236a756d62663d2f633270612f61646f62653a75726e3a757569643a37323164633530342d306565332d346631362d613261642d3762333335323233323163372f633270612e7369676e61747572656a617373657274696f6e738063616c6766736861323536";
        assert_eq!(expected, res);
    }
}
