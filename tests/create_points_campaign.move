#[test_only]
module metrom::create_points_campaign_tests {
    use std::timestamp;
    use std::option;
    use std::signer;

    use aptos_framework::bcs;

    use metrom::metrom::{
        Self,
        ENoPoints,
        EAlreadyExists,
        EInvalidHash,
        EInvalidStartTime,
        EInvalidDuration,
        EZeroAddressFeeToken,
        EDisallowedFeeToken
    };
    use metrom::tests_base;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ENoPoints)]
    fun fail_no_points(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        tests_base::create_points_campaign(
            owner,
            owner,
            timestamp::now_seconds() + 10,
            timestamp::now_seconds() + 20,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            0
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EZeroAddressFeeToken)]
    fun fail_invalid_zero_address_fee_token(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        metrom::create_points_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            10,
            @0x0
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EAlreadyExists)]
    fun fail_already_exists(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        tests_base::create_default_points_campaign(owner, owner);
        tests_base::create_default_points_campaign(owner, owner);
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

        tests_base::create_points_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::some(x"00"),
            10
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

        tests_base::create_points_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::some(
                x"0000000000000000000000000000000000000000000000000000000000000000"
            ),
            10
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

        tests_base::create_points_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            10
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

        tests_base::create_points_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            10
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

        tests_base::create_points_campaign(
            owner,
            owner,
            from,
            to,
            kind,
            data,
            option::none(),
            10
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EDisallowedFeeToken)]
    fun fail_disallowed_fee_token(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 20;
        metrom::create_points_campaign(
            owner,
            from,
            to,
            1,
            bcs::to_bytes(&@0x01),
            option::none(),
            10,
            @0x1
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + 3600;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();

        let (campaign_id, fee_token_address) =
            tests_base::create_points_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                100
            );

        metrom::assert_points_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            100,
            fee_token_address,
            tests_base::octas(1)
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_50_pc_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = from + (3600 * 2);
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();

        // 50% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 500_000);

        let (campaign_id, fee_token_address) =
            tests_base::create_points_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                100
            );

        metrom::assert_points_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            100,
            fee_token_address,
            tests_base::octas(1)
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success_full_fee_rebate(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let from = timestamp::now_seconds() + 10;
        let to = timestamp::now_seconds() + 20;
        let kind = 1;
        let data = bcs::to_bytes(&@0x01);
        let specification_hash = option::none();

        // 100% rebate
        metrom::set_fee_rebate(owner, signer::address_of(owner), 1_000_000);

        let (campaign_id, fee_token_address) =
            tests_base::create_points_campaign(
                owner,
                owner,
                from,
                to,
                kind,
                data,
                specification_hash,
                100
            );

        metrom::assert_points_campaign_full(
            campaign_id,
            signer::address_of(owner),
            option::none(),
            from,
            to,
            kind,
            data,
            specification_hash,
            100,
            fee_token_address,
            0
        );
    }
}
