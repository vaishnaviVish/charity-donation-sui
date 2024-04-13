#[test_only]
module charity::test_game {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::coin::{Self, Coin, mint_for_testing};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::test_utils::{assert_eq};
    use sui::clock::{Self, Clock};
    use sui::transfer::{Self};

    use std::vector;
    use std::string::{Self, String};

    use charity::game::{Self, Donation, DonorRecord};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;

    #[test]
    public fun test_game() {

        let scenario_test = ts::begin(ADMIN);
        let scenario = &mut scenario_test;

        next_tx(scenario, TEST_ADDRESS1);
        {
            let clock = clock::create_for_testing(ts::ctx(scenario));
            let target: u64 = 10000_000_000_000;
            let duration = 1000;

            game::new(target, duration, &clock, ts::ctx(scenario));

            clock::share_for_testing(clock); 
        };
        // Address1 donates
        next_tx(scenario, TEST_ADDRESS1); 
        {
            let donation = ts::take_shared<Donation>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let coin_ = mint_for_testing<SUI>(1000_000_000_000, ts::ctx(scenario));

            assert_eq(game::getDonationGoal(&donation), 10000_000_000_000);

            game::donate(&mut donation, coin_, &clock, ts::ctx(scenario));

            assert_eq(game::getTotalDonated(&donation), 1000_000_000_000);

            ts::return_shared(clock);
            ts::return_shared(donation);
        };
        // Address2 donates
        next_tx(scenario, TEST_ADDRESS2); 
        {
            let donation = ts::take_shared<Donation>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let coin_ = mint_for_testing<SUI>(1000_000_000_000, ts::ctx(scenario));
            
            game::donate(&mut donation, coin_, &clock, ts::ctx(scenario));

            assert_eq(game::getTotalDonated(&donation), 2000_000_000_000);

            ts::return_shared(clock);
            ts::return_shared(donation);
        };
        // Address3 donates
        next_tx(scenario, TEST_ADDRESS3); 
        {
            let donation = ts::take_shared<Donation>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            let coin_ = mint_for_testing<SUI>(1000_000_000_000, ts::ctx(scenario));
            
            game::donate(&mut donation, coin_, &clock, ts::ctx(scenario));

            assert_eq(game::getTotalDonated(&donation), 3000_000_000_000);

            ts::return_shared(clock);
            ts::return_shared(donation);
        };
        // check the DonorRecord object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let donor_record = ts::take_from_sender<DonorRecord>(scenario);

            ts::return_to_sender(scenario, donor_record);
        };
        // check the DonorRecord object
        next_tx(scenario, TEST_ADDRESS2);
        {
            let donor_record = ts::take_from_sender<DonorRecord>(scenario);

            ts::return_to_sender(scenario, donor_record);
        };
        // check the DonorRecord object
        next_tx(scenario, TEST_ADDRESS3);
        {
            let donor_record = ts::take_from_sender<DonorRecord>(scenario);

            ts::return_to_sender(scenario, donor_record);
        };

        // end donation
        next_tx(scenario, TEST_ADDRESS1);
        {
            let donation = ts::take_shared<Donation>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, (86400 * 30 * 1000));

            game::endDonation(&mut donation, &clock, ts::ctx(scenario));

            ts::return_shared(clock);
            ts::return_shared(donation);
        };

        next_tx(scenario, TEST_ADDRESS1);
        {
            let user_balance = ts::take_from_sender<Coin<SUI>>(scenario);
            assert_eq(coin::value(&user_balance), 3000_000_000_000);

            ts::return_to_sender(scenario,user_balance);
        };
        ts::end(scenario_test);
    }
} 
     