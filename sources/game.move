module charity::game {
    use charity::drand_lib::{derive_randomness, verify_drand_signature, safe_selection};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use std::option::{Self, Option};
    use std::vector;

    const EPaymentTooLow: u64 = 1;
    const EDonationEnded: u64 = 2;
    const EDonationNotActive: u64 = 3;
    const EDonationCompleted: u64 = 4;

    struct Donation {
        id: UID,
        end_time: u64,
        goal: u64,
        donates: Balance<SUI>,
        active: bool,
    }

    struct DonorRecord {
        id: UID,
        donation_id: ID,
        donor: address,
        amount_donated: u64,
    }

    public fun new(target: u64, duration: u64, clock: &Clock, ctx: &mut TxContext) {
        let end_time = duration + clock::timestamp_ms(clock);
        let donation = Donation {
            id: object::new(ctx),
            end_time: end_time,
            goal: target,
            donates: balance::zero(),
            active: true,
        };
        transfer::share_object(donation);
    }

    public fun donate(donation: &mut Donation, amount: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        assert!(donation.active, EDonationNotActive);
        assert!(donation.end_time > clock::timestamp_ms(clock), EDonationEnded);
        assert!(coin::value(&amount) > 0, EPaymentTooLow);

        let balance = coin::into_balance(amount);
        balance::join(&mut donation.donates, balance);

        let donor_record = DonorRecord {
            id: object::new(ctx),
            donation_id: object::id(donation),
            donor: tx_context::sender(ctx),
            amount_donated: balance::value(&balance),
        };
        transfer::share_object(donor_record);
    }

    public fun endDonation(donation: &mut Donation, clock: &Clock, ctx: &mut TxContext) {
        assert!(donation.active, EDonationNotActive);
        assert!(donation.end_time < clock::timestamp_ms(clock), EDonationEnded);

        let balance = balance::withdraw_all<SUI>(&mut donation.donates);
        let coin = coin::from_balance(balance, ctx);

        transfer::public_transfer(coin, tx_context::sender(ctx));
        donation.active = false;
    }

    public fun getDonorRecords(donation: &DonorRecord) : (ID, address, u64) {
        (
            donation.donation_id,
            donation.donor,
            donation.amount_donated
        )  
    }

    // Get total amount donated
    public fun getTotalDonated(donation: &Donation): u64 {
        balance::value(&donation.donates)
    }

    // Get donation goal
    public fun getDonationGoal(donation: &Donation): u64 {
        donation.goal
    }
}
