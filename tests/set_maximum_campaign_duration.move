#[test_only]
module metrom::set_maximum_campaign_duration_tests {
    use metrom::metrom::{Self, EForbidden, EInvalidMaximumCampaignDuration};
    use metrom::tests_base;

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidMaximumCampaignDuration)]
    fun fail_invalid_duration1(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        let minimum_campaign_duration = metrom::minimum_campaign_duration();
        metrom::set_maximum_campaign_duration(owner, minimum_campaign_duration);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidMaximumCampaignDuration)]
    fun fail_invalid_duration2(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        let minimum_campaign_duration = metrom::minimum_campaign_duration();
        metrom::set_maximum_campaign_duration(owner, minimum_campaign_duration - 1);
    }

    #[test(metrom = @metrom, owner = @0x50, updater = @0x51)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        metrom: &signer, owner: &signer, updater: &signer
    ) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_maximum_campaign_duration(updater, 10_000);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    fun success(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_maximum_campaign_duration(owner, 10_000);
        assert!(metrom::maximum_campaign_duration() == 10_000);
    }
}
