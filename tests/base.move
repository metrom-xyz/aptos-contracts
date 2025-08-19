#[test_only]
module metrom::test_token {
    use std::string::{Self, String};
    use std::option;
    use std::signer;

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
        let symbol_bytes = *symbol.bytes();

        let token_address =
            object::create_object_address(&signer::address_of(caller), symbol_bytes);
        if (object::is_object(token_address)) {
            return object::address_to_object<Metadata>(token_address);
        };

        let constructor_ref = object::create_named_object(caller, symbol_bytes);

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

    public fun balance_of(asset: Object<Metadata>, account: address): u64 {
        primary_fungible_store::balance(account, asset)
    }

    public fun asset_address(asset: Object<Metadata>): address {
        object::object_address(&asset)
    }

    public fun get_asset(token: address): Object<Metadata> {
        object::address_to_object<Metadata>(token)
    }
}

#[test_only]
module metrom::tests_base {
    use std::timestamp;
    use std::vector;
    use std::signer;
    use std::string;
    use std::option::{Self, Option};

    use aptos_framework::bcs;

    use metrom::test_token;
    use metrom::metrom::{Self};

    public fun init(aptos: &signer) {
        timestamp::set_time_has_started_for_testing(aptos);
    }

    public fun init_metrom_with_defaults(metrom: &signer, owner: &signer) {
        init_metrom(metrom, owner, owner, 10_000, 1, 3600 * 2);
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
        metrom::set_minimum_token_rates(
            updater,
            vector[token],
            vector[rate],
            vector[],
            vector[]
        );
        assert!(metrom::minimum_reward_token_rate(token) == rate);
    }

    public fun set_minimum_fee_rate(
        updater: &signer, token: address, rate: u64
    ) {
        metrom::set_minimum_token_rates(
            updater,
            vector[],
            vector[],
            vector[token],
            vector[rate]
        );
        assert!(metrom::minimum_fee_token_rate(token) == rate);
    }

    public fun create_rewards_campaign(
        caller: &signer,
        updater: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        reward_amounts: vector<u64>
    ): (vector<u8>, vector<address>) {
        let reward_token_addresses = vector::empty();
        for (i in 0..reward_amounts.length()) {
            let bytes_i = vector::empty();
            bytes_i.push_back(i as u8);

            let reward_token =
                test_token::initialize(
                    caller,
                    string::utf8(bytes_i),
                    string::utf8(bytes_i),
                    8
                );
            let reward_token_address = test_token::asset_address(reward_token);
            reward_token_addresses.push_back(reward_token_address);

            set_minimum_reward_rate(updater, reward_token_address, 1);

            test_token::mint_to(
                reward_token,
                signer::address_of(caller),
                reward_amounts[i]
            );
        };

        metrom::create_rewards_campaign(
            caller,
            from,
            to,
            kind,
            data,
            specification_hash,
            reward_token_addresses,
            reward_amounts
        );

        (
            metrom::rewards_campaign_id(
                signer::address_of(caller),
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_token_addresses,
                reward_amounts

            ),
            reward_token_addresses
        )
    }

    public fun create_default_rewards_campaign(
        caller: &signer, updater: &signer
    ): (vector<u8>, address) {
        let (campaign_id, reward_token_addresses) =
            create_rewards_campaign(
                caller,
                updater,
                timestamp::now_seconds() + 10,
                timestamp::now_seconds() + 20,
                1,
                bcs::to_bytes(&@0x01),
                option::none(),
                vector[octas(100)]
            );

        (campaign_id, reward_token_addresses[0])
    }

    public fun create_points_campaign(
        caller: &signer,
        updater: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64
    ): (vector<u8>, address) {
        let fee_token =
            test_token::initialize(
                caller,
                string::utf8(b"TST"),
                string::utf8(b"Test token"),
                18
            );
        test_token::mint_to(
            fee_token,
            signer::address_of(caller),
            octas(1000)
        );
        let fee_token_address = test_token::asset_address(fee_token);
        set_minimum_fee_rate(updater, fee_token_address, octas(1));

        metrom::create_points_campaign(
            caller,
            from,
            to,
            kind,
            data,
            specification_hash,
            points,
            fee_token_address
        );

        (
            metrom::points_campaign_id(
                signer::address_of(caller),
                from,
                to,
                kind,
                data,
                specification_hash,
                points,
                fee_token_address
            ),
            fee_token_address
        )
    }

    public fun create_default_points_campaign(
        caller: &signer, updater: &signer
    ): (vector<u8>, address) {
        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let points = octas(100);

        create_points_campaign(
            caller,
            updater,
            from,
            to,
            kind,
            data,
            specification_hash,
            points
        )
    }

    public fun octas(amount: u64): u64 {
        amount * 100_000_000
    }
}
