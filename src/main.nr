use dep::aztec::macros::aztec;




#[aztec]
pub contract Bundler {
    use std::{meta::derive, ops::{Add, Sub}};
    use token::Token;

    use dep::aztec::{
        context::{PrivateCallInterface, PrivateContext},
        encrypted_logs::log_assembly_strategies::default_aes128::{
            event::encode_and_encrypt_event_unconstrained,
            note::{encode_and_encrypt_note, encode_and_encrypt_note_unconstrained},
        },
        event::event_interface::EventInterface,
        macros::{
            events::event,
            functions::{initializer, internal, private, public, view},
            storage::storage,
        },
        prelude::{AztecAddress, Map, PublicContext, PublicImmutable, PublicMutable},
        protocol_types::traits::Serialize,
    };
    
    use dep::authwit::auth::{
        assert_current_call_valid_authwit, 
        assert_current_call_valid_authwit_public,
        compute_authwit_nullifier,
    };

    #[storage]
    struct Storage<Context> {
        admin: PublicImmutable<AztecAddress, Context>,
    }

    #[public]
    #[initializer]
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin address");
    
        storage.admin.initialize(admin);
    }


    /// Send n Stable tokens and m Reward tokens to an address (public version)
    /// 
    /// This function bundles two public token transfers into a single transaction
    #[public]
    fn send_tokens_public(
        to: AztecAddress, 
        reward_token: AztecAddress,
        stable_token: AztecAddress,
        stable_amount: u128, 
        reward_amount: u128
    ) {
        let from = context.msg_sender();
        let nonce = 0 as Field; // No AuthWit, sending as self
        
        // Send stable tokens
        if (stable_amount > 0) {
            Token::at(stable_token)
                .transfer_in_public(from, to, stable_amount, nonce)
                .call(&mut context);
        }
        
        // Send reward tokens
        if (reward_amount > 0) {
            Token::at(reward_token)
                .transfer_in_public(from, to, reward_amount, nonce)
                .call(&mut context);
        }
    }
    
    /// Send n Stable tokens and m Reward tokens to an address (private version)
    /// 
    /// This function bundles two private token transfers into a single transaction
    #[private]
    fn send_tokens_private(
        to: AztecAddress, 
        reward_token: AztecAddress,
        stable_token: AztecAddress,
        stable_amount: u128, 
        reward_amount: u128
    ) {
        let from = context.msg_sender();
        let nonce = 0 as Field; // No AuthWit, sending as self
        
        // Send stable tokens
        if (stable_amount > 0) {
            Token::at(stable_token)
                .transfer_in_private(from, to, stable_amount, nonce)
                .call(&mut context);
        }
        
        // Send reward tokens
        if (reward_amount > 0) {
            Token::at(reward_token)
                .transfer_in_private(from, to, reward_amount, nonce)
                .call(&mut context);
        }
    }
    
    /// Pay oneself Stable tokens from a given address using AuthWit, and send Reward tokens to that address
    /// Public version of the function for public token balances
    #[public]
    fn exchange_tokens_public(
        from: AztecAddress, 
        stable_token: AztecAddress,
        reward_token: AztecAddress,
        stable_amount: u128, 
        reward_amount: u128,
        nonce: Field
    ) {
        let to = context.msg_sender(); // The caller will receive the stable tokens
        
        // Take stable tokens from 'from' to 'to' (caller) using AuthWit
        if (!from.eq(to)) {
            // If sender is not the caller, we need to validate authwit
            assert_current_call_valid_authwit_public(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }
        
        // Pull stable tokens from 'from' address to caller
        if (stable_amount > 0) {
            Token::at(stable_token)
                .transfer_in_public(from, to, stable_amount, nonce)
                .call(&mut context);
        }
        
        // Send reward tokens from caller to 'from' address
        if (reward_amount > 0) {
            let reward_nonce = 0 as Field; // No AuthWit needed as caller is sending their own tokens
            Token::at(reward_token)
                .transfer_in_public(to, from, reward_amount, reward_nonce)
                .call(&mut context);
        }
    }
    
    /// Pay oneself Stable tokens from a given address using AuthWit, and send Reward tokens to that address
    /// Private version of the function for private token balances
    #[private]
    fn exchange_tokens_private(
        from: AztecAddress, 
        stable: AztecAddress,
        reward: AztecAddress,
        stable_amount: u128, 
        reward_amount: u128,
        nonce: Field
    ) {
        let to = context.msg_sender(); // The caller will receive the stable tokens
        
        // Take stable tokens from 'from' to 'to' (caller) using AuthWit
        if (!from.eq(to)) {
            // If sender is not the caller, we need to validate authwit
            if (stable_amount > 0) {
                assert_current_call_valid_authwit(&mut context, from);
            }
        } else {
            assert(nonce == 0, "invalid nonce");
        }
        
        // Pull stable tokens from 'from' address to caller
        if (stable_amount > 0) {
            Token::at(stable)
                .transfer_in_private(from, to, stable_amount, nonce)
                .call(&mut context);
        }
        
        // Send reward tokens from caller to 'from' address
        if (reward_amount > 0) {
            let reward_nonce = 0 as Field; // No AuthWit needed as caller is sending their own tokens
            Token::at(reward)
                .transfer_in_private(to, from, reward_amount, reward_nonce)
                .call(&mut context);
        }
    }
    
    /// Cancel an authentication witness for the stable token
    #[private]
    fn cancel_stable_authwit(inner_hash: Field) {
        let on_behalf_of = context.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        context.push_nullifier(nullifier);
    }
    
    /// Cancel an authentication witness for the reward token
    #[private]
    fn cancel_reward_authwit(inner_hash: Field) {
        let on_behalf_of = context.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        context.push_nullifier(nullifier);
    }

    
}