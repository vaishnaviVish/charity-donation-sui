#[allow(lint(self_transfer))]
module charity::donation_platform {
    use charity::donation_lib::{derive_randomness, verify_drand_signature, safe_selection};
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


    const ACTIVE : u64 = 0;
    const ENDED: u64 = 1;

    struct Donation has key {
        id: UID,
        endTime: u64,
        donationGoal: Balance<SUI>,
        totalDonated: Balance<SUI>,
        status: u64,
    }

    struct DonorRecord has key, store {
        id: UID,
        donationId: ID,
        donor: address,
        amountDonated: Coin<SUI>,
    }

    public fun startDonation(donationGoal: Balance<SUI>, donationDuration: u64, clock: &Clock, ctx: &mut TxContext) {
        // donationDuration is passed in minutes,
        let endTime = donationDuration + clock::timestamp_ms(clock);

        // create Donation
        let donation = Donation {
            id: object::new(ctx),
            endTime,
            donationGoal,
            totalDonated: balance::zero(),
            status: ACTIVE,
        };

        // make donation accessible by everyone
        transfer::share_object(donation);
    }

    public fun donate(donation: &mut Donation, amount: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        // check that donation has not ended
        assert!(donation.endTime > clock::timestamp_ms(clock), EDonationEnded);

        // check that donation state is still active
        assert!(donation.status == ACTIVE, EDonationEnded);

        // add the amount to the donation's total
        let coin_balance = coin::into_balance(amount);
        balance::join(&mut donation.totalDonated, coin_balance);

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

    public fun endDonation(donation: &mut Donation, clock: &Clock){
        // check that donation has ended
        assert!(donation.endTime < clock::timestamp_ms(clock), EDonationNotEnded);

        // check that donation state is still active
        assert!(donation.status == ACTIVE, EDonationEnded);

        donation.status = ENDED;
    }

    public fun getDonorRecords(donation: &Donation) -> vector<DonorRecord> {
        let mut donorRecords: vector<DonorRecord> = vector::empty();
        let allDonorRecords = object::get_all::<DonorRecord>();
        for donorRecord in allDonorRecords.iter() {
            if donorRecord.donationId == object::id(donation) {
                vector::push_back(&mut donorRecords, *donorRecord);
            }
        }
        donorRecords
    }

    // Get total amount donated
    public fun getTotalDonated(donation: &Donation): Balance<SUI> {
        donation.totalDonated
    }

    // Get donation goal
    public fun getDonationGoal(donation: &Donation): Balance<SUI> {
        donation.donationGoal
    }

    // Tests
    #[test_only] use sui::test_scenario as ts;
    #[test_only] const Donor1: address = @0xA;
    #[test_only] const Donor2: address = @0xB;
    #[test_only] const Donor3: address = @0xC;

    #[test_only]
    public fun testDonate(ts: &mut ts::Scenario, sender: address, amount: u64, clock: &Clock){
        ts::next_tx(ts, sender);
        let donation = ts::take_shared<Donation>(ts);
        let amountCoin = coin::mint_for_testing<SUI>( amount, ts::ctx(ts));
        donate(&mut donation, amountCoin, clock, ts::ctx(ts));
        ts::return_shared(donation);
    }

    #[test_only]
    public fun testEndDonation(ts: &mut ts::Scenario, sender: address, clock: &Clock) {
        ts::next_tx(ts, sender);
        let donation = ts::take_shared<Donation>(ts);
        endDonation(&mut donation, clock);
        ts::return_shared(donation);
    }

    #[test_only]
    public fun testGetDonorRecords(ts: &mut ts::Scenario, donation: &Donation) -> vector<DonorRecord> {
        getDonorRecords(donation)
    }

    #[test]
    fun test_donation_platform(){
        let ts = ts::begin(@0x0);
        let clock = clock::create_for_testing(ts::ctx(&mut ts));

        // start donation
        {
            ts::next_tx(&mut ts, @0x0);

            let donationGoal: u64 = 100; // 100 SUI
            let donationDuration: u64 = 50; // 50 ticks

            startDonation(donationGoal, donationDuration, &clock, ts::ctx(&mut ts));
        };

        // donate
        {
            testDonate(&mut ts, Donor1, 30, &clock);
            testDonate(&mut ts, Donor2, 20, &clock);
            testDonate(&mut ts, Donor3, 50, &clock);
        };

        // increase time to donation end
        {
            clock::increment_for_testing(&mut clock, 55);
        };

        // end donation
        {
            testEndDonation(&mut ts, @0x0, &clock);
        };

        // test get donor records
        {
            let donation = ts::take_shared::<Donation>(&ts);
            testGetDonorRecords(&mut ts, &donation);
            ts::return_shared(donation);
        }

        clock::destroy_for_testing(clock);
        ts::end(ts);
    }
}
