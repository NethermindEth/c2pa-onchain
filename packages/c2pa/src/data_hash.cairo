use crate::assertion::AssertionTrait;
use crate::cbor::{CborSerde, write_map_field, write_map_field_opt, write_map_header};
use crate::cbor_types::{
    Bytes, BytesCborSerde, Digest, DigestCborSerde, OptionCborSerde, SnapCborSerde, SnapSerde,
    SpanCborSerde, String,
};
use crate::hash_utils::{HashRange, HashRangeCborSerde};
use crate::word_array::WordArray;

#[derive(Drop, Copy, Debug, Serde)]
pub struct DataHash {
    /// List of excluded ranges
    pub exclusions: Option<Span<HashRange>>,
    /// Name of the data hash assertion
    /// (there can be many assertions for different data ranges)
    pub name: Option<String>,
    /// Hashing algorithm (SHA256 by default)
    pub alg: Option<String>,
    /// The hash value
    pub hash: Digest,
    /// Padding
    pub pad: Bytes,
    /// Padding
    pub pad2: Option<Bytes>,
    /// URL
    pub url: Option<String>,
}

impl DataHashAssertion of AssertionTrait<DataHash> {
    /// Returns the assertion label
    fn assertion_label(self: @DataHash) -> String {
        @"c2pa.hash.data"
    }

    /// Returns the relative assertion link, as in hashed URI
    fn assertion_link(self: @DataHash) -> String {
        @"self#jumbf=c2pa.assertions/c2pa.hash.data"
    }
}

impl DataHashCborSerde of CborSerde<DataHash> {
    fn cbor_serialize(self: @DataHash, ref output: WordArray) {
        let mut num_fields = 2;
        if self.exclusions.is_some() {
            num_fields += 1;
        }
        if self.name.is_some() {
            num_fields += 1;
        }
        if self.alg.is_some() {
            num_fields += 1;
        }
        if self.pad2.is_some() {
            num_fields += 1;
        }
        if self.url.is_some() {
            num_fields += 1;
        }
        write_map_header(ref output, num_fields);
        write_map_field_opt::<Span<HashRange>>("exclusions", *self.exclusions, ref output);
        write_map_field_opt("name", *self.name, ref output);
        write_map_field_opt("alg", *self.alg, ref output);
        write_map_field("hash", self.hash, ref output);
        write_map_field("pad", self.pad, ref output);
        write_map_field_opt("pad2", *self.pad2, ref output);
        write_map_field_opt("url", *self.url, ref output);
    }
}

#[cfg(test)]
mod tests {
    use crate::assertion::AssertionTrait;
    use crate::cbor_types::String;
    use crate::hash_utils::{HashRange, HashRangeCborSerde};
    use crate::hashed_uri::HashedUri;
    use crate::word_array::hex::words_to_hex;
    use crate::word_array::{WordArray, WordArrayTrait};
    use super::{DataHash, DataHashCborSerde};

    #[test]
    fn test_data_hash_serialization() {
        let data_hash = DataHash {
            exclusions: Option::Some(
                array![
                    HashRange { start: 8192, length: 4096 },
                    HashRange { start: 16384, length: 4096 },
                ]
                    .span(),
            ),
            name: Option::Some(@"Some data"),
            alg: Option::Some(@"sha256"),
            hash: 0x7c3ec0db52c7035bfb5b264f5e22c9a4a604c84bbecf648c699c7fe57a1511e7_u256,
            pad: Default::default(),
            pad2: Option::None,
            url: Option::None,
        };

        let mut output: WordArray = Default::default();
        DataHashCborSerde::cbor_serialize(@data_hash, ref output);

        let res = words_to_hex(output.span());
        let expected: ByteArray =
            "a56a6578636c7573696f6e7382a2657374617274192000666c656e677468191000a2657374617274194000666c656e677468191000646e616d6569536f6d65206461746163616c6766736861323536646861736858207c3ec0db52c7035bfb5b264f5e22c9a4a604c84bbecf648c699c7fe57a1511e76370616440";
        assert_eq!(expected, res);
    }

    #[test]
    fn test_data_hash_assertion_link() {
        let data_hash = DataHash {
            exclusions: Option::Some(
                array![
                    HashRange { start: 8192, length: 4096 },
                    HashRange { start: 16384, length: 4096 },
                ]
                    .span(),
            ),
            name: Option::Some(@"Some data"),
            alg: Option::Some(@"sha256"),
            hash: 0x7c3ec0db52c7035bfb5b264f5e22c9a4a604c84bbecf648c699c7fe57a1511e7_u256,
            pad: Default::default(),
            pad2: Option::None,
            url: Option::None,
        };

        let alg: Option<String> = None;
        let hashed_uri = data_hash.to_hashed_uri(alg);
        let expected = HashedUri {
            url: @"self#jumbf=c2pa.assertions/c2pa.hash.data",
            alg,
            hash: 0xca33e9977d9b96809bc823c0456921d8df36df2cc98945aa8fecb549439c7d49_u256,
        };
        assert_eq!(hashed_uri, expected);
    }
}
