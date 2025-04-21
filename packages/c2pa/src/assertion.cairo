use crate::cbor::CborSerde;
use crate::cbor_types::String;
use crate::hash_utils::hash_by_alg;
use crate::hashed_uri::HashedUri;
use crate::jumbf_box::{BMFFBoxTrait, CAICBORAssertionBox, CAICBORAssertionBoxTrait};
use crate::word_array::WordArray;

pub trait AssertionTrait<T, +Drop<T>, +CborSerde<T>> {
    /// Returns the assertion label
    fn assertion_label(self: @T) -> String;

    /// Returns the relative assertion link, as in hashed URI
    fn assertion_link(self: @T) -> String;

    /// Converts the assertion to a CAI CBOR assertion box
    fn to_assertion_box(
        self: @T,
    ) -> CAICBORAssertionBox {
        let mut output: WordArray = Default::default();
        self.cbor_serialize(ref output);
        // TODO: handle the case where there are multiple assertions of the same type
        // hence the label is not unique and should include an index
        CAICBORAssertionBoxTrait::new(Self::assertion_label(self), output)
    }

    /// Returns the assertion hash
    fn to_hashed_uri(
        self: @T, alg: Option<String>,
    ) -> HashedUri {
        let assertion_box = Self::to_assertion_box(self);

        let mut box_payload: WordArray = Default::default();
        assertion_box.write_box_payload(ref box_payload);

        HashedUri { url: Self::assertion_link(self), hash: hash_by_alg(box_payload, alg), alg }
    }
}
