# ImpayQ: Core Noir Contracts

This repository contains privacy-enabled smart contracts written in Noir for the Aztec Network, implementing a payment system with merchant management and bundled token transfers.

## Overview

![image](https://github.com/user-attachments/assets/2ced0065-4176-478b-b5cb-3d4d209be598)


ImpayQ is a privacy-focused payment system built on Aztec Network that allows:
- Merchant management and token assignment
- Bundled token transfers (both public and private)
- Token exchange with authorization mechanisms
- Secure account management

The system leverages Aztec's privacy features to enable confidential transactions while maintaining the flexibility needed for a modern payment infrastructure.

## Contract Architecture

### Merchants Contract (`merchants.nr`)

The Merchants contract manages merchant registration and token assignments:

- **Admin Management**: 
  - `constructor(admin)`: Initializes the contract with an admin address
  - `set_admin(new_admin)`: Allows the current admin to transfer admin rights

- **Merchant Operations**:
  - `add_merchant(merchant, token)`: Associates a merchant address with a specific token
  - `get_token(merchant)`: Returns the token address associated with a merchant

### Bundler Contract (`main.nr`)

The Bundler contract enables bundled token operations and exchange functionality:

- **Token Bundling**:
  - `send_tokens_public(to, reward_token, stable_token, stable_amount, reward_amount)`: Sends both stable and reward tokens in a single public transaction
  - `send_tokens_private(to, reward_token, stable_token, stable_amount, reward_amount)`: Same functionality as above but for private balances

- **Token Exchange**:
  - `exchange_tokens_public(from, stable_token, reward_token, stable_amount, reward_amount, nonce)`: Exchanges stable tokens for reward tokens using public balances
  - `exchange_tokens_private(from, stable, reward, stable_amount, reward_amount, nonce)`: Same as above but for private balances

- **Authorization Management**:
  - `cancel_stable_authwit(inner_hash)`: Cancels an authentication witness for stable token
  - `cancel_reward_authwit(inner_hash)`: Cancels an authentication witness for reward token

### Account Contract (`account/accounts.nr`)

The SchnorrHardcodedAccount contract implements secure authorization using Schnorr signatures:

- `entrypoint(app_payload, fee_payload, cancellable)`: Main entrypoint for account operations
- `verify_private_authwit(inner_hash)`: Verifies private authentication witnesses
- `is_valid_impl(_context, outer_hash)`: Implements signature verification using a hardcoded public key

## Key Features

1. **Privacy-Preserving Transactions**: Both public and private methods for token transfers and exchanges
2. **Authorization Witness (AuthWit)**: Secure delegation of transaction authority using cryptographic proofs
3. **Bundled Operations**: Multiple token operations in a single transaction, improving UX and reducing fees
4. **Admin-Controlled Merchant Registry**: Centralized management of merchants and their tokens

## Dependencies

The project relies on the following Aztec Network packages:
- `aztec`: Core library for Aztec contracts
- `authwit`: Authentication witness functionality
- `token`: Standard token contract interface

## Development

This project uses Nargo (Noir's package manager) for dependency management and compilation.

### Prerequisites

- Install [Nargo](https://noir-lang.org/getting_started/nargo_installation)
- Familiarity with [Aztec Network](https://docs.aztec.network/)

### Building and Testing

```bash
# Navigate to the contract directory
cd corecontracts

# Build the contracts
nargo build

# Test the contracts
nargo test
```

## Deployment

These contracts are designed to be deployed on the Aztec Network. Refer to the Aztec documentation for detailed deployment instructions.

## License

This project is licensed under the terms provided in the LICENSE file.

## Contributors

- ImpayQ Team
