/// @title Metrom
/// @notice The module handling all Metrom entities and interactions. It supports
/// creation and update of campaigns as well as claims and recoveries of unassigned
/// rewards for each one of them.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
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
    const ZERO_BYTES_32: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    const U32_1_000_000: u32 = 1_000_000;
    const U64_1_000_000: u64 = 1_000_000;
    const U64_1_HOUR_SECONDS: u64 = 3600;
    const MAX_REWARDS_PER_CAMPAIGN: u64 = 5;

    // events

    #[event]
    /// @notice Emitted at initialization time.
    /// @param owner The initial module's owner.
    /// @param updater The initial module's updater.
    /// @param fee The initial module's rewards campaign fee.
    /// @param minimum_campaign_duration The initial module's minimum campaign duration.
    /// @param maximum_campaign_duration The initial module's maximum campaign duration.
    struct Initialize has drop, store {
        owner: address,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    }

    #[event]
    /// @notice Emitted when a rewards based campaign is created.
    /// @param id The id of the campaign.
    /// @param owner The initial owner of the campaign.
    /// @param from From when the campaign will run.
    /// @param to To when the campaign will run.
    /// @param kind The campaign's kind.
    /// @param data ABI-encoded campaign-specific data.
    /// @param specification_hash The campaign's specification hash.
    /// @param reward_tokens A list of the reward tokens used to create the campaign.
    /// @param reward_amounts A list of the reward amounts used to create the campaign.
    /// @param A list of the fees paid to create the campaign.
    struct CreateRewardsCampaign has drop, store {
        id: vector<u8>,
        owner: address,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>,
        reward_fees: vector<u64>
    }

    #[event]
    /// @notice Emitted when a points based campaign is created.
    /// @param id The id of the campaign.
    /// @param owner The initial owner of the campaign.
    /// @param from From when the campaign will run.
    /// @param to To when the campaign will run.
    /// @param kind The campaign's kind.
    /// @param data ABI-encoded campaign-specific data.
    /// @param specification_hash The campaign's specification data hash.
    /// @param points The amount of points to distribute (scaled to account for 18 decimals).
    /// @param fee_token The token used to pay the creation fee.
    /// @param fee The creation fee amount.
    struct CreatePointsCampaign has drop, store {
        id: vector<u8>,
        owner: address,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64,
        fee_token: address,
        fee: u64
    }

    #[event]
    /// @notice Emitted when the campaigns updater distributes rewards on a campaign.
    /// @param campaign_id The id of the campaign. on which the rewards were distributed.
    /// @param root The updated Merkle root for the campaign.
    struct DistributeReward has drop, store {
        campaign_id: vector<u8>,
        root: vector<u8>
    }

    #[event]
    /// @notice Emitted when the rates updater or the owner updates the minimum emission
    /// rate of a certain whitelisted reward token required in order to create a rewards based
    /// campaign.
    /// @param token The address of the whitelisted reward token to update.
    /// @param minimum_rate The new minimum rate required in order to create a
    /// campaign.
    struct SetMinimumRewardTokenRate has drop, store {
        token: address,
        minimum_rate: u64
    }

    #[event]
    /// @notice Emitted when the rates updater or the owner updates the minimum rate for a
    /// certain whitelisted fee token required in order to create a points based campaign.
    /// @param token The address of the whitelisted fee token to update.
    /// @param minimum_rate The new minimum rate required in order to create a
    /// campaign.
    struct SetMinimumFeeTokenRate has drop, store {
        token: address,
        minimum_rate: u64
    }

    #[event]
    /// @notice Emitted when an eligible LP claims a reward.
    /// @param campaign_id The id of the campaign on which the claim is performed.
    /// @param token The claimed token.
    /// @param amount The claimed amount.
    /// @param receiver The claim's receiver.
    struct ClaimReward has drop, store {
        campaign_id: vector<u8>,
        token: address,
        amount: u64,
        receiver: address
    }

    #[event]
    /// @notice Emitted when the campaign's owner recovers unassigned rewards.
    /// @param campaign_id The id of the campaign on which the recovery was performed.
    /// @param token The recovered token.
    /// @param amount The recovered amount.
    /// @param receiver The recovery's receiver.
    struct RecoverReward has drop, store {
        campaign_id: vector<u8>,
        token: address,
        amount: u64,
        receiver: address
    }

    #[event]
    /// @notice Emitted when Metrom's module owner claims accrued fees.
    /// @param token The claimed token.
    /// @param amount The claimed amount.
    /// @param receiver The claims's receiver.
    struct ClaimFee has drop, store {
        token: address,
        amount: u64,
        receiver: address
    }

    #[event]
    /// @notice Emitted when a campaign's ownership transfer is initiated.
    /// @param id The targeted campaign's id.
    /// @param owner The new desired owner.
    struct TransferCampaignOwnership has drop, store {
        campaign_id: vector<u8>,
        owner: address
    }

    #[event]
    /// @notice Emitted when a campaign's current pending owner accepts its ownership.
    /// @param id The targete campaign's id.
    /// @param owner The targete campaign's new owner.
    struct AcceptCampaignOwnership has drop, store {
        campaign_id: vector<u8>,
        owner: address
    }

    #[event]
    /// @notice Emitted when Metrom's ownership transfer is initiated.
    /// @param owner The new desired owner.
    struct TransferOwnership has drop, store {
        owner: address
    }

    #[event]
    /// @notice Emitted when Metrom's current pending owner accepts its ownership.
    /// @param owner The new owner.
    struct AcceptOwnership has drop, store {
        owner: address
    }

    #[event]
    /// @notice Emitted when Metrom's owner sets a new allowed updater address.
    /// @param updater The new updater.
    struct SetUpdater has drop, store {
        updater: address
    }

    #[event]
    /// @notice Emitted when Metrom's owner sets a new rewards based campaign fee.
    /// @param fee The new rewards campaign fee.
    struct SetFee has drop, store {
        fee: u32
    }

    #[event]
    /// @notice Emitted when Metrom's owner sets a new address-specific
    /// rebate for the protocol rewards based campaign fees.
    /// @param account The account for which the rebate was set.
    /// @param rebate The rebate.
    struct SetFeeRebate has drop, store {
        account: address,
        rebate: u32
    }

    #[event]
    /// @notice Emitted when Metrom's owner sets a new minimum campaign duration.
    /// @param minimum_campaign_duration The new minimum campaign duration.
    struct SetMinimumCampaignDuration has drop, store {
        minimum_campaign_duration: u64
    }

    #[event]
    /// @notice Emitted when Metrom's owner sets a new maximum campaign duration.
    /// @param maximum_campaign_duration The new maximum campaign duration.
    struct SetMaximumCampaignDuration has drop, store {
        maximum_campaign_duration: u64
    }

    // errors

    const EForbidden: u64 = 0;
    const EAlreadyInitialized: u64 = 1;
    const EAlreadyExists: u64 = 2;
    const ENoRewards: u64 = 3;
    const ETooManyRewards: u64 = 4;
    const EInconsistentRewards: u64 = 5;
    const EZeroAddressRewardToken: u64 = 6;
    const ENoRewardAmount: u64 = 7;
    const EDisallowedRewardToken: u64 = 8;
    const ERewardAmountTooLow: u64 = 9;
    const ENotEnoughTokensTransferred: u64 = 10;
    const ENoPoints: u64 = 11;
    const EDisallowedFeeToken: u64 = 12;
    const EInvalidHash: u64 = 13;
    const ENonExistentCampaign: u64 = 14;
    const EZeroAddressReceiver: u64 = 15;
    const EInconsistentClaimedRewardAmount: u64 = 16;
    const ENonExistentReward: u64 = 17;
    const EInvalidFee: u64 = 18;
    const EInvalidMinimumCampaignDuration: u64 = 19;
    const EInvalidMaximumCampaignDuration: u64 = 20;
    const EInvalidRebate: u64 = 21;
    const EInvalidStartTime: u64 = 22;
    const EInvalidDuration: u64 = 23;
    const EZeroAddressFeeToken: u64 = 24;
    const EInvalidFeeToken: u64 = 25;
    const EInvalidProof: u64 = 26;
    const ENoRoot: u64 = 27;
    const EInconsistentArrayLengths: u64 = 28;

    // data structs

    /// @notice Represents a points based campaign in the module's state, with its owner,
    /// running period, type, data, specification hash and points information.
    struct PointsCampaign has copy, store, drop, key {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64
    }

    /// @notice Represents a reward for a campaign in the module's
    /// state. It keeps track of the remaining amount after fees as well
    /// as a mapping of claimed amounts for each user.
    struct Reward has store, key {
        amount: u64,
        claimed: SmartTable<address, u64>
    }

    /// @notice Represents a rewards based campaign in the module's state, with its owner,
    /// running period, type, data, specification hash, root and rewards information.
    struct RewardsCampaign has store, key {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        root: Option<vector<u8>>,
        reward: SmartTable<address, Reward>
    }

    /// @notice Represents a readonly rewards based campaign.
    struct ReadonlyRewardsCampaign has drop {
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        root: Option<vector<u8>>
    }

    /// @notice The module's overall operating state. Keeps track of protocol parameters and
    /// created campaigns/entities in general.
    struct State has key {
        treasury: SignerCapability,
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
        rewards_campaign: SmartTable<vector<u8>, RewardsCampaign>
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
        let state = borrow_mut_state();
        assert!(state.owner == owner, EForbidden);
        state
    }

    inline fun borrow_mut_state_for_updater(updater: address): &mut State acquires State {
        let state = borrow_mut_state();
        assert!(state.updater == updater, EForbidden);
        state
    }

    fun validate_hash(hash: Option<vector<u8>>) {
        if (hash.is_none()) return;

        let hash = hash.borrow();
        let hash_len = hash.length();
        assert!(
            hash_len == 32 && *hash != ZERO_BYTES_32,
            EInvalidHash
        );
    }

    fun validate_campaign_base_returning_duration(
        specification_hash: Option<vector<u8>>,
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
        assert!(duration <= maximum_campaign_duration, EInvalidDuration);

        duration
    }

    fun generate_raw_leaf(owner: address, token: address, amount: u64): vector<u8> {
        let out = bcs::to_bytes(&owner);
        out.append(bcs::to_bytes(&token));
        out.append(bcs::to_bytes(&amount));
        out
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
        let treasury_address = account::get_signer_capability_address(&state.treasury);
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
        assert!(received_amount >= required_amount, ENotEnoughTokensTransferred);
        received_amount
    }

    // write functions

    /// @notice Standard module initialization function. Sets up internal state in a basic way,
    /// and needs the `init_state` function to be called to finish initialization.
    entry fun init_module(caller: &signer) {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @metrom, EForbidden);

        let constructor_ref = object::create_named_object(caller, METROM_STATE);
        let obj_signer = &object::generate_signer(&constructor_ref);

        let (_, treasury) = account::create_resource_account(caller, METROM_STATE);

        move_to(
            obj_signer,
            State {
                treasury,
                owner: @0x0,
                pending_owner: option::none(),
                updater: @0x0,
                fee: 0,
                minimum_campaign_duration: 0,
                maximum_campaign_duration: 0,
                fee_rebate: smart_table::new(),
                claimable_fees: smart_table::new(),
                minimum_reward_token_rate: smart_table::new(),
                minimum_fee_token_rate: smart_table::new(),
                points_campaign: smart_table::new(),
                rewards_campaign: smart_table::new()
            }
        );
    }

    /// @notice Initializes the module's state.
    /// @param owner The initial owner.
    /// @param updater The initial updater.
    /// @param fee The initial fee.
    /// @param minimum_campaign_duration The initial minimum campaign duration.
    /// @param maximum_campaign_duration The initial maximum campaign duration.
    public entry fun init_state(
        owner: address,
        updater: address,
        fee: u32,
        minimum_campaign_duration: u64,
        maximum_campaign_duration: u64
    ) acquires State {
        assert!(fee < U32_1_000_000, EInvalidFee);
        assert!(
            minimum_campaign_duration < maximum_campaign_duration,
            EInvalidMinimumCampaignDuration
        );

        let state = borrow_mut_state();
        assert!(state.owner == @0x0, EAlreadyInitialized);

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

    /// @notice Creates a rewards campaign.
    /// @param from The starting timestamp of the campaign.
    /// @param to The ending timestamp of the campaign.
    /// @param kind The kind of the campaign.
    /// @param data The BCS-encoded campaign's additional data.
    /// @param specification_hash The specification hash for the campaign, optionally
    /// pointing fo a file containing the JSON specification for the campaign.
    /// @param reward_tokens The reward tokens for the campaign.
    /// @param reward_amounts The reward amounts for the campaign.
    public entry fun create_rewards_campaign(
        caller: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>
    ) acquires State {
        let rewards_len = reward_tokens.length();
        assert!(rewards_len > 0, ENoRewards);
        assert!(rewards_len <= MAX_REWARDS_PER_CAMPAIGN, ETooManyRewards);
        assert!(rewards_len == reward_amounts.length(), EInconsistentRewards);

        let id =
            rewards_campaign_id(
                from,
                to,
                kind,
                data,
                specification_hash,
                reward_tokens,
                reward_amounts
            );

        let state = borrow_mut_state();
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
            ((state.fee as u64) * (U64_1_000_000 - (fee_rebate as u64)) / (U64_1_000_000)) as u32;

        let reward = smart_table::new<address, Reward>();
        let reward_fees = vector::empty<u64>();
        for (i in 0..rewards_len) {
            let token = reward_tokens[i];
            assert!(token != @0x0, EZeroAddressRewardToken);

            let amount = reward_amounts[i];
            assert!(amount > 0, ENoRewardAmount);

            let minimum_reward_token_rate =
                *state.minimum_reward_token_rate.borrow_with_default(token, &0);
            assert!(minimum_reward_token_rate > 0, EDisallowedRewardToken);
            assert!(
                amount * U64_1_HOUR_SECONDS / duration >= minimum_reward_token_rate,
                ERewardAmountTooLow
            );

            let received_amount = take_token_amount(state, token, caller, amount);
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
                root: option::none(),
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

    /// @notice Creates a points campaign.
    /// @param from The starting timestamp of the campaign.
    /// @param to The ending timestamp of the campaign.
    /// @param kind The kind of the campaign.
    /// @param data The BCS-encoded campaign's additional data.
    /// @param specification_hash The specification hash for the campaign, optionally
    /// pointing fo a file containing the JSON specification for the campaign.
    /// @param points The points to distribute.
    /// @param fee_token The token with which to pay the creation fee.
    public entry fun create_points_campaign(
        caller: &signer,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64,
        fee_token: address
    ) acquires State {
        assert!(points > 0, ENoPoints);
        assert!(fee_token != @0x0, EZeroAddressFeeToken);

        let state = borrow_mut_state();
        let id =
            points_campaign_id(
                from,
                to,
                kind,
                data,
                specification_hash,
                points,
                fee_token
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
        let minimum_fee_token_rate =
            *state.minimum_fee_token_rate.borrow_with_default(fee_token, &0);
        assert!(minimum_fee_token_rate > 0, EDisallowedFeeToken);
        let fee_amount = minimum_fee_token_rate * duration / U64_1_HOUR_SECONDS;
        let fee_amount = fee_amount * ((U32_1_000_000 - fee_rebate) as u64) / U64_1_000_000;

        let received_amount = take_token_amount(state, fee_token, caller, fee_amount);
        *state.claimable_fees.borrow_mut_with_default(fee_token, 0) += received_amount;

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
    }

    /// @notice Distributes rewards on a campaign. This function must be called by
    /// the updater.
    /// @param campaign_id The id of the campaign to update.
    /// @param root The Merkle root to set for the campaign.
    public entry fun distribute_rewards(
        caller: &signer,
        campaign_ids: vector<vector<u8>>,
        roots: vector<vector<u8>>
    ) acquires State {
        let campaign_ids_len = campaign_ids.length();
        assert!(
            roots.length() == campaign_ids_len,
            EInconsistentArrayLengths
        );

        for (i in 0..campaign_ids_len) {
            let campaign_id = campaign_ids[i];
            let root = roots[i];

            validate_hash(option::some(root));
            let state = borrow_mut_state_for_updater(signer::address_of(caller));
            assert!(state.rewards_campaign.contains(campaign_id), ENonExistentCampaign);
            state.rewards_campaign.borrow_mut(campaign_id).root = option::some(root);
            event::emit(DistributeReward { campaign_id, root });
        }
    }

    /// @notice Sets the minimum rate for an allowed reward token. Can only be called by
    /// the updater account.
    /// @param token The address of the allowed token.
    /// @param minimum_rate The new minimum rate.
    public entry fun set_minimum_token_rates(
        caller: &signer,
        reward_tokens: vector<address>,
        minimum_reward_token_rates: vector<u64>,
        fee_tokens: vector<address>,
        minimum_fee_token_rates: vector<u64>
    ) acquires State {
        set_minimum_token_rates_inner(
            caller,
            reward_tokens,
            minimum_reward_token_rates,
            false
        );
        set_minimum_token_rates_inner(
            caller,
            fee_tokens,
            minimum_fee_token_rates,
            true
        );
    }

    fun set_minimum_token_rates_inner(
        caller: &signer,
        tokens: vector<address>,
        minimum_rates: vector<u64>,
        fees: bool
    ) acquires State {
        let tokens_len = tokens.length();
        assert!(
            minimum_rates.length() == tokens_len,
            EInconsistentArrayLengths
        );

        let state = borrow_mut_state_for_updater(signer::address_of(caller));

        for (i in 0..tokens_len) {
            let token = tokens[i];
            let minimum_rate = minimum_rates[i];

            if (fees) {
                state.minimum_fee_token_rate.upsert(token, minimum_rate);
                event::emit(SetMinimumFeeTokenRate { token, minimum_rate });
            } else {
                state.minimum_reward_token_rate.upsert(token, minimum_rate);
                event::emit(SetMinimumRewardTokenRate { token, minimum_rate });
            }
        }
    }

    fun process_reward_claim(
        caller_address: address,
        campaign_id: vector<u8>,
        claim_owner: address,
        enforce_campaign_owner: bool,
        proof: vector<vector<u8>>,
        token: address,
        amount: u64,
        receiver: address
    ): u64 acquires State {
        assert!(receiver != @0x0, EZeroAddressReceiver);
        assert!(token != @0x0, EZeroAddressRewardToken);
        assert!(amount > 0, ENoRewardAmount);

        let state = borrow_mut_state();

        assert!(state.rewards_campaign.contains(campaign_id), ENonExistentCampaign);
        let campaign = state.rewards_campaign.borrow_mut(campaign_id);
        assert!(campaign.root.is_some(), ENoRoot);
        assert!(campaign.reward.contains(token), ENonExistentReward);
        let reward = campaign.reward.borrow_mut(token);
        if (enforce_campaign_owner) assert!(caller_address == campaign.owner, EForbidden);

        assert!(
            verify_merkle_proof(
                *campaign.root.borrow(),
                proof,
                claim_owner,
                token,
                amount
            ),
            EInvalidProof
        );

        let already_claimed_amount =
            reward.claimed.borrow_mut_with_default(claim_owner, 0u64);
        let claimed_amount = amount - *already_claimed_amount;
        assert!(claimed_amount > 0, ENoRewardAmount);
        assert!(claimed_amount <= reward.amount, EInconsistentClaimedRewardAmount);

        *already_claimed_amount += claimed_amount;
        reward.amount -= claimed_amount;

        primary_fungible_store::transfer(
            &account::create_signer_with_capability(&state.treasury),
            get_token_metadata(token),
            receiver,
            claimed_amount
        );

        claimed_amount
    }

    fun verify_merkle_proof(
        root: vector<u8>,
        proof: vector<vector<u8>>,
        claim_owner: address,
        token: address,
        amount: u64
    ): bool {
        let leaf =
            aptos_hash::keccak256(
                aptos_hash::keccak256(generate_raw_leaf(claim_owner, token, amount))
            );

        let computed_hash = leaf;
        for (i in 0..proof.length()) {
            let proof_item = proof[i];
            computed_hash =
                if (hash_a_less_than_b(computed_hash, proof_item)) {
                    computed_hash.append(proof_item);
                    aptos_hash::keccak256(computed_hash)
                } else {
                    proof_item.append(computed_hash);
                    aptos_hash::keccak256(proof_item)
                }
        };

        computed_hash == root
    }

    fun hash_a_less_than_b(a: vector<u8>, b: vector<u8>): bool {
        let a_len = a.length();
        let b_len = b.length();
        assert!(a_len == 32 && a_len == b_len, EInvalidHash);

        for (i in 0..a_len) {
            let a_item = a[i];
            let b_item = b[i];

            if (a_item == b_item) {
                continue;
            } else if (a_item < b_item) {
                return true;
            } else {
                return false;
            };
        };

        return false
    }

    fun process_multiple_claims(
        caller: &signer,
        campaign_ids: vector<vector<u8>>,
        proofs: vector<vector<vector<u8>>>,
        tokens: vector<address>,
        amounts: vector<u64>,
        receivers: vector<address>,
        recovering: bool
    ) acquires State {
        let campaign_ids_len = campaign_ids.length();
        assert!(
            proofs.length() == campaign_ids_len
                && tokens.length() == campaign_ids_len
                && amounts.length() == campaign_ids_len
                && receivers.length() == campaign_ids_len,
            EInconsistentArrayLengths
        );

        let caller_address = signer::address_of(caller);
        for (i in 0..campaign_ids_len) {
            let campaign_id = campaign_ids[i];
            let token = tokens[i];
            let amount = amounts[i];
            let proof = proofs[i];
            let receiver = receivers[i];

            let amount =
                process_reward_claim(
                    caller_address,
                    campaign_id,
                    if (recovering)@0x0
                    else caller_address,
                    false,
                    proof,
                    token,
                    amount,
                    receiver
                );

            if (recovering) event::emit(
                RecoverReward { campaign_id, token, amount, receiver }
            )
            else event::emit(
                ClaimReward { campaign_id, token, amount, receiver }
            )
        }
    }

    /// @notice Claims outstanding rewards on a given rewards campaign.
    /// @param campaign_ids The ids of the campaigns on which to process the claim.
    /// @param proofs The Merkle inclusion proofs required to prove that the claims are valid.
    /// @param tokens The tokens to claim.
    /// @param amounts The amounts to claim.
    /// @param receivers The receivers to which the claims must be sent.
    public entry fun claim_rewards(
        caller: &signer,
        campaign_ids: vector<vector<u8>>,
        proofs: vector<vector<vector<u8>>>,
        tokens: vector<address>,
        amounts: vector<u64>,
        receivers: vector<address>
    ) acquires State {
        process_multiple_claims(
            caller,
            campaign_ids,
            proofs,
            tokens,
            amounts,
            receivers,
            false
        );
    }

    /// @notice Recovers unassigned rewards on a given rewards campaign. This can only be
    /// called by the targeted campaign's owner.
    /// @param campaign_ids The ids of the campaigns on which to process the claim.
    /// @param proofs The Merkle inclusion proofs required to prove that the claims are valid.
    /// @param tokens The tokens to claim.
    /// @param amounts The amounts to claim.
    /// @param receivers The receivers to which the claims must be sent.
    public entry fun recover_rewards(
        caller: &signer,
        campaign_ids: vector<vector<u8>>,
        proofs: vector<vector<vector<u8>>>,
        tokens: vector<address>,
        amounts: vector<u64>,
        receivers: vector<address>
    ) acquires State {
        process_multiple_claims(
            caller,
            campaign_ids,
            proofs,
            tokens,
            amounts,
            receivers,
            true
        );

    }

    /// @notice Can be called by Metrom's owner to claim accrued protocol fees.
    /// @param token The token to claim.
    /// @param token The receiver of the claim.
    public entry fun claim_fees(
        caller: &signer, token: address, receiver: address
    ) acquires State {
        assert!(receiver != @0x0, EZeroAddressReceiver);
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        assert!(state.claimable_fees.contains(token), EInvalidFeeToken);
        let treasury_signer = account::create_signer_with_capability(&state.treasury);
        let amount = state.claimable_fees.remove(token);
        primary_fungible_store::transfer(
            &treasury_signer,
            get_token_metadata(token),
            receiver,
            amount
        );
        event::emit(ClaimFee { token, amount, receiver });
    }

    /// @notice Initiates an ownership transfer operation for a campaign. This can only be
    /// called by the current campaign owner.
    /// @param id The id of the targeted campaign.
    /// @param owner The desired new owner of the campaign.
    public entry fun transfer_campaign_ownership(
        caller: &signer, id: vector<u8>, owner: address
    ) acquires State {
        let caller_address = signer::address_of(caller);

        let state = borrow_mut_state();
        if (state.rewards_campaign.contains(id)) {
            let rewards_campaign = state.rewards_campaign.borrow_mut(id);
            assert!(rewards_campaign.owner == caller_address, EForbidden);
            rewards_campaign.pending_owner = option::some(owner);
        } else if (state.points_campaign.contains(id)) {
            let points_campaign = state.points_campaign.borrow_mut(id);
            assert!(points_campaign.owner == caller_address, EForbidden);
            points_campaign.pending_owner = option::some(owner);
        } else {
            assert!(false, ENonExistentCampaign);
        };

        event::emit(TransferCampaignOwnership { campaign_id: id, owner });
    }

    /// @notice Finalized an ownership transfer operation for a campaign. This can only be
    /// called by the current campaign pending owner to accept ownership of it.
    /// @param id The id of the targeted campaign.
    public entry fun accept_campaign_ownership(
        caller: &signer, id: vector<u8>
    ) acquires State {
        let caller_address = signer::address_of(caller);
        let state = borrow_mut_state();

        if (state.rewards_campaign.contains(id)) {
            let rewards_campaign = state.rewards_campaign.borrow_mut(id);
            assert!(
                rewards_campaign.pending_owner.contains(&caller_address), EForbidden
            );
            rewards_campaign.owner = caller_address;
            rewards_campaign.pending_owner = option::none();
        } else if (state.points_campaign.contains(id)) {
            let points_campaign = state.points_campaign.borrow_mut(id);
            assert!(points_campaign.owner == caller_address, EForbidden);
            points_campaign.owner = caller_address;
            points_campaign.pending_owner = option::none();
        } else {
            assert!(false, ENonExistentCampaign);
        };

        event::emit(AcceptCampaignOwnership { campaign_id: id, owner: caller_address });
    }

    /// @notice Initiates an ownership transfer operation for the Metrom module. This can
    /// only be called by the current Metrom owner.
    /// @param owner The desired new owner of Metrom.
    public entry fun transfer_ownership(caller: &signer, owner: address) acquires State {
        borrow_mut_state_for_owner(signer::address_of(caller)).pending_owner = option::some(
            owner
        );
        event::emit(TransferOwnership { owner });
    }

    /// @notice Finalizes an ownership transfer operation for the Metrom module. This can
    /// only be called by the current Metrom pending owner.
    public entry fun accept_ownership(caller: &signer) acquires State {
        let state = borrow_mut_state();
        let new_owner_address = signer::address_of(caller);
        assert!(state.pending_owner.contains(&new_owner_address), EForbidden);
        state.owner = new_owner_address;
        state.pending_owner = option::none();
        event::emit(AcceptOwnership { owner: new_owner_address });
    }

    /// @notice Can be called by Metrom's owner to set a new allowed updater address.
    /// @param updater The new updater address.
    public entry fun set_updater(caller: &signer, updater: address) acquires State {
        borrow_mut_state_for_owner(signer::address_of(caller)).updater = updater;
        event::emit(SetUpdater { updater });
    }

    /// @notice Can be called by Metrom's owner to set a new fee value.
    public entry fun set_fee(caller: &signer, fee: u32) acquires State {
        assert!(fee < U32_1_000_000, EInvalidFee);
        borrow_mut_state_for_owner(signer::address_of(caller)).fee = fee;
        event::emit(SetFee { fee });
    }

    /// @notice Can be called by Metrom's owner to set a new specific protocol fee
    /// rebate for an account.
    /// @param account The account for which to set the rebate value.
    /// @param rebate The rebate.
    public entry fun set_fee_rebate(
        caller: &signer, account: address, rebate: u32
    ) acquires State {
        assert!(rebate <= U32_1_000_000, EInvalidRebate);
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        state.fee_rebate.upsert(account, rebate);
        event::emit(SetFeeRebate { account, rebate });
    }

    /// @notice Can be called by Metrom's owner to set a new minimum allowed campaign duration.
    /// @param minimumCampaignDuration The new minimum allowed campaign duration.
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

    /// @notice Can be called by Metrom's owner to set a new maximum allowed campaign duration.
    /// @param maximumCampaignDuration The new maximum allowed campaign duration.
    public entry fun set_maximum_campaign_duration(
        caller: &signer, maximum_campaign_duration: u64
    ) acquires State {
        let state = borrow_mut_state_for_owner(signer::address_of(caller));
        assert!(
            maximum_campaign_duration > state.minimum_campaign_duration,
            EInvalidMaximumCampaignDuration
        );
        state.maximum_campaign_duration = maximum_campaign_duration;
        event::emit(SetMaximumCampaignDuration { maximum_campaign_duration });
    }

    // view functions

    #[view]
    public fun rewards_campaign_id(
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>
    ): vector<u8> {
        let out = bcs::to_bytes(&from);
        out.append(bcs::to_bytes(&to));
        out.append(bcs::to_bytes(&kind));
        out.append(bcs::to_bytes(&data));
        out.append(bcs::to_bytes(&specification_hash));
        out.append(bcs::to_bytes(&reward_tokens));
        out.append(bcs::to_bytes(&reward_amounts));
        aptos_hash::keccak256(out)
    }

    #[view]
    public fun points_campaign_id(
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64,
        fee_token: address
    ): vector<u8> {
        let out = bcs::to_bytes(&from);
        out.append(bcs::to_bytes(&to));
        out.append(bcs::to_bytes(&kind));
        out.append(bcs::to_bytes(&data));
        out.append(bcs::to_bytes(&specification_hash));
        out.append(bcs::to_bytes(&points));
        out.append(bcs::to_bytes(&fee_token));
        aptos_hash::keccak256(out)
    }

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
    public fun points_campaign_by_id(id: vector<u8>): PointsCampaign acquires State {
        *borrow_state().points_campaign.borrow(id)
    }

    #[view]
    public fun campaign_reward(id: vector<u8>, token: address): u64 acquires State {
        let state = borrow_state();
        if (!state.rewards_campaign.contains(id)) {
            return 0;
        };

        let campaign = state.rewards_campaign.borrow(id);
        if (!campaign.reward.contains(token)) {
            return 0;
        };

        campaign.reward.borrow(token).amount
    }

    #[view]
    public fun claimed_campaign_reward(
        id: vector<u8>, token: address, account: address
    ): u64 acquires State {
        let state = borrow_state();
        if (!state.rewards_campaign.contains(id)) {
            return 0;
        };

        let campaign = state.rewards_campaign.borrow(id);
        if (!campaign.reward.contains(token)) {
            return 0;
        };

        *campaign.reward.borrow(token).claimed.borrow_with_default(account, &0)
    }

    #[view]
    public fun minimum_reward_token_rate(token: address): u64 acquires State {
        *borrow_state().minimum_reward_token_rate.borrow_with_default(token, &0)
    }

    #[view]
    public fun minimum_fee_token_rate(token: address): u64 acquires State {
        *borrow_state().minimum_fee_token_rate.borrow_with_default(token, &0)
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
    public fun minimum_campaign_duration(): u64 acquires State {
        borrow_state().minimum_campaign_duration
    }

    #[view]
    public fun maximum_campaign_duration(): u64 acquires State {
        borrow_state().maximum_campaign_duration
    }

    #[view]
    public fun treasury_address(): address acquires State {
        account::get_signer_capability_address(&borrow_state().treasury)
    }

    // test-only functions

    #[test_only]
    public fun test_init_module(caller: &signer) {
        init_module(caller);
    }

    #[test_only]
    public fun assert_rewards_campaign_full(
        campaign_id: vector<u8>,
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        root: Option<vector<u8>>,
        reward_tokens: vector<address>,
        reward_amounts: vector<u64>,
        fee_amounts: vector<u64>
    ) acquires State {
        let campaign = rewards_campaign_by_id(campaign_id);

        assert!(campaign.owner == owner);
        assert!(campaign.pending_owner == pending_owner);
        assert!(campaign.from == from);
        assert!(campaign.to == to);
        assert!(campaign.kind == kind);
        assert!(campaign.data == data);
        assert!(campaign.specification_hash == specification_hash);
        assert!(campaign.root == root);

        for (i in 0..reward_tokens.length()) {
            assert!(
                campaign_reward(campaign_id, reward_tokens[i]) == reward_amounts[i]
            );
            assert!(
                claimable_fees(reward_tokens[i]) == fee_amounts[i]
            );
        }
    }

    #[test_only]
    public fun assert_points_campaign_full(
        campaign_id: vector<u8>,
        owner: address,
        pending_owner: Option<address>,
        from: u64,
        to: u64,
        kind: u32,
        data: vector<u8>,
        specification_hash: Option<vector<u8>>,
        points: u64,
        fee_token: address,
        fee_amount: u64
    ) acquires State {
        let campaign = points_campaign_by_id(campaign_id);

        assert!(campaign.owner == owner);
        assert!(campaign.pending_owner == pending_owner);
        assert!(campaign.from == from);
        assert!(campaign.to == to);
        assert!(campaign.kind == kind);
        assert!(campaign.data == data);
        assert!(campaign.specification_hash == specification_hash);
        assert!(campaign.points == points);
        assert!(claimable_fees(fee_token) == fee_amount);
    }

    #[test_only]
    public fun assert_rewards_campaign_root(
        campaign_id: vector<u8>, expected: vector<u8>
    ) acquires State {
        assert!(rewards_campaign_by_id(campaign_id).root == option::some(expected));
    }

    #[test_only]
    public fun assert_rewards_campaign_owner_and_pending_owner(
        campaign_id: vector<u8>,
        expected_owner: address,
        expected_pending_owner: Option<address>
    ) acquires State {
        let campaign = rewards_campaign_by_id(campaign_id);
        assert!(campaign.owner == expected_owner);
        assert!(campaign.pending_owner == expected_pending_owner);
    }
}
