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
        let mut num_fields = 6;
        if self.title.is_some() {
            num_fields += 1; // #[serde(skip_serializing_if = "Option::is_none")]
        }
        if self.alg.is_some() {
            num_fields += 1; // #[serde(skip_serializing_if = "Option::is_none")]
        }
        write_map_header(ref output, num_fields);

        if let Option::Some(title) = *self.title {
            StringCborSerde::cbor_serialize(@"dc:title", ref output);
            StringCborSerde::cbor_serialize(title, ref output);
        }

        StringCborSerde::cbor_serialize(@"dc:format", ref output);
        StringCborSerde::cbor_serialize(*self.format, ref output);

        StringCborSerde::cbor_serialize(@"instanceID", ref output);
        StringCborSerde::cbor_serialize(*self.instance_id, ref output);

        StringCborSerde::cbor_serialize(@"claim_generator", ref output);
        StringCborSerde::cbor_serialize(*self.claim_generator, ref output);

        StringCborSerde::cbor_serialize(@"claim_generator_info", ref output);
        match *self.claim_generator_info {
            Option::Some(_) => panic!("unsupported"),
            Option::None => output.append_u8(0xf6),
        };

        StringCborSerde::cbor_serialize(@"signature", ref output);
        StringCborSerde::cbor_serialize(*self.signature, ref output);

        StringCborSerde::cbor_serialize(@"assertions", ref output);
        (*self.assertions).cbor_serialize(ref output);

        if let Option::Some(alg) = *self.alg {
            StringCborSerde::cbor_serialize(@"alg", ref output);
            StringCborSerde::cbor_serialize(alg, ref output);
        }
    }
}

/// CBOR serialization implementation for HashedUri
impl HashedUriCborSerde of CborSerde<HashedUri> {
    fn cbor_serialize(self: @HashedUri, ref output: WordArray) {
        output.append_u8(0xa2);

        StringCborSerde::cbor_serialize(@"url", ref output);
        StringCborSerde::cbor_serialize(*self.url, ref output);

        StringCborSerde::cbor_serialize(@"hash", ref output);
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

/// Helper function to write CBOR map header
fn write_map_header(ref output: WordArray, num_fields: usize) {
    if num_fields <= 23 {
        output.append_u8(0xa0 + num_fields.try_into().unwrap()); // Single byte header
    } else if num_fields <= 255 {
        output.append_u8(0xb8); // One byte length
        output.append_u8(num_fields.try_into().unwrap());
    } else if num_fields <= 65535 {
        output.append_u8(0xb9); // Two bytes length
        let (hi, lo) = DivRem::div_rem(num_fields, 0x100);
        output.append_word(lo * 0x100 + hi, 2); // Little-endian length
    } else {
        output.append_u8(0xba); // Four bytes length
        output.append_u32_le(num_fields);
    }
}

/// CBOR serialization implementation for ByteArray
impl StringCborSerde of CborSerde<ByteArray> {
    fn cbor_serialize(self: @ByteArray, ref output: WordArray) {
        write_text_header(ref output, self.len());
        output.append_string(self);
    }
}

/// CBOR serialization implementation for u256
impl HashCborSerde of CborSerde<u256> {
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
impl SpanCborSerde<T, +CborSerde<T>, +Drop<T>, +Copy<T>> of CborSerde<Span<T>> {
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

    // #[test]
    // fn test_hashed_uri_serialization() {
    //     let hashed_uri = HashedUri {
    //         url: @"test_url",
    //         hash: 0x17aa0d46e266d6608dcd66d37ba1d843d1fc3063efaa632cbe88e6d4e1d1b3e0,
    //     };
    //     let mut output: WordArray = Default::default();
    //     HashedUriCborSerde::cbor_serialize(@hashed_uri, ref output);
    //     assert_eq!(
    //         "a2637572686874657374207572686468617368697465737420686173",
    //         words_to_hex(output.span()),
    //     );
    // }

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
            alg: Option::Some(@"sha256"),
        };

        let mut output: WordArray = Default::default();
        ClaimCborSerde::cbor_serialize(@claim, ref output);

        let res = words_to_hex(output.span());
        let expected: ByteArray =
            "a76964633a666f726d6174606a696e7374616e63654944606f636c61696d5f67656e657261746f726f61646f626520756e6974207465737474636c61696d5f67656e657261746f725f696e666ff6697369676e6174757265785373656c66236a756d62663d2f633270612f61646f62653a75726e3a757569643a37323164633530342d306565332d346631362d613261642d3762333335323233323163372f633270612e7369676e61747572656a617373657274696f6e738063616c6766736861323536";
        assert_eq!(expected, res);
    }
}
