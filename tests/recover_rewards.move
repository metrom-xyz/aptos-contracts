#[test_only]
module metrom::recover_rewards_tests {
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
        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[vector[]],
            vector[@0x1],
            vector[10],
            vector[@0x0]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = EZeroAddressRewardToken)]
    fun fail_zero_address_token(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[vector[]],
            vector[@0x0],
            vector[10],
            vector[@0x1]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENoRewardAmount)]
    fun fail_zero_amount(aptos: &signer, metrom: &signer, user: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[vector[]],
            vector[@0x1],
            vector[0],
            vector[@0x1]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENonExistentCampaign)]
    fun fail_non_existent_campaign(
        aptos: &signer, metrom: &signer, user: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        metrom::recover_rewards(
            user,
            vector[
                x"0000000000000000000000000000000000000000000000000000000000000001"
            ],
            vector[vector[]],
            vector[@0x1],
            vector[1],
            vector[@0x1]
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, user = @0x50)]
    #[expected_failure(abort_code = ENoRoot)]
    fun fail_no_root(aptos: &signer, metrom: &signer, user: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, user);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(user, user);
        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[vector[]],
            vector[@0x1],
            vector[1],
            vector[@0x1]
        );
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
            vector[campaign_id],
            vector[
                x"0000000000000000000000000000000000000000000000000000000000000001"
            ]
        );
        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[vector[]],
            vector[@0x1],
            vector[1],
            vector[@0x1]
        );
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
            vector[campaign_id],
            vector[
                x"0000000000000000000000000000000000000000000000000000000000000001"
            ]
        );

        metrom::recover_rewards(
            user,
            vector[campaign_id],
            vector[
                vector[
                    x"0000000000000000000000000000000000000000000000000000000000000002"
                ]
            ],
            vector[reward_token_address],
            vector[100000000],
            vector[@0x1]
        );
    }
}
