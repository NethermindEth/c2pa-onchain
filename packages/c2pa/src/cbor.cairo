use core::traits::DivRem;
use super::word_array::{WordArray, WordArrayTrait};

/// CBOR serialization trait
pub trait CborSerde<T> {
    fn cbor_serialize(self: @T, ref output: WordArray);
}

/// Helper function to serialize a field in a CBOR map
pub fn write_map_field<T, +CborSerde<T>>(key: ByteArray, value: @T, ref output: WordArray) {
    write_string_header(ref output, key.len());
    output.append_string(@key);
    CborSerde::cbor_serialize(value, ref output);
}

/// Helper function to serialize a field in a CBOR map if the value is Some
pub fn write_map_field_opt<T, +CborSerde<T>, +Drop<T>>(
    key: ByteArray, value: Option<T>, ref output: WordArray,
) {
    if let Option::Some(value) = value {
        write_map_field(key, @value, ref output);
    }
}

/// Helper function to write CBOR text string header
pub fn write_string_header(ref output: WordArray, length: usize) {
    write_u32(ref output, length.try_into().unwrap(), 0x60);
}

/// Helper function to write CBOR array header
pub fn write_array_header(ref output: WordArray, length: usize) {
    write_u32(ref output, length.try_into().unwrap(), 0x80);
}

/// Helper function to write CBOR byte string header
pub fn write_bytes_header(ref output: WordArray, length: usize) {
    write_u32(ref output, length.try_into().unwrap(), 0x40);
}

/// Helper function to write CBOR map header
pub fn write_map_header(ref output: WordArray, num_fields: usize) {
    write_u32(ref output, num_fields.try_into().unwrap(), 0xa0);
}

/// Helper function to write CBOR unsigned integer (up to 4 bytes)
pub fn write_u32(ref output: WordArray, value: u32, tag: u8) {
    if value <= 23 {
        output.append_u8(tag + value.try_into().unwrap()); // Single byte
    } else if value <= 255 {
        output.append_u8(tag + 0x18); // One byte
        output.append_u8(value.try_into().unwrap());
    } else if value <= 65535 {
        output.append_u8(tag + 0x19); // Two bytes 
        let (hi, lo) = DivRem::div_rem(value, 0x100);
        output.append_word(hi * 0x100 + lo, 2); // Big-endian
    } else {
        output.append_u8(tag + 0x1a); // Four bytes
        output.append_u32_be(value);
    }
}
