#[test_only]
module metrom::set_fee_rebate_tests {
    use metrom::metrom::{Self, EForbidden, EInvalidRebate};
    use metrom::tests_base;

    #[test(metrom = @metrom, owner = @0x50)]
    #[expected_failure(abort_code = EInvalidRebate)]
    fun fail_invalid(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee_rebate(owner, @0x60, 1_000_001);
    }

    #[test(metrom = @metrom, owner = @0x50, updater = @0x51)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        metrom: &signer, owner: &signer, updater: &signer
    ) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_fee_rebate(updater, @0x60, 10_000);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    fun success(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);

        assert!(metrom::fee_rebate(@0x60) == 0);
        metrom::set_fee_rebate(owner, @0x60, 1_000_000);
        assert!(metrom::fee_rebate(@0x60) == 1_000_000);

        metrom::set_fee_rebate(owner, @0x60, 10_000);
        assert!(metrom::fee_rebate(@0x60) == 10_000);

        metrom::set_fee_rebate(owner, @0x60, 0);
        assert!(metrom::fee_rebate(@0x60) == 0);
    }
}
