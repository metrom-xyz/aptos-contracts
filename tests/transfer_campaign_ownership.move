#[test_only]
module metrom::transfer_campaign_ownership_tests {
    use std::option;
    use std::signer;

    use metrom::metrom::{Self, ENonExistentCampaign, EForbidden};
    use metrom::tests_base;

    #[test(
        aptos = @aptos_framework, metrom = @metrom, owner = @0x50, account = @0x51
    )]
    #[expected_failure(abort_code = ENonExistentCampaign)]
    fun fail_non_existent_campaign(
        aptos: &signer,
        metrom: &signer,
        owner: &signer,
        account: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::transfer_campaign_ownership(
            account,
            x"0000000000000000000000000000000000000000000000000000000000000001",
            @0x2
        );
    }

    #[test(
        aptos = @aptos_framework, metrom = @metrom, owner = @0x50, account = @0x51
    )]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        aptos: &signer,
        metrom: &signer,
        owner: &signer,
        account: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(owner, owner);
        metrom::transfer_campaign_ownership(account, campaign_id, @0x10);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        let (campaign_id, _) = tests_base::create_default_rewards_campaign(owner, owner);
        metrom::transfer_campaign_ownership(owner, campaign_id, @0x10);
        metrom::assert_rewards_campaign_owner_and_pending_owner(
            campaign_id, signer::address_of(owner), option::some(@0x10)
        );
    }
}
