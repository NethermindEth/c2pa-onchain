use core::traits::DivRem;
use super::word_array::{WordArray, WordArrayTrait};
use super::claim::{Claim, HashedUri};

/// CBOR serialization trait
trait CborSerde<T> {
    fn cbor_serialize(self: @T, ref output: WordArray);
}

/// CBOR serialization implementation for Claim
impl ClaimCborSerde of CborSerde<Claim> {
    fn cbor_serialize(self: @Claim, ref output: WordArray) {
        // Start CBOR map with 6 items (fixed number of fields)
        output.append_u8(0xa6); // Map header with 6 items

        // Serialize title (optional string)
        output.append_u8(0x65); // text string of length 5
        output.append_string(@"title");
        match *self.title {
            Option::Some(title) => {
                write_text_header(ref output, title.len());
                output.append_string(title);
            },
            Option::None => {
                output.append_u8(0xf6); // null
            }
        }

        // Serialize format
        output.append_u8(0x66); // text string of length 6
        output.append_string(@"format");
        write_text_header(ref output, (*self.format).len());
        output.append_string(*self.format);

        // Serialize instance_id
        output.append_u8(0x6b); // text string of length 11
        output.append_string(@"instance_id");
        write_text_header(ref output, (*self.instance_id).len());
        output.append_string(*self.instance_id);

        // Serialize claim_generator
        output.append_u8(0x6f); // text string of length 15
        output.append_string(@"claim_generator");
        write_text_header(ref output, (*self.claim_generator).len());
        output.append_string(*self.claim_generator);

        // Serialize signature
        output.append_u8(0x69); // text string of length 9
        output.append_string(@"signature");
        write_text_header(ref output, (*self.signature).len());
        output.append_string(*self.signature);

        // Serialize assertions array
        output.append_u8(0x6a); // text string of length 10
        output.append_string(@"assertions");
        write_array_header(ref output, (*self.assertions).len());
        for assertion in *self
            .assertions {
                HashedUriCborSerde::cbor_serialize(assertion, ref output);
            }
    }
}

/// CBOR serialization implementation for HashedUri
impl HashedUriCborSerde of CborSerde<HashedUri> {
    fn cbor_serialize(self: @HashedUri, ref output: WordArray) {
        // Start CBOR map with 2 items
        output.append_u8(0xa2); // Map header with 2 items

        // Serialize url
        output.append_u8(0x63); // text string of length 3
        output.append_string(@"url");
        write_text_header(ref output, (*self.url).len());
        output.append_string(*self.url);

        // Serialize hash
        output.append_u8(0x64); // text string of length 4
        output.append_string(@"hash");
        write_u256(ref output, *self.hash);
    }
}

/// Helper function to write CBOR text string header
fn write_text_header(ref output: WordArray, length: usize) {
    if length <= 23 {
        output.append_u8(0x60 + length.try_into().unwrap()); // Single byte header
    } else if length <= 255 {
        output.append_u8(0x78); // One byte length
        output.append_u8(length.try_into().unwrap());
    } else if length <= 65535 {
        output.append_u8(0x79); // Two bytes length
        let (hi, lo) = DivRem::div_rem(length, 0x100);
        output.append_word(lo * 0x100 + hi, 2); // Little-endian length
    } else {
        output.append_u8(0x7a); // Four bytes length
        output.append_u32_le(length);
    }
}

/// Helper function to write CBOR array header
fn write_array_header(ref output: WordArray, length: usize) {
    if length <= 23 {
        output.append_u8(0x80 + length.try_into().unwrap()); // Single byte header
    } else if length <= 255 {
        output.append_u8(0x98); // One byte length
        output.append_u8(length.try_into().unwrap());
    } else if length <= 65535 {
        output.append_u8(0x99); // Two bytes length
        let (hi, lo) = DivRem::div_rem(length, 0x100);
        output.append_word(lo * 0x100 + hi, 2); // Little-endian length
    } else {
        output.append_u8(0x9a); // Four bytes length
        output.append_u32_le(length);
    }
}

/// Helper function to write CBOR byte string header
fn write_bytes_header(ref output: WordArray, length: usize) {
    if length <= 23 {
        output.append_u8(0x40 + length.try_into().unwrap()); // Single byte header
    } else if length <= 255 {
        output.append_u8(0x58); // One byte length
        output.append_u8(length.try_into().unwrap());
    } else if length <= 65535 {
        output.append_u8(0x59); // Two bytes length
        let (hi, lo) = DivRem::div_rem(length, 0x100);
        output.append_word(lo * 0x100 + hi, 2); // Little-endian length
    } else {
        output.append_u8(0x5a); // Four bytes length
        output.append_u32_le(length);
    }
}

/// Helper function to write CBOR u256 as bytes
fn write_u256(ref output: WordArray, value: u256) {
    // A u256 is 32 bytes
    write_bytes_header(ref output, 32);
    // Write high 128 bits
    output.append_word(value.high.try_into().unwrap(), 16);
    // Write low 128 bits
    output.append_word(value.low.try_into().unwrap(), 16);
}

#[cfg(test)]
mod tests {
    use super::{CborSerde, ClaimCborSerde, HashedUriCborSerde};
    use super::super::claim::{Claim, HashedUri};
    use super::super::word_array::{WordArray, WordArrayTrait};
    use super::super::word_array::hex::words_to_hex;

    #[test]
    fn test_hashed_uri_serialization() {
        let hashed_uri = HashedUri {
            url: @"test_url",
            hash: 0x17aa0d46e266d6608dcd66d37ba1d843d1fc3063efaa632cbe88e6d4e1d1b3e0,
        };
        let mut output: WordArray = Default::default();
        HashedUriCborSerde::cbor_serialize(@hashed_uri, ref output);
        assert_eq!(
            "a2637572686874657374207572686468617368697465737420686173", words_to_hex(output.span()),
        );
    }

    #[test]
    fn test_claim_serialization() {
        let claim = Claim {
            title: Option::Some(@"test_title"),
            format: @"test_format",
            instance_id: @"test_instance",
            claim_generator: @"test_generator",
            signature: @"test_signature",
            assertions: array![
                HashedUri {
                    url: @"test_url",
                    hash: 0x17aa0d46e266d6608dcd66d37ba1d843d1fc3063efaa632cbe88e6d4e1d1b3e0,
                }
            ]
                .span(),
        };
        let mut output: WordArray = Default::default();
        ClaimCborSerde::cbor_serialize(@claim, ref output);
        // TODO: Add assertion to verify the exact CBOR encoding
    }
}
