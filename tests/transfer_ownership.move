#[test_only]
module metrom::transfer_ownership_tests {
    use std::signer;

    use metrom::metrom::{Self, EForbidden};
    use metrom::tests_base;

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
        metrom::transfer_ownership(account, @0x10);
    }

    #[test(aptos = @aptos_framework, metrom = @metrom, owner = @0x50)]
    fun success(aptos: &signer, metrom: &signer, owner: &signer) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, owner);

        assert!(metrom::owner() == signer::address_of(owner));
        assert!(metrom::pending_owner().is_none());

        metrom::transfer_ownership(owner, @0x70);

        assert!(metrom::owner() == signer::address_of(owner));
        assert!(metrom::pending_owner().contains(&@0x70));
    }
}
