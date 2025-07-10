#[test_only]
module metrom::set_minimum_campaign_duration_tests {
    use metrom::metrom::{Self, EForbidden, EInvalidMinimumCampaignDuration};
    use metrom::tests_base;

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidMinimumCampaignDuration)]
    fun fail_invalid_duration1(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        let maximum_campaign_duration = metrom::maximum_campaign_duration();
        metrom::set_minimum_campaign_duration(owner, maximum_campaign_duration);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidMinimumCampaignDuration)]
    fun fail_invalid_duration2(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        let maximum_campaign_duration = metrom::maximum_campaign_duration();
        metrom::set_minimum_campaign_duration(owner, maximum_campaign_duration + 1);
    }

    #[test(metrom = @metrom, owner = @0x50, updater = @0x51)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        metrom: &signer, owner: &signer, updater: &signer
    ) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_minimum_campaign_duration(updater, 10);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    fun success(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        assert!(metrom::minimum_campaign_duration() != 10);
        metrom::set_minimum_campaign_duration(owner, 10);
        assert!(metrom::minimum_campaign_duration() == 10);
    }
}
