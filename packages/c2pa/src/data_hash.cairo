use crate::cbor_types::{
    String, Bytes, Digest, SnapSerde, OptionCborSerde, SpanCborSerde, BytesCborSerde, SnapCborSerde,
    DigestCborSerde,
};
use crate::cbor::{CborSerde, write_map_header, write_map_field, write_map_field_opt};
use crate::word_array::WordArray;
use crate::hash_utils::{HashRange, HashRangeCborSerde};

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
