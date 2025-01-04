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
        output.append_u8(0xa6);

        ByteArrayCborSerde::cbor_serialize(@"title", ref output);
        match *self.title {
            Option::Some(title) => ByteArrayCborSerde::cbor_serialize(title, ref output),
            Option::None => output.append_u8(0xf6),
        }

        ByteArrayCborSerde::cbor_serialize(@"format", ref output);
        ByteArrayCborSerde::cbor_serialize(*self.format, ref output);

        ByteArrayCborSerde::cbor_serialize(@"instance_id", ref output);
        ByteArrayCborSerde::cbor_serialize(*self.instance_id, ref output);

        ByteArrayCborSerde::cbor_serialize(@"claim_generator", ref output);
        ByteArrayCborSerde::cbor_serialize(*self.claim_generator, ref output);

        ByteArrayCborSerde::cbor_serialize(@"signature", ref output);
        ByteArrayCborSerde::cbor_serialize(*self.signature, ref output);

        ByteArrayCborSerde::cbor_serialize(@"assertions", ref output);
        (*self.assertions).cbor_serialize(ref output);
    }
}

/// CBOR serialization implementation for HashedUri
impl HashedUriCborSerde of CborSerde<HashedUri> {
    fn cbor_serialize(self: @HashedUri, ref output: WordArray) {
        output.append_u8(0xa2);

        ByteArrayCborSerde::cbor_serialize(@"url", ref output);
        ByteArrayCborSerde::cbor_serialize(*self.url, ref output);

        ByteArrayCborSerde::cbor_serialize(@"hash", ref output);
        (*self.hash).cbor_serialize(ref output);
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


/// CBOR serialization implementation for ByteArray
impl ByteArrayCborSerde of CborSerde<ByteArray> {
    fn cbor_serialize(self: @ByteArray, ref output: WordArray) {
        write_text_header(ref output, self.len());
        output.append_string(self);
    }
}

/// CBOR serialization implementation for u256
impl U256CborSerde of CborSerde<u256> {
    fn cbor_serialize(self: @u256, ref output: WordArray) {
        // A u256 is 32 bytes
        write_bytes_header(ref output, 32);
        // Write high 128 bits
        output.append_word((*self.high).try_into().unwrap(), 16);
        // Write low 128 bits
        output.append_word((*self.low).try_into().unwrap(), 16);
    }
}

/// CBOR serialization implementation for Span<T>
impl SpanCborSerde<T, impl TCborSerde: CborSerde<T>, impl TDrop: Drop<T>, impl TCopy: Copy<T>> 
    of CborSerde<Span<T>> {
    fn cbor_serialize(self: @Span<T>, ref output: WordArray) {
        write_array_header(ref output, (*self).len());
        for item in *self {
            CborSerde::cbor_serialize(item, ref output);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{ClaimCborSerde, HashedUriCborSerde};
    use crate::claim::{Claim, HashedUri};
    use crate::word_array::{WordArray, WordArrayTrait};
    use crate::word_array::hex::words_to_hex;

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
