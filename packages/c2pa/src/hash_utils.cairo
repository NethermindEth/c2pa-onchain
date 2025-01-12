use super::word_array::WordArrayTrait;
use crate::cbor::{CborSerde, write_map_header, write_map_field};
use crate::cbor_types::{U32CborSerde, String, Digest};
use crate::word_array::WordArray;
use core::sha256::compute_sha256_u32_array;

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

pub trait Hashable<T> {
    fn hash(self: @T, alg: Option<String>) -> Digest;
}

impl CborHashable<T, +Drop<T>, +CborSerde<T>> of Hashable<T> {
    fn hash(self: @T, alg: Option<String>) -> Digest {
        let mut output: WordArray = Default::default();
        self.cbor_serialize(ref output);
        hash_by_alg(output, alg)
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
    };

    let (input, last_input_word, last_input_num_bytes) = data.into_components();
    let hash = compute_sha256_u32_array(input, last_input_word, last_input_num_bytes);
    digest_from_words(hash)
}

fn digest_from_words(words: [u32; 8]) -> Digest {
    let [a, b, c, d, e, f, g, h] = words;
    let high: u128 = a.into() * 0x100000000 + b.into() * 0x10000 + c.into() * 0x100 + d.into();
    let low: u128 = e.into() * 0x100000000 + f.into() * 0x10000 + g.into() * 0x100 + h.into();
    u256 { high, low }
}
