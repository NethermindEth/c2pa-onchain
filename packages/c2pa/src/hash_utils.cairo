use core::sha256::compute_sha256_u32_array;
use crate::cbor::{CborSerde, write_map_field, write_map_header};
use crate::cbor_types::{Digest, String, U32CborSerde};
use crate::word_array::WordArray;
use super::word_array::WordArrayTrait;

const TWO_POW_32: u128 = 0x100000000_u128;
const TWO_POW_64: u128 = 0x10000000000000000_u128;
const TWO_POW_96: u128 = 0x1000000000000000000000000_u128;

#[derive(Drop, Copy, Debug, Serde)]
pub struct HashRange {
    pub start: usize,
    pub length: usize,
}

pub impl HashRangeCborSerde of CborSerde<HashRange> {
    fn cbor_serialize(self: @HashRange, ref output: WordArray) {
        write_map_header(ref output, 2);
        write_map_field("start", self.start, ref output);
        write_map_field("length", self.length, ref output);
    }
}

pub fn hash_by_alg(data: WordArray, alg: Option<String>) -> Digest {
    match alg {
        Option::Some(alg) => {
            if alg != @"sha256" {
                panic!("Unsupported hash algorithm: {}", alg);
            }
        },
        Option::None => {},
    }

    let (input, last_input_word, last_input_num_bytes) = data.into_components();
    let hash = compute_sha256_u32_array(input, last_input_word, last_input_num_bytes);
    digest_from_words(hash)
}

fn digest_from_words(words: [u32; 8]) -> Digest {
    let [a, b, c, d, e, f, g, h] = words;
    let high: u128 = a.into() * TWO_POW_96
        + b.into() * TWO_POW_64
        + c.into() * TWO_POW_32
        + d.into();
    let low: u128 = e.into() * TWO_POW_96
        + f.into() * TWO_POW_64
        + g.into() * TWO_POW_32
        + h.into();
    u256 { high, low }
}

#[cfg(test)]
mod tests {
    use crate::word_array::hex::words_from_hex;
    use super::*;

    #[test]
    fn test_hash_by_alg() {
        let data = words_from_hex("");
        let hash = hash_by_alg(data, Option::Some(@"sha256"));
        assert_eq!(hash, 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855);
    }
}
