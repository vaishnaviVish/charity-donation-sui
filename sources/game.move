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

    const EPaymentTooLow : u64 = 0;
    const EWrongDonation : u64 = 1;
    const EDonationEnded: u64 = 2;
    const EDonationNotEnded: u64 = 4;
    const EDonationCompleted: u64 = 5;

    struct Donation has key, store {
        id: UID,
        end_time: u64,
        goal: u64,
        donates: Balance<SUI>,
        status: bool,
    }

    struct DonorRecord has key, store {
        id: UID,
        donationId: ID,
        donor: address,
        amountDonated: u64,
    }

    public fun new(target: u64, duration: u64, clock: &Clock, ctx: &mut TxContext) {
        // donationDuration is passed in minutes,
        let end_time_ = duration + clock::timestamp_ms(clock);
        // create Donation
        let donation = Donation {
            id: object::new(ctx),
            end_time: end_time_,
            goal: target,
            donates: balance::zero(),
            status: true,
        };
        // make donation accessible by everyone
        transfer::share_object(donation);
    }

    public fun donate(donation: &mut Donation, amount: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        // check that donation has not ended
        assert!(donation.end_time > clock::timestamp_ms(clock), EDonationEnded);
        // check that donation state is still active
        assert!(donation.status, EDonationEnded);
        // add the amount to the donation's total
        assert!(coin::value(&amount) > 0 ,EPaymentTooLow);
        let balance_ = coin::into_balance(amount);
        let amount = balance::value(&balance_);
        balance::join(&mut donation.donates, balance_);
        // create donor record
        let donorRecord = DonorRecord {
            id: object::new(ctx),
            donationId: object::id(donation),
            donor: tx_context::sender(ctx),
            amountDonated: amount,
        };
        // make donor record accessible by everyone
        transfer::public_transfer(donorRecord, tx_context::sender(ctx));
    }

    public fun endDonation(donation: &mut Donation, clock: &Clock, ctx: &mut TxContext){
        // check that donation has ended
        assert!(donation.end_time < clock::timestamp_ms(clock), EDonationNotEnded);
        // check that donation state is still active
        let balance_ = balance::withdraw_all<SUI>(&mut donation.donates);
        let coin_ = coin::from_balance(balance_, ctx);

        transfer::public_transfer(coin_, tx_context::sender(ctx));
        donation.status = false;
    }

    public fun getDonorRecords(donation: &DonorRecord) : (ID, address, u64) {
        (
            donation.donationId,
            donation.donor,
            donation.amountDonated
        )  
    }

    // Get total amount donated
    public fun getTotalDonated(donation: &Donation): u64 {
        let amount = balance::value(&donation.donates);
        amount 
    }

    // Get donation goal
    public fun getDonationGoal(donation: &Donation): u64 {
        donation.goal
    }
}
