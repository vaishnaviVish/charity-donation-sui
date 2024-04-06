# Charity Donation Platform

A decentralized application (DApp) for facilitating charity donations.

## Overview

- The Charity Donation Platform allows users to create donation events, contribute funds, and track donation progress.
- Donors can contribute to ongoing donation campaigns, and the platform ensures transparency and accountability.
- At the end of each donation event, donors can verify the outcome, and the donated funds are allocated according to the campaign's goals.

## Features

- **Create Donation Events:** Users can initiate new donation campaigns, setting goals and durations for fundraising.
- **Contribute Funds:** Donors can contribute funds to ongoing donation events securely and transparently.
- **Track Donation Progress:** The platform provides real-time tracking of donation progress, ensuring transparency and accountability.
- **Verify Donations:** Donors can verify the outcome of donation events and ensure that funds are allocated according to the campaign's goals.

## Dependency

- This DApp relies on the Sui blockchain framework for its smart contract functionality.
- Ensure you have the Move compiler installed and configured to the appropriate framework (e.g., `framework/devnet` for Devnet or `framework/testnet` for Testnet).

```bash
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/devnet" }
```

## Installation

Follow these steps to deploy and use the Charity Donation Platform:

1. **Move Compiler Installation:**
   Ensure you have the Move compiler installed. Refer to the [Sui documentation](https://docs.sui.io/) for installation instructions.

2. **Compile the Smart Contract:**
   Switch the dependencies in the `Sui` configuration to match your chosen framework (`framework/devnet` or `framework/testnet`), then build the contract.

   ```bash
   sui move build
   ```

3. **Deployment:**
   Deploy the compiled smart contract to your chosen blockchain platform using the Sui command-line interface.

   ```bash
   sui client publish --gas-budget 100000000 --json
   ```

## Note

- The Charity Donation Platform leverages randomness from the drand service for certain operations, ensuring fairness and unpredictability.
- The randomness is sourced from the drand quicknet chain, which generates verifiable random 32-byte outputs every 3 seconds. For more details, refer to the [drand documentation](https://drand.love/).
- Re-running tests for a specific round may yield the same results if the inputs remain unchanged. However, altering the round or updating the signature will produce different outcomes.
- Ensure that you update the signature when changing the round to maintain result integrity.