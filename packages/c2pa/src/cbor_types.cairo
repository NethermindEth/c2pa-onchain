use core::fmt::Debug;
use crate::hex::{bytes_from_hex, bytes_to_hex};
use crate::cbor::{
    CborSerde, write_string_header, write_array_header, write_bytes_header, write_u32,
};
use crate::word_array::{WordArray, WordArrayTrait};

/// Type alias for ascii string
pub type String = @ByteArray;

/// Type alias for raw bytes
pub type Bytes = @ByteBuffer;

/// Type alias for hash digest
pub type Digest = u256;

/// Newtype wrapper for ByteArray
#[derive(Drop, Serde, PartialEq)]
pub struct ByteBuffer {
    pub data: ByteArray,
}

#[generate_trait]
pub impl BytesImpl of BytesTrait {
    fn from_hex(hex: ByteArray) -> Bytes {
        @ByteBuffer { data: bytes_from_hex(hex) }
    }

    fn to_hex(self: Bytes) -> ByteArray {
        bytes_to_hex(self.data)
    }
}

pub impl BytesDebug of Debug<ByteBuffer> {
    fn fmt(self: Bytes, ref f: core::fmt::Formatter) -> Result<(), core::fmt::Error> {
        f.buffer.append(@self.to_hex());
        Result::Ok(())
    }
}

/// `Serde` trait implementation for `ByteArray`.
pub impl SnapSerde<T, +Serde<T>, +Drop<T>> of Serde<@T> {
    fn serialize(self: @@T, ref output: Array<felt252>) {
        (*self).serialize(ref output);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<@T> {
        match Serde::deserialize(ref serialized) {
            Option::Some(res) => Option::Some(@res),
            Option::None => Option::None,
        }
    }
}

/// CBOR serialization implementation for String
pub impl StringCborSerde of CborSerde<ByteArray> {
    fn cbor_serialize(self: String, ref output: WordArray) {
        write_string_header(ref output, self.len());
        output.append_string(self);
    }
}

/// CBOR serialization implementation for Bytes
pub impl BytesCborSerde of CborSerde<ByteBuffer> {
    fn cbor_serialize(self: Bytes, ref output: WordArray) {
        write_bytes_header(ref output, self.data.len());
        output.append_string(self.data);
    }
}

/// CBOR serialization implementation for Digest
pub impl DigestCborSerde of CborSerde<Digest> {
    fn cbor_serialize(self: @Digest, ref output: WordArray) {
        // A u256 is 32 bytes
        write_bytes_header(ref output, 32);
        // Write high 128 bits
        output.append_word((*self.high).try_into().unwrap(), 16);
        // Write low 128 bits
        output.append_word((*self.low).try_into().unwrap(), 16);
    }
}

/// CBOR serialization implementation for Span<T>
pub impl SpanCborSerde<T, +CborSerde<T>, +Drop<T>, +Copy<T>> of CborSerde<Span<T>> {
    fn cbor_serialize(self: @Span<T>, ref output: WordArray) {
        write_array_header(ref output, (*self).len());
        for item in *self {
            CborSerde::cbor_serialize(item, ref output);
        }
    }
}

/// CBOR serialization implementation for Option<T>
pub impl OptionCborSerde<T, +CborSerde<T>> of CborSerde<Option<T>> {
    fn cbor_serialize(self: @Option<T>, ref output: WordArray) {
        if let Option::Some(value) = self {
            CborSerde::cbor_serialize(value, ref output);
        } else {
            output.append_u8(0xf6);
        }
    }
}

/// CBOR serialization implementation for @T
pub impl SnapCborSerde<T, +CborSerde<T>> of CborSerde<@T> {
    fn cbor_serialize(self: @@T, ref output: WordArray) {
        CborSerde::cbor_serialize(*self, ref output);
    }
}

/// CBOR serialization implementation for u32
pub impl U32CborSerde of CborSerde<usize> {
    fn cbor_serialize(self: @u32, ref output: WordArray) {
        write_u32(ref output, *self, 0x00);
    }
}

/// CBOR serialization implementation for ()
pub impl UnitCborSerde of CborSerde<()> {
    fn cbor_serialize(self: @(), ref output: WordArray) {
        panic!("unsupported");
    }
}
