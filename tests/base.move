#[test_only]
module metrom::tests_base {
    use aptos_framework::signer;

    use metrom::metrom;

    #[test_only]
    public fun init_metrom_with_defaults(metrom: &signer, owner: &signer) {
        Self::init_metrom(metrom, owner, @0xBBBB, 10_000, 1, 100);
    }

    #[test_only]
    public fun init_metrom(
        metrom: &signer,
        owner: &signer,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    ) {
        metrom::test_init_module(metrom);
        metrom::init_state(
            metrom,
            signer::address_of(owner),
            updater,
            fee,
            minimum_campaign_duration,
            maximum_campaign_duration
        );
    }
}
