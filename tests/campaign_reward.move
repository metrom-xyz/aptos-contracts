#[test_only]
module metrom::campaign_reward_tests {
    use metrom::metrom;
    use metrom::tests_base;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        let (campaign_id, reward_token) =
            tests_base::create_default_rewards_campaign(owner, owner);
        assert!(
            metrom::campaign_reward(campaign_id, reward_token) == tests_base::octas(99)
        );
    }
}
