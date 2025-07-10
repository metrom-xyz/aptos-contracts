module metrom::metrom {
    use std::signer;
    use std::option::{Self, Option};
    use std::smart_table::{Self, SmartTable};
    use std::vector;
    use std::timestamp;
    use std::aptos_hash;

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::bcs;

    // constants

    const METROM_STATE: vector<u8> = b"metrom_state";
    const ZERO_BYTES_32: vector<u8> = b"0x0000000000000000000000000000000000000000000000000000000000000000";

    const U32_1_000_000: u32 = 1_000_000;
    const U64_1_000_000: u64 = 1_000_000;
    const U64_1_HOUR_SECONDS: u64 = 3600;
    const MAX_REWARDS_PER_CAMPAIGN: u64 = 5;

    const EForbidden: u64 = 0;
    const EAlreadyInitialized: u64 = 1;
    const EInvalidFee: u64 = 2;
    const EInvalidMinimumCampaignDuration: u64 = 3;
    const EInvalidMaximumCampaignDuration: u64 = 4;
    const EInvalidRebate: u64 = 5;
    const EInvalidStartTime: u64 = 6;
    const EInvalidDuration: u64 = 7;
    const EInvalidRewards: u64 = 8;
    const EInvalidHash: u64 = 9;
    const EAlreadyExists: u64 = 10;
    const EInvalidTokenAmount: u64 = 11;
    const ENoPoints: u64 = 12;
    const EInvalidFeeToken: u64 = 13;

    // events

    #[event]
    struct Initialize has drop, store {
        owner: address,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    }

    #[event]
    struct CreateRewardsCampaign has drop, store {
        id: vector<u8>,
        owner: address,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>,
        reward_fees: vector<u64>
    }

    #[event]
    struct CreatePointsCampaign has drop, store {
        id: vector<u8>,
        owner: address,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        points: u64,
        fee_token: address,
        fee: u64
    }

    #[event]
    struct DistributeReward has drop, store {
        campaign_id: vector<u8>,
        root: vector<u8>
    }

    #[event]
    struct SetMinimumRewardTokenRate has drop, store {
        token: address,
        minimum_rate: u64
    }

    #[event]
    struct SetMinimumFeeTokenRate has drop, store {
        token: address,
        minimum_rate: u64
    }

    #[event]
    struct ClaimReward has drop, store {
        campaign_id: vector<u8>,
        token: address,
        amount: u64,
        receiver: address
    }

    #[event]
    struct ClaimFee has drop, store {
        token: address,
        amount: u64,
        receiver: address
    }

    #[event]
    struct TransferOwnership has drop, store {
        owner: address
    }

    #[event]
    struct AcceptOwnership has drop, store {
        owner: address
    }

    #[event]
    struct SetUpdater has drop, store {
        updater: address
    }

    #[event]
    struct SetFee has drop, store {
        fee: u32
    }

    #[event]
    struct SetFeeRebate has drop, store {
        account: address,
        rebate: u32
    }

    #[event]
    struct SetMinimumCampaignDuration has drop, store {
        minimum_campaign_duration: u64
    }

    #[event]
    struct SetMaximumCampaignDuration has drop, store {
        maximum_campaign_duration: u64
    }

    // data structs

    struct RewardAmount has drop {
        token: address,
        amount: u64
    }

    struct RewardsCampaignBundle has drop {
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>
    }

    struct LeafData has drop {
        owner: address,
        token: address,
        amount: u64
    }

    struct PointsCampaignBundle has drop {
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        points: u64,
        fee_token: address
    }

    struct PointsCampaign has store, key {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        points: u64
    }

    struct ReadonlyPointsCampaign {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        points: u64
    }

    struct Reward has store, key {
        amount: u64,
        claimed: SmartTable<address, u64>
    }

    struct RewardsCampaign has store, key {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        root: vector<u8>,
        reward: SmartTable<address, Reward>
    }

    struct ReadonlyRewardsCampaign {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        root: vector<u8>
    }

    struct State has key {
        owner: address,
        pending_owner: Option<address>,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64,
        fee_rebate: SmartTable<address, u32>,
        claimable_fees: SmartTable<address, u64>,
        minimum_reward_token_rate: SmartTable<address, u64>,
        minimum_fee_token_rate: SmartTable<address, u64>,
        points_campaign: SmartTable<vector<u8>, PointsCampaign>,
        rewards_campaign: SmartTable<vector<u8>, RewardsCampaign>,
        treasury_account: SignerCapability
    }

    // internal utility functions

    fun state_obj_address(): address {
        object::create_object_address(&@metrom, METROM_STATE)
    }

    inline fun borrow_state(): &State acquires State {
        borrow_global<State>(state_obj_address())
    }

    inline fun borrow_mut_state(): &mut State acquires State {
        borrow_global_mut<State>(state_obj_address())
    }

    inline fun borrow_mut_state_for_owner(owner: address): &mut State acquires State {
        let state = borrow_global_mut<State>(state_obj_address());
        assert!(state.owner == owner, EForbidden);
        state
    }

    inline fun borrow_mut_state_for_updater(updater: address): &mut State acquires State {
        let state = borrow_global_mut<State>(state_obj_address());
        assert!(state.updater == updater, EForbidden);
        state
    }

    fun validate_hash(hash: vector<u8>) {
        let hash_len = hash.length();
        assert!(
            hash_len == 0 || (hash_len == 32 && hash != ZERO_BYTES_32),
            EInvalidHash
        );
    }

    fun validate_campaign_base_returning_duration(
        specification_hash: vector<u8>,
        from: u64,
        to: u64,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    ): u64 {
        validate_hash(specification_hash);

        assert!(from > timestamp::now_seconds(), EInvalidStartTime);
        assert!(
            to >= from + minimum_campaign_duration,
            EInvalidDuration
        );
        let duration = to - from;
        assert!(duration < maximum_campaign_duration, EInvalidDuration);

        duration
    }

    fun get_token_metadata(token: address): Object<Metadata> {
        object::address_to_object<Metadata>(token)
    }

    fun take_token_amount(
        state: &State,
        token: address,
        from: &signer,
        required_amount: u64
    ): u64 {
        let treasury_address =
            account::get_signer_capability_address(&state.treasury_account);
        let token_metadata = get_token_metadata(token);
        let balance_before =
            primary_fungible_store::balance(treasury_address, token_metadata);
        primary_fungible_store::transfer(
            from,
            token_metadata,
            treasury_address,
            required_amount
        );
        let received_amount =
            primary_fungible_store::balance(treasury_address, token_metadata)
                - balance_before;
        assert!(received_amount >= required_amount);
        received_amount
    }

    // write functions

    entry fun init_module(caller: &signer) {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @metrom, EForbidden);

        let constructor_ref = object::create_named_object(caller, METROM_STATE);
        let obj_signer = &object::generate_signer(&constructor_ref);

        let (_, treasury_account) = account::create_resource_account(
            caller, METROM_STATE
        );

        move_to(
            obj_signer,
            State {
                owner: @0x00,
                pending_owner: option::none(),
                updater: @0x00,
                fee: 0,
                minimum_campaign_duration: 0,
                maximum_campaign_duration: 0,
                fee_rebate: smart_table::new(),
                claimable_fees: smart_table::new(),
                minimum_reward_token_rate: smart_table::new(),
                minimum_fee_token_rate: smart_table::new(),
                points_campaign: smart_table::new(),
                rewards_campaign: smart_table::new(),
                treasury_account
            }
        );
    }

    public entry fun init_state(
        caller: &signer,
        owner: address,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    ) acquires State {
        assert!(
            signer::address_of(caller) == @metrom,
            EForbidden
        );
        assert!(fee < U32_1_000_000, EInvalidFee);
        assert!(
            minimum_campaign_duration < maximum_campaign_duration,
            EInvalidMinimumCampaignDuration
        );

        let state = borrow_global_mut<State>(state_obj_address());
        assert!(state.owner == @0x00, EAlreadyInitialized);

        state.owner = owner;
        state.updater = updater;
        state.fee = fee;
        state.minimum_campaign_duration = minimum_campaign_duration;
        state.maximum_campaign_duration = maximum_campaign_duration;

        event::emit(
            Initialize {
                owner,
                updater,
                fee,
                minimum_campaign_duration,
                maximum_campaign_duration
            }
        );
    }

    public entry fun create_reward_campaign(
        caller: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>
    ) acquires State {
        let rewards_len = reward_tokens.length();
        assert!(
            rewards_len <= MAX_REWARDS_PER_CAMPAIGN && rewards_len != 0,
            EInvalidRewards
        );

        let state = borrow_mut_state();
        let id =
            aptos_hash::keccak256(
                bcs::to_bytes(
                    &RewardsCampaignBundle {
                        from,
                        to,
                        kind,
                        data,
                        specification_hash,
                        reward_tokens,
                        reward_amounts
                    }
                )
            );
        assert!(!state.rewards_campaign.contains(id), EAlreadyExists);

        let duration =
            validate_campaign_base_returning_duration(
                specification_hash,
                from,
                to,
                state.minimum_campaign_duration,
                state.maximum_campaign_duration
            );

        let caller_address = signer::address_of(caller);
        let fee_rebate = *state.fee_rebate.borrow_with_default(caller_address, &0);
        let resolved_fee =
            ((state.fee as u64) * ((U32_1_000_000 - fee_rebate) as u64)
                / (U32_1_000_000 as u64)) as u32;

        let reward = smart_table::new<address, Reward>();
        let reward_fees = vector::empty<u64>();
        for (i in 0..rewards_len) {
            let token = reward_tokens.remove(i);
            let amount = reward_amounts.remove(i);

            let minimum_reward_token_rate =
                *state.minimum_reward_token_rate.borrow(token);
            assert!(
                amount * U64_1_HOUR_SECONDS / duration >= minimum_reward_token_rate,
                EInvalidTokenAmount
            );

            let received_amount = Self::take_token_amount(state, token, caller, amount);
            let fee_amount = amount * (resolved_fee as u64) / U64_1_000_000;
            let reward_amount_minus_fees = received_amount - fee_amount;
            *state.claimable_fees.borrow_mut_with_default(token, 0) += fee_amount;

            reward_fees.push_back(fee_amount);

            if (reward.contains(token)) {
                reward.borrow_mut(token).amount += reward_amount_minus_fees;
            } else {
                reward.add(
                    token,
                    Reward { amount: reward_amount_minus_fees, claimed: smart_table::new() }
                );
            }
        };

        state.rewards_campaign.add(
            id,
            RewardsCampaign {
                owner: signer::address_of(caller),
                pending_owner: option::none(),
                from,
                to,
                kind,
                data,
                specification_hash,
                root: vector::empty(),
                reward
            }
        );

        event::emit(
            CreateRewardsCampaign {
                id,
                owner: caller_address,
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_tokens,
                reward_amounts,
                reward_fees
            }
        );
    }

    public entry fun create_points_campaign(
        caller: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: vector<u8>,
        points: u64,
        fee_token: address
    ) acquires State {
        assert!(points > 0, ENoPoints);

        let state = borrow_mut_state();
        let id =
            aptos_hash::keccak256(
                bcs::to_bytes(
                    &PointsCampaignBundle {
                        from,
                        to,
                        kind,
                        data,
                        specification_hash,
                        points,
                        fee_token
                    }
                )
            );
        assert!(!state.points_campaign.contains(id), EAlreadyExists);

        let duration =
            validate_campaign_base_returning_duration(
                specification_hash,
                from,
                to,
                state.minimum_campaign_duration,
                state.maximum_campaign_duration
            );

        let caller_address = signer::address_of(caller);
        let fee_rebate = *state.fee_rebate.borrow_with_default(caller_address, &0);
        let minimum_fee_token_rate = *state.minimum_fee_token_rate.borrow(fee_token);
        assert!(minimum_fee_token_rate > 0, EInvalidFeeToken);
        let fee_amount = minimum_fee_token_rate * duration / U64_1_HOUR_SECONDS;
        let fee_amount = fee_amount * ((U32_1_000_000 - fee_rebate) as u64) / U64_1_000_000;

        state.points_campaign.add(
            id,
            PointsCampaign {
                owner: signer::address_of(caller),
                pending_owner: option::none(),
                from,
                to,
                kind,
                data,
                specification_hash,
                points
            }
        );

        let received_amount = Self::take_token_amount(
            state, fee_token, caller, fee_amount
        );
        *state.claimable_fees.borrow_mut_with_default(fee_token, 0) += received_amount;
    }

    public entry fun distribute_rewards(
        caller: &signer, campaign_id: vector<u8>, root: vector<u8>
    ) acquires State {
        validate_hash(root);
        let state = borrow_mut_state_for_updater(signer::address_of(caller));
        state.rewards_campaign.borrow_mut(campaign_id).root = root;
        event::emit(DistributeReward { campaign_id, root });
    }

    public entry fun set_minimum_reward_token_rates(
        caller: &signer, tokens: vector<address>, minimum_rates: vector<u64>
    ) acquires State {
        Self::set_minimum_token_rates(caller, tokens, minimum_rates, false);
    }

    public entry fun set_minimum_fee_token_rates(
        caller: &signer, tokens: vector<address>, minimum_rates: vector<u64>
    ) acquires State {
        Self::set_minimum_token_rates(caller, tokens, minimum_rates, true);
    }

    fun set_minimum_token_rates(
        caller: &signer,
        tokens: vector<address>,
        minimum_rates: vector<u64>,
        fees: bool
    ) acquires State {
        let state = borrow_mut_state_for_updater(signer::address_of(caller));

        for (i in 0..tokens.length()) {
            let token = tokens.remove(i);
            let minimum_rate = minimum_rates.remove(i);
            if (fees) {
                state.minimum_fee_token_rate.upsert(token, minimum_rate);
                event::emit(SetMinimumFeeTokenRate { token, minimum_rate });
            } else {
                state.minimum_reward_token_rate.upsert(token, minimum_rate);
                event::emit(SetMinimumRewardTokenRate { token, minimum_rate });
            }
        };
    }

    fun process_reward_claim(
        treasury_signer: &signer,
        root: vector<u8>,
        reward: &mut Reward,
        claim_owner: address,
        proof: vector<vector<u8>>,
        token: address,
        amount: u64,
        receiver: address
    ): u64 {
        assert!(amount > 0, EInvalidTokenAmount);

        let leaf =
            aptos_hash::keccak256(
                aptos_hash::keccak256(
                    bcs::to_bytes(&LeafData { owner: claim_owner, token, amount })
                )
            );
        // if (!MerkleProof.verifyCalldata(_bundle.proof, _campaignRoot, _leaf)) revert InvalidProof();

        let claimed_amount = reward.claimed.borrow_mut(claim_owner);
        let claim_amount = amount - *claimed_amount;
        if (claim_amount == 0) return 0;
        assert!(claim_amount <= reward.amount, EInvalidTokenAmount);

        *claimed_amount += claim_amount;
        reward.amount -= claim_amount;

        primary_fungible_store::transfer(
            treasury_signer,
            get_token_metadata(token),
            receiver,
            claim_amount
        );

        claim_amount
    }

    fun claimable_reward_and_root(
        caller: &signer,
        state: &mut State,
        campaign_id: vector<u8>,
        token: address,
        check_owner: bool
    ): (vector<u8>, &mut Reward) {
        let campaign = state.rewards_campaign.borrow_mut(campaign_id);
        if (check_owner) assert!(
            signer::address_of(caller) == campaign.owner, EForbidden
        );
        (campaign.root, campaign.reward.borrow_mut(token))
    }

    public entry fun claim_rewards(
        caller: &signer,
        campaign_id: vector<u8>,
        proof: vector<vector<u8>>,
        token: address,
        amount: u64,
        receiver: address
    ) acquires State {
        let state = borrow_mut_state();
        let treasury_signer =
            account::create_signer_with_capability(&state.treasury_account);

        let caller_address = signer::address_of(caller);

        let (root, claimable_reward) =
            claimable_reward_and_root(caller, state, campaign_id, token, false);
        let claimed_amount =
            process_reward_claim(
                &treasury_signer,
                root,
                claimable_reward,
                caller_address,
                proof,
                token,
                amount,
                receiver
            );
        event::emit(
            ClaimReward { campaign_id, token, amount: claimed_amount, receiver }
        );
    }

    public entry fun recover_rewards(
        caller: &signer,
        campaign_id: vector<u8>,
        proof: vector<vector<u8>>,
        token: address,
        amount: u64,
        receiver: address
    ) acquires State {
        let state = borrow_mut_state();
        let treasury_signer =
            account::create_signer_with_capability(&state.treasury_account);

        let (root, claimable_reward) =
            claimable_reward_and_root(caller, state, campaign_id, token, true);
        let claimed_amount =
            process_reward_claim(
                &treasury_signer,
                root,
                claimable_reward,
                @0x00,
                proof,
                token,
                amount,
                receiver
            );
        event::emit(
            ClaimReward { campaign_id, token, amount: claimed_amount, receiver }
        );
    }

    public entry fun claim_fees(
        caller: &signer, token: address, receiver: address
    ) acquires State {
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        let treasury_signer =
            account::create_signer_with_capability(&state.treasury_account);

        let amount = state.claimable_fees.remove(token);
        primary_fungible_store::transfer(
            &treasury_signer,
            get_token_metadata(token),
            receiver,
            amount
        );
        event::emit(ClaimFee { token, amount, receiver });
    }

    public entry fun transfer_ownership(caller: &signer, owner: address) acquires State {
        borrow_mut_state_for_owner(signer::address_of(caller)).pending_owner = option::some(
            owner
        );
        event::emit(TransferOwnership { owner });
    }

    public entry fun accept_ownership(caller: &signer, old_owner: address) acquires State {
        let state = borrow_mut_state_for_owner(old_owner);
        let new_owner_address = signer::address_of(caller);
        assert!(state.pending_owner.contains(&new_owner_address), EForbidden);
        state.owner = new_owner_address;
        state.pending_owner = option::none();
        event::emit(AcceptOwnership { owner: new_owner_address });
    }

    public entry fun set_updater(caller: &signer, updater: address) acquires State {
        borrow_mut_state_for_owner(signer::address_of(caller)).updater = updater;
        event::emit(SetUpdater { updater });
    }

    public entry fun set_fee(caller: &signer, fee: u32) acquires State {
        assert!(fee < U32_1_000_000, EInvalidFee);
        borrow_mut_state_for_owner(signer::address_of(caller)).fee = fee;
        event::emit(SetFee { fee });
    }

    public entry fun set_fee_rebate(
        caller: &signer, account: address, rebate: u32
    ) acquires State {
        assert!(rebate <= U32_1_000_000, EInvalidRebate);
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        state.fee_rebate.upsert(account, rebate);
        event::emit(SetFeeRebate { account, rebate });
    }

    public entry fun set_minimum_campaign_duration(
        caller: &signer, minimum_campaign_duration: u64
    ) acquires State {
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        assert!(
            minimum_campaign_duration < state.maximum_campaign_duration,
            EInvalidMinimumCampaignDuration
        );
        state.minimum_campaign_duration = minimum_campaign_duration;
        event::emit(SetMinimumCampaignDuration { minimum_campaign_duration });

    }

    public entry fun set_maximum_campaign_duration(
        caller: &signer, maximum_campaign_duration: u64
    ) acquires State {
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        assert!(
            maximum_campaign_duration > state.maximum_campaign_duration,
            EInvalidMaximumCampaignDuration
        );
        state.maximum_campaign_duration = maximum_campaign_duration;
        event::emit(SetMaximumCampaignDuration { maximum_campaign_duration });
    }

    // view functions

    #[view]
    public fun rewards_campaign_by_id(id: vector<u8>): ReadonlyRewardsCampaign acquires State {
        let campaign = borrow_state().rewards_campaign.borrow(id);

        ReadonlyRewardsCampaign {
            owner: campaign.owner,
            pending_owner: campaign.pending_owner,
            from: campaign.from,
            to: campaign.to,
            kind: campaign.kind,
            data: campaign.data,
            specification_hash: campaign.specification_hash,
            root: campaign.root
        }
    }

    #[view]
    public fun points_campaign_by_id(id: vector<u8>): ReadonlyPointsCampaign acquires State {
        let campaign = borrow_state().points_campaign.borrow(id);

        ReadonlyPointsCampaign {
            owner: campaign.owner,
            pending_owner: campaign.pending_owner,
            from: campaign.from,
            to: campaign.to,
            kind: campaign.kind,
            data: campaign.data,
            specification_hash: campaign.specification_hash,
            points: campaign.points
        }
    }

    #[view]
    public fun campaign_reward(id: vector<u8>, token: address): u64 acquires State {
        borrow_state().rewards_campaign.borrow(id).reward.borrow(token).amount
    }

    #[view]
    public fun claimed_campaign_reward(
        id: vector<u8>, token: address, account: address
    ): u64 acquires State {
        *borrow_state().rewards_campaign.borrow(id).reward.borrow(token).claimed.borrow(
            account
        )
    }

    #[view]
    public fun owner(): address acquires State {
        borrow_state().owner
    }

    #[view]
    public fun pending_owner(): Option<address> acquires State {
        borrow_state().pending_owner
    }

    #[view]
    public fun updater(): address acquires State {
        borrow_state().updater
    }

    #[view]
    public fun fee(): u32 acquires State {
        borrow_state().fee
    }

    #[view]
    public fun fee_rebate(account: address): u32 acquires State {
        *borrow_state().fee_rebate.borrow_with_default(account, &0)
    }

    #[view]
    public fun claimable_fees(token: address): u64 acquires State {
        *borrow_state().claimable_fees.borrow_with_default(token, &0)
    }

    #[view]
    public fun minimum_campaign_duration(): u64 acquires State {
        borrow_state().minimum_campaign_duration
    }

    #[view]
    public fun maximum_campaign_duration(): u64 acquires State {
        borrow_state().maximum_campaign_duration
    }

    #[test_only]
    public fun test_init_module(caller: &signer) {
        init_module(caller);
    }
}
