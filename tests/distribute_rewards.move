#[test_only]
module metrom::distribute_rewards_tests {
    use metrom::metrom::{Self, EInvalidHash, ENonExistentCampaign};
    use metrom::tests_base;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidHash)]
    fun fail_invalid_root_length(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let (campaign_id, _) = tests_base::create_default_rewards_campaign(owner, owner);

        metrom::distribute_rewards(owner, campaign_id, vector[0u8]);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidHash)]
    fun fail_zero_root(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let (campaign_id, _) = tests_base::create_default_rewards_campaign(owner, owner);

        metrom::distribute_rewards(
            owner,
            campaign_id,
            x"0000000000000000000000000000000000000000000000000000000000000000"
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = ENonExistentCampaign)]
    fun fail_non_existent_campaign(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        metrom::distribute_rewards(
            owner,
            x"0000000000000000000000000000000000000000000000000000000000000001",
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        let root = x"0000000000000000000000000000000000000000000000000000000000000001";
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(owner, owner);
        metrom::distribute_rewards(owner, campaign_id, root);
        metrom::assert_rewards_campaign_root(campaign_id, root);
    }
}
