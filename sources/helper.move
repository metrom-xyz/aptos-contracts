module metrom::helper {
    use std::string::{String};

    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};

    #[view]
    public fun get_token_metadata(token: address): (u8, String, String) {
        let metadata = object::address_to_object<Metadata>(token);
        (
            fungible_asset::decimals(metadata),
            fungible_asset::symbol(metadata),
            fungible_asset::name(metadata)
        )
    }
}
