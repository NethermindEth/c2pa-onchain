use c2pa::claim::Claim;
use c2pa::data_hash::DataHash;
use c2pa::cbor_types::Digest;

#[starknet::interface]
trait IClaimRegistry<TContractState> {
    fn verify_and_register_claim(
        ref self: TContractState, provenance_claim: Claim, data_hash_assertion: DataHash, signature: u256,
    ) -> bool;
    fn get_claim_hash(self: @TContractState, data_hash: Digest) -> Option<Digest>;
}

#[starknet::contract]
mod ClaimRegistry {
    use super::{Claim, DataHash, Digest};
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
    };

    #[storage]
    struct Storage {
        claims: Map<Digest, Digest>,
    }

    #[abi(embed_v0)]
    impl ClaimRegistryImpl of super::IClaimRegistry<ContractState> {
        fn verify_and_register_claim(
            ref self: ContractState, provenance_claim: Claim, data_hash_assertion: DataHash, signature: u256,
        ) -> bool {
            self.claims.entry(data_hash_assertion.hash).write(0);
            true
        }

        fn get_claim_hash(self: @ContractState, data_hash: Digest) -> Option<Digest> {
            let claim = self.claims.entry(data_hash).read();
            Option::Some(claim)
        }
    }
}
