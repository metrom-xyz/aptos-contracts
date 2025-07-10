#[test_only]
module metrom::set_updater_tests {
    use metrom::metrom::{Self, EForbidden};
    use metrom::tests_base;

    #[test(metrom = @metrom, owner = @0x50, updater = @0x51)]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        metrom: &signer, owner: &signer, updater: &signer
    ) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        metrom::set_updater(updater, @0x60);
    }

    #[test(metrom = @metrom, owner = @0x50)]
    fun success(metrom: &signer, owner: &signer) {
        tests_base::init_metrom_with_defaults(metrom, owner);
        assert!(metrom::updater() != @0x60);
        metrom::set_updater(owner, @0x60);
        assert!(metrom::updater() == @0x60);
    }
}
