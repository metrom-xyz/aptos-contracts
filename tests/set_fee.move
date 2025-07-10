#[test_only]
module metrom::set_fee_tests {
    use metrom::metrom::{Self, EInvalidFee, EForbidden};
    use metrom::tests_base;

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidFee)]
    fun fail_invalid(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(owner, 1_000_000);
    }

    #[test(metrom = @metrom, owner = @0x50, updater = @0x51)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        metrom: &signer, owner: &signer, updater: &signer
    ) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(updater, 10_000);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    fun success(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee(owner, 10_000);
        assert!(metrom::fee() == 10_000);
    }
}
