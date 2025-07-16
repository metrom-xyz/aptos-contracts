#[test_only]
module metrom::claim_fees_tests {
    use metrom::metrom::{Self, EForbidden, EZeroAddressReceiver, EInvalidFeeToken};
    use metrom::tests_base;
    use metrom::test_token;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EZeroAddressReceiver)]
    fun fail_zero_address_receiver(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::claim_fees(aptos, @0x1, @0x0);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::claim_fees(aptos, @0x10, @0x01);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidFeeToken)]
    fun fail_invalid_fee_token(
        aptos: &signer, metrom: &signer, owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::claim_fees(owner, @0x10, @0x01);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        let (_, reward_token_address) =
            tests_base::create_default_rewards_campaign(owner, owner);

        let recipient = @0x70;
        assert!(
            test_token::balance_of(
                test_token::get_asset(reward_token_address), recipient
            ) == 0
        );
        metrom::claim_fees(owner, reward_token_address, recipient);
        assert!(
            test_token::balance_of(
                test_token::get_asset(reward_token_address), recipient
            ) == tests_base::octas(1)
        );
    }
}
