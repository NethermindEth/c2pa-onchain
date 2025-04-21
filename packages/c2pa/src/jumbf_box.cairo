use crate::cbor_types::{Digest, String};
use crate::word_array::{WordArray, WordArrayTrait};

pub const CAI_CBOR_ASSERTION_UUID: u128 = 0x63626F7200110010800000AA00389B71;
pub const JUMB_FOURCC: u32 = 0x6a756d62; // b"jumb"
pub const JUMD_FOURCC: u32 = 0x6a756d64; // b"jumd"
pub const CBOR_FOURCC: u32 = 0x63626f72; // b"cbor"

#[derive(Drop)]
pub struct CAICBORAssertionBox {
    pub description: JUMBFDescriptionBox,
    pub content: JUMBFCBORContentBox,
}

#[derive(Drop)]
pub struct JUMBFDescriptionBox {
    /// A 128-bit UUID for the type
    pub box_uuid: u128,
    /// Bit field for valid values
    pub toggles: u8,
    /// UTF-8 string (OPTIONAL)
    /// A terminating null will be added upon serialization
    pub label: Option<String>,
    /// User assigned value (OPTIONAL)
    pub box_id: Option<u32>,
    /// SHA-256 hash of the payload (OPTIONAL)
    pub signature: Option<Digest>,
    /// Private salt content box (OPTIONAL) — not supported
}

#[derive(Drop)]
pub struct JUMBFCBORContentBox {
    /// CBOR encoded content
    pub cbor: WordArray,
}

#[generate_trait]
pub impl CAICBORAssertionBoxImpl of CAICBORAssertionBoxTrait {
    fn new(label: String, cbor: WordArray) -> CAICBORAssertionBox {
        CAICBORAssertionBox {
            description: JUMBFDescriptionBoxTrait::new(CAI_CBOR_ASSERTION_UUID, Some(label)),
            content: JUMBFCBORContentBox { cbor },
        }
    }
}

#[generate_trait]
pub impl JUMBFDescriptionBoxImpl of JUMBFDescriptionBoxTrait {
    fn new(box_uuid: u128, label: Option<String>) -> JUMBFDescriptionBox {
        JUMBFDescriptionBox {
            box_uuid,
            toggles: 3, // 0x11 (Requestable + Label Present)
            label,
            box_id: None,
            signature: None,
        }
    }
}

pub trait BMFFBoxTrait<T> {
    fn box_type(self: @T) -> u32;
    fn write_box_payload(self: @T, ref output: WordArray);

    fn write_box(
        self: @T, ref output: WordArray,
    ) {
        let mut payload: WordArray = Default::default();
        Self::write_box_payload(self, ref payload);
        // Ignore the case when box_type is b"    "
        let box_size = payload.byte_len() + 8;
        output.append_u32_be(box_size);
        output.append_u32_be(Self::box_type(self));
        output.extend(payload.span());
    }
}

impl CAICBORAssertionBoxBMFFImpl of BMFFBoxTrait<CAICBORAssertionBox> {
    fn box_type(self: @CAICBORAssertionBox) -> u32 {
        JUMB_FOURCC
    }

    fn write_box_payload(self: @CAICBORAssertionBox, ref output: WordArray) {
        self.description.write_box(ref output);
        self.content.write_box(ref output);
    }
}

impl JUMBFDescriptionBoxBMFFImpl of BMFFBoxTrait<JUMBFDescriptionBox> {
    fn box_type(self: @JUMBFDescriptionBox) -> u32 {
        JUMD_FOURCC
    }

    fn write_box_payload(self: @JUMBFDescriptionBox, ref output: WordArray) {
        output.append_u128_be(*self.box_uuid);
        output.append_u8(*self.toggles);

        if let Option::Some(label) = self.label {
            output.append_string(*label);
            output.append_u8(0); // Null terminator
        }

        if let Option::Some(box_id) = self.box_id {
            output.append_u32_be(*box_id);
        }

        if let Option::Some(signature) = self.signature {
            output.append_u256_be(*signature);
        }
    }
}

impl JUMBFCBORContentBoxBMFFImpl of BMFFBoxTrait<JUMBFCBORContentBox> {
    fn box_type(self: @JUMBFCBORContentBox) -> u32 {
        CBOR_FOURCC
    }

    fn write_box_payload(self: @JUMBFCBORContentBox, ref output: WordArray) {
        output.extend(self.cbor.span());
    }
}

#[cfg(test)]
mod tests {
    use crate::word_array::hex::{words_from_hex, words_to_hex};
    use super::*;

    #[test]
    fn test_caicbor_assertion_box() {
        let cbor = words_from_hex(
            "a56a6578636c7573696f6e7381a265737461727414666c656e677468183e646e616d656e6a756d6266206d616e696665737463616c6766736861323536646861736858200000000000000000000000000000000000000000000000000000000000000000637061644a00000000000000000000",
        );
        let box = CAICBORAssertionBoxTrait::new(@"c2pa.hash.data", cbor);

        let mut output: WordArray = Default::default();
        box.write_box_payload(ref output);

        let result = words_to_hex(output.span());
        let expected =
            "000000286a756d6463626f7200110010800000aa00389b7103633270612e686173682e64617461000000007b63626f72a56a6578636c7573696f6e7381a265737461727414666c656e677468183e646e616d656e6a756d6266206d616e696665737463616c6766736861323536646861736858200000000000000000000000000000000000000000000000000000000000000000637061644a00000000000000000000";
        assert_eq!(result, expected);
    }
}
