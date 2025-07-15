#[test_only]
module metrom::accept_campaign_ownership_tests {
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
        metrom::accept_campaign_ownership(
            account,
            x"0000000000000000000000000000000000000000000000000000000000000001"
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
        metrom::accept_campaign_ownership(account, campaign_id);
    }

    #[test(
        aptos = @aptos_framework, metrom = @metrom, old_owner = @0x50, new_owner = @0x51
    )]
    fun success(
        aptos: &signer,
        metrom: &signer,
        old_owner: &signer,
        new_owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, old_owner);
        let (campaign_id, _) =
            tests_base::create_default_rewards_campaign(old_owner, old_owner);
        metrom::transfer_campaign_ownership(
            old_owner, campaign_id, signer::address_of(new_owner)
        );
        metrom::assert_rewards_campaign_owner_and_pending_owner(
            campaign_id,
            signer::address_of(old_owner),
            option::some(signer::address_of(new_owner))
        );
        metrom::accept_campaign_ownership(new_owner, campaign_id);
        metrom::assert_rewards_campaign_owner_and_pending_owner(
            campaign_id, signer::address_of(new_owner), option::none()
        );
    }
}
