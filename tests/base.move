#[test_only]
module metrom::test_token {
    use std::string::{Self, String};
    use std::option;

    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef, TransferRef};
    use aptos_framework::primary_fungible_store;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Refs has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef
    }

    public fun initialize(
        caller: &signer,
        symbol: String,
        name: String,
        decimals: u8
    ): Object<Metadata> {
        let constructor_ref = object::create_named_object(caller, *symbol.bytes());

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            name,
            symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b"")
        );

        let mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(&constructor_ref);

        let obj_signer = object::generate_signer(&constructor_ref);

        move_to(&obj_signer, Refs { mint_ref, transfer_ref });

        object::object_from_constructor_ref(&constructor_ref)
    }

    public fun mint_to(
        asset: Object<Metadata>, recipient: address, amount: u64
    ) acquires Refs {
        let store = primary_fungible_store::ensure_primary_store_exists(
            recipient, asset
        );
        let refs = borrow_global<Refs>(asset_address(asset));
        fungible_asset::mint_to(&refs.mint_ref, store, amount);
    }

    public fun asset_address(asset: Object<Metadata>): address {
        object::object_address(&asset)
    }
}

#[test_only]
module metrom::tests_base {
    use std::timestamp;
    use std::vector;
    use std::signer;
    use std::string;

    use aptos_framework::bcs;

    use metrom::test_token;
    use metrom::metrom::{Self};

    public fun init(aptos: &signer) {
        timestamp::set_time_has_started_for_testing(aptos);
    }

    public fun init_metrom_with_defaults(metrom: &signer, owner: &signer) {
        init_metrom(metrom, owner, owner, 10_000, 1, 100);
    }

    public fun init_metrom(
        metrom: &signer,
        owner: &signer,
        updater: &signer,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    ) {
        metrom::test_init_module(metrom);
        metrom::init_state(
            metrom,
            signer::address_of(owner),
            signer::address_of(updater),
            fee,
            minimum_campaign_duration,
            maximum_campaign_duration
        );
    }

    public fun set_minimum_reward_rate(
        updater: &signer, token: address, rate: u64
    ) {
        assert!(metrom::minimum_reward_token_rate(token) != rate);
        metrom::set_minimum_reward_token_rate(updater, token, rate);
        assert!(metrom::minimum_reward_token_rate(token) == rate);
    }

    public fun set_minimum_fee_rate(
        updater: &signer, token: address, rate: u64
    ) {
        assert!(metrom::minimum_fee_token_rate(token) != rate);
        metrom::set_minimum_fee_token_rate(updater, token, rate);
        assert!(metrom::minimum_fee_token_rate(token) == rate);
    }

    public fun create_default_rewards_campaign(
        caller: &signer, updater: &signer
    ): (vector<u8>, address) {
        let reward_token =
            test_token::initialize(
                caller,
                string::utf8(b"TST"),
                string::utf8(b"Test token"),
                18
            );
        let reward_token_address = test_token::asset_address(reward_token);
        set_minimum_reward_rate(updater, reward_token_address, 1);

        let reward_amount = octas(100);
        test_token::mint_to(reward_token, signer::address_of(caller), reward_amount);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = vector::empty();

        let reward_tokens = vector::empty();
        reward_tokens.push_back(reward_token_address);

        let reward_amounts = vector::empty();
        reward_amounts.push_back(reward_amount);

        metrom::create_reward_campaign(
            caller,
            from,
            to,
            kind,
            data,
            specification_hash,
            reward_tokens,
            reward_amounts
        );

        (
            metrom::rewards_campaign_id(
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_tokens,
                reward_amounts

            ),
            reward_token_address
        )
    }

    public fun create_default_points_campaign(
        caller: &signer, updater: &signer
    ): (vector<u8>, address) {
        let fee_token =
            test_token::initialize(
                caller,
                string::utf8(b"TST"),
                string::utf8(b"Test token"),
                18
            );
        let fee_token_address = test_token::asset_address(fee_token);
        set_minimum_fee_rate(updater, fee_token_address, 1);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = vector::empty();
        let points = octas(100);
        let fee_token = fee_token_address;

        metrom::create_points_campaign(
            caller,
            from,
            to,
            kind,
            data,
            specification_hash,
            points,
            fee_token
        );

        (
            metrom::points_campaign_id(
                from,
                to,
                kind,
                data,
                specification_hash,
                points,
                fee_token
            ),
            fee_token
        )
    }

    public fun octas(amount: u64): u64 {
        amount * 100_000_000
    }
}
