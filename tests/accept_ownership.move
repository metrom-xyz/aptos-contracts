#[test_only]
module metrom::accept_ownership_tests {
    use std::signer;

    use metrom::metrom::{Self, EForbidden};
    use metrom::tests_base;

    #[test(
        aptos = @aptos_framework, metrom = @metrom, old_owner = @0x50, new_owner = @0x51
    )]
    #[expected_failure(abort_code = EForbidden)]
    fun fail_forbidden(
        aptos: &signer,
        metrom: &signer,
        old_owner: &signer,
        new_owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, old_owner);
        metrom::transfer_ownership(old_owner, @0x10); // this is fine
        metrom::accept_ownership(new_owner); // this fails
    }

    #[test(
        aptos = @aptos_framework, metrom = @metrom, old_owner = @0x50, new_owner = @0x51
    )]
    fun success(
        aptos: &signer,
        metrom: &signer,
        old_owner: &signer,
        new_owner: &signer
    ) {
        tests_base::init(aptos);
        tests_base::init_metrom_with_defaults(metrom, old_owner);

        let old_owner_address = signer::address_of(old_owner);
        let new_owner_address = signer::address_of(new_owner);

        assert!(metrom::owner() == old_owner_address);
        assert!(metrom::pending_owner().is_none());

        metrom::transfer_ownership(old_owner, new_owner_address);
        metrom::accept_ownership(new_owner);

        assert!(metrom::owner() == new_owner_address);
        assert!(metrom::pending_owner().is_none());
    }
}
