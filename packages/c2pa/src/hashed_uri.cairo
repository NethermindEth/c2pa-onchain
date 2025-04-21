use crate::cbor::{CborSerde, write_map_field, write_map_field_opt, write_map_header};
use crate::cbor_types::{Digest, DigestCborSerde, SnapCborSerde, SnapSerde, String, StringCborSerde};
use crate::word_array::WordArray;

#[derive(Drop, Copy, Debug, Serde, PartialEq)]
pub struct HashedUri {
    /// URI stored as tagged CBOR
    pub url: String,
    /// Hashing algorithm, SHA256 by default
    pub alg: Option<String>,
    /// Hash stored as CBOR byte string
    pub hash: Digest,
}

/// CBOR serialization implementation for HashedUri
impl HashedUriCborSerde of CborSerde<HashedUri> {
    fn cbor_serialize(self: @HashedUri, ref output: WordArray) {
        let mut num_fields = 2;
        if self.alg.is_some() {
            num_fields += 1; // #[serde(skip_serializing_if = "Option::is_none")]
        }
        write_map_header(ref output, num_fields);
        write_map_field("url", *self.url, ref output);
        write_map_field_opt("alg", *self.alg, ref output);
        write_map_field("hash", self.hash, ref output);
    }
}
