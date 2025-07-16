#[test_only]
module metrom::claim_rewards_tests {
    use metrom::metrom::{
        Self,
        EZeroAddressReceiver,
        EZeroAddressRewardToken,
        ENoRewardAmount,
        ENonExistentCampaign,
        ENonExistentReward,
        EInconsistentClaimedRewardAmount,
        ENoRoot,
        EInvalidProof
    };
    use metrom::tests_base;
    use metrom::test_token;

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = EZeroAddressReceiver)]
    fun fail_zero_address_receiver(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::claim_rewards(user, campaign_id, vector[], @0x1, 10, @0x0);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = EZeroAddressRewardToken)]
    fun fail_zero_address_token(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::claim_rewards(user, campaign_id, vector[], @0x0, 10, @0x1);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENoRewardAmount)]
    fun fail_zero_amount(aptos: &signer, metrom: &signer, user: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::claim_rewards(user, campaign_id, vector[], @0x1, 0, @0x1);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENonExistentCampaign)]
    fun fail_non_existent_campaign(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        metrom::claim_rewards(
            user,
            x"0000000000000000000000000000000000000000000000000000000000000001",
            vector[],
            @0x1,
            1,
            @0x1
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENoRoot)]
    fun fail_no_root(aptos: &signer, metrom: &signer, user: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::claim_rewards(user, campaign_id, vector[], @0x1, 1, @0x1);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENonExistentReward)]
    fun fail_non_existent_reward(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::distribute_rewards(
            user,
            campaign_id,
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );
        metrom::claim_rewards(user, campaign_id, vector[], @0x1, 1, @0x1);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = EInvalidProof)]
    fun fail_invalid_proof(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, reward_token_address) =
            tests_base::create_default_rewards_campaign(user, user);

        metrom::distribute_rewards(
            user,
            campaign_id,
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );

        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"0000000000000000000000000000000000000000000000000000000000000002"
            ],
            reward_token_address,
            100000000,
            @0x1
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = EInconsistentClaimedRewardAmount)]
    fun fail_too_much_amount(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, reward_token_address) =
            tests_base::create_default_rewards_campaign(user, user);

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000008",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000050",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 10100000000
        //     }
        // ]
        // then the provided proof at claim time is the one for the second claim

        metrom::distribute_rewards(
            user,
            campaign_id,
            x"4e328e811672b717cc6ae55a4a7c22cbde78df71c11d5a51702414748278b19f"
        );

        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"84f88ea9ca7c8d787a9e7e4fb299d21f20e355b30af49bb50baf163f2f0aa9b3"
            ],
            reward_token_address,
            10100000000,
            @0x1
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENoRewardAmount)]
    fun fail_multiple_same_claim_processing(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, reward_token_address) =
            tests_base::create_default_rewards_campaign(user, user);

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000008",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000050",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     }
        // ]
        // then the provided proof at claim time is the one for the second claim

        metrom::distribute_rewards(
            user,
            campaign_id,
            x"9d8a777a3b0223af8f444323a7262e629b240e6f0814e296bb51b70acb2da439"
        );

        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"84f88ea9ca7c8d787a9e7e4fb299d21f20e355b30af49bb50baf163f2f0aa9b3"
            ],
            reward_token_address,
            900000000,
            @0x1
        );

        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"84f88ea9ca7c8d787a9e7e4fb299d21f20e355b30af49bb50baf163f2f0aa9b3"
            ],
            reward_token_address,
            900000000,
            @0x1
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    fun success(aptos: &signer, metrom: &signer, user: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, reward_token_address) =
            tests_base::create_default_rewards_campaign(user, user);

        let metrom_treasury_address = metrom::treasury_address();

        let token = test_token::get_asset(reward_token_address);
        assert!(
            test_token::balance_of(token, metrom_treasury_address)
                == tests_base::octas(100)
        );

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000008",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000050",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     }
        // ]
        // then the provided proof at claim time is the one for the second claim

        metrom::distribute_rewards(
            user,
            campaign_id,
            x"9d8a777a3b0223af8f444323a7262e629b240e6f0814e296bb51b70acb2da439"
        );

        let receiver = @0x119991;

        assert!(test_token::balance_of(token, receiver) == 0);
        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"84f88ea9ca7c8d787a9e7e4fb299d21f20e355b30af49bb50baf163f2f0aa9b3"
            ],
            reward_token_address,
            tests_base::octas(9),
            receiver
        );
        assert!(
            test_token::balance_of(token, metrom_treasury_address)
                == tests_base::octas(91)
        );
        assert!(test_token::balance_of(token, receiver) == tests_base::octas(9));
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    fun success_complex_proof(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, reward_token_address) =
            tests_base::create_default_rewards_campaign(user, user);

        let metrom_treasury_address = metrom::treasury_address();

        let token = test_token::get_asset(reward_token_address);
        assert!(
            test_token::balance_of(token, metrom_treasury_address)
                == tests_base::octas(100)
        );

        // the following root is taken by constructing a tree
        // including the following claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000001",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000050",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 900000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000002",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 800000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000000000000000000000000000053",
        //         token: "0xff86b9406f5d37fd612ef4b8e4a122dc7837f547640926f069e6352106ba99c1",
        //         amount: 100000000
        //     }
        // ]
        // then the provided proof at claim time is the one for the second claim

        metrom::distribute_rewards(
            user,
            campaign_id,
            x"06eae8437fb44ca7f4e3f5b113a60d9d8f6b52f890006393299fb5dc843cead9"
        );

        let receiver = @0x119991;

        assert!(test_token::balance_of(token, receiver) == 0);
        metrom::claim_rewards(
            user,
            campaign_id,
            vector[
                x"9f804541de0f7b549aeca4c190399ab666624f9ed6959da2bbc6b43333eb6e5d",
                x"7f897bb769bce4051942ed7a5cd67d8378b6a2c02fa798db8982e71070eac36a"
            ],
            reward_token_address,
            tests_base::octas(9),
            receiver
        );
        assert!(
            test_token::balance_of(token, metrom_treasury_address)
                == tests_base::octas(91)
        );
        assert!(test_token::balance_of(token, receiver) == tests_base::octas(9));
    }
}
