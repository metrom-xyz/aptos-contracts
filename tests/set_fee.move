#[test_only]
module metrom::set_fee_tests {
    use metrom::metrom::{Self, EInvalidFee, EForbidden};
    use metrom::tests_base;

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidFee)]
    fun fail_invalid(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(owner, 1_000_000);
    }

    #[test(
        aptos = @aptos_framework, metrom = @metrom, owner = @0x50, updater = @0x51
    )]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        aptos: &signer,
        metrom: &signer,
        owner: &signer,
        updater: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(updater, 10_000);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(owner, 10_000);
        assert!(metrom::fee() == 10_000);
    }
}
