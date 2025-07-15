#[test_only]
module metrom::create_rewards_campaign_tests {
    use std::timestamp;
    use std::option;
    use std::signer;
    use std::string;

    use aptos_framework::bcs;

    use metrom::metrom::{
        Self,
        ENoRewards,
        ETooManyRewards,
        EAlreadyExists,
        EInvalidHash,
        EInvalidStartTime,
        EInvalidDuration,
        ENoRewardAmount,
        EDisallowedRewardToken,
        ERewardAmountTooLow,
        EZeroAddressRewardToken
    };
    use metrom::tests_base;
    use metrom::test_token;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ENoRewards)]
    fun fail_no_rewards(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            specification_hash,
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ETooManyRewards)]
    fun fail_too_many_rewards(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[10, 10, 10, 10, 10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            specification_hash,
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EAlreadyExists)]
    fun fail_already_exists(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        tests_base::create_default_rewards_campaign(owner, owner);
        tests_base::create_default_rewards_campaign(owner, owner);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidHash)]
    fun fail_invalid_specification_hash_length(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let reward_amounts = vector[10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::some(vector[0u8]),
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidHash)]
    fun fail_invalid_specification_hash_zero_bytes(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let reward_amounts = vector[10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::some(
                x"0000000000000000000000000000000000000000000000000000000000000000"
            ),
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidStartTime)]
    fun fail_invalid_start_time(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = 0;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let reward_amounts = vector[10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidDuration)]
    fun fail_invalid_minimum_duration(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        metrom::set_minimum_campaign_duration(owner, 10);

        let from = timestamp::now_seconds() + 10;
        let to = from + 5;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let reward_amounts = vector[10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidDuration)]
    fun fail_invalid_maximum_duration(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        metrom::set_maximum_campaign_duration(owner, 10);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let reward_amounts = vector[10, 10];

        tests_base::create_rewards_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            reward_amounts
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EZeroAddressRewardToken)]
    fun fail_invalid_zero_address_reward(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        metrom::create_rewards_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            vector[@0x0],
            vector[1]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ENoRewardAmount)]
    fun fail_invalid_zero_reward_amount(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        metrom::create_rewards_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            vector[@0x1],
            vector[0]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EDisallowedRewardToken)]
    fun fail_disallowed_reward_token(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        metrom::create_rewards_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            vector[@0x1],
            vector[tests_base::octas(10)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ERewardAmountTooLow)]
    fun fail_reward_amount_too_low_single(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        tests_base::set_minimum_reward_rate(owner, @0x1, tests_base::octas(10));

        let from = timestamp::now_seconds() + 10;
        let to = from + 3600;

        metrom::create_rewards_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            vector[@0x1],
            vector[1]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ERewardAmountTooLow)]
    fun fail_reward_amount_too_low_multiple(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let reward_token_1 =
            test_token::initialize(
                owner,
                string::utf8(b"TEST1"),
                string::utf8(b"Test 1"),
                8
            );
        test_token::mint_to(
            reward_token_1,
            signer::address_of(owner),
            tests_base::octas(10)
        );
        let reward_token_1_address = test_token::asset_address(reward_token_1);
        tests_base::set_minimum_reward_rate(
            owner, reward_token_1_address, tests_base::octas(10)
        );

        let reward_token_2 =
            test_token::initialize(
                owner,
                string::utf8(b"TEST2"),
                string::utf8(b"Test 2"),
                8
            );
        let reward_token_2_address = test_token::asset_address(reward_token_2);
        tests_base::set_minimum_reward_rate(
            owner, test_token::asset_address(reward_token_2), tests_base::octas(100)
        );

        let from = timestamp::now_seconds() + 10;
        let to = from + 3600;

        metrom::create_rewards_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            vector[reward_token_1_address, reward_token_2_address],
            vector[tests_base::octas(10), tests_base::octas(10)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_single_rewards(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(100)];

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(99)],
            vector[tests_base::octas(1)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_single_rewards_50_pc_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(200)];

        // 50% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 500_000);

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(199)],
            vector[tests_base::octas(1)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_single_rewards_full_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(200)];

        // 100% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 1_000_000);

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(200)],
            vector[0]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_multiple_rewards(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(100), tests_base::octas(1000)];

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(99), tests_base::octas(990)],
            vector[tests_base::octas(1), tests_base::octas(10)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_multiple_rewards_50_pc_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(200), tests_base::octas(2000)];

        // 50% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 500_000);

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(199), tests_base::octas(1990)],
            vector[tests_base::octas(1), tests_base::octas(10)]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_multiple_rewards_full_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();
        let reward_amounts = vector[tests_base::octas(200), tests_base::octas(2000)];

        // 100% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 1_000_000);

        let (campaign_id, reward_token_addresses) =
            tests_base::create_rewards_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_amounts
            );

        metrom::assert_rewards_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            option::none(),
            reward_token_addresses,
            vector[tests_base::octas(200), tests_base::octas(2000)],
            vector[0, 0]
        );
    }
}
