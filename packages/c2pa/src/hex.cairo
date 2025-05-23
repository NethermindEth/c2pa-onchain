/// Gets bytes from hex.
pub fn bytes_from_hex(hex_string: ByteArray) -> ByteArray {
    let num_characters = hex_string.len();
    assert!(num_characters & 1 == 0, "Invalid hex string length");

    let mut bytes: ByteArray = Default::default();
    let mut i = 0;

    while i != num_characters {
        let hi = hex_char_to_nibble(hex_string[i]);
        let lo = hex_char_to_nibble(hex_string[i + 1]);
        bytes.append_byte(hi * 16 + lo);
        i += 2;
    }

    bytes
}

fn hex_char_to_nibble(hex_char: u8) -> u8 {
    if hex_char >= 48 && hex_char <= 57 {
        // 0-9
        hex_char - 48
    } else if hex_char >= 65 && hex_char <= 70 {
        // A-F
        hex_char - 55
    } else if hex_char >= 97 && hex_char <= 102 {
        // a-f
        hex_char - 87
    } else {
        panic!("Invalid hex character: {hex_char}");
        0
    }
}

/// Converts bytes to hex.
pub fn bytes_to_hex(data: @ByteArray) -> ByteArray {
    let alphabet: @ByteArray = @"0123456789abcdef";
    let mut result: ByteArray = Default::default();

    let mut i = 0;
    while i != data.len() {
        let value: u32 = data[i].into();
        let (l, r) = core::traits::DivRem::div_rem(value, 16);
        result.append_byte(alphabet.at(l).unwrap());
        result.append_byte(alphabet.at(r).unwrap());
        i += 1;
    }

    result
}

#[cfg(test)]
mod tests {
    use super::{bytes_from_hex, bytes_to_hex};

    #[test]
    fn test_bytes_from_hex() {
        assert_eq!("hello starknet", bytes_from_hex("68656c6c6f20737461726b6e6574"));
        assert_eq!("hello starknet", bytes_from_hex("68656C6C6F20737461726B6E6574"));
    }

    #[test]
    fn test_bytes_to_hex() {
        assert_eq!("68656c6c6f20737461726b6e6574", bytes_to_hex(@"hello starknet"));
    }
}
