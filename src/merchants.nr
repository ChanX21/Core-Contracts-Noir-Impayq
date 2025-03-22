use dep::aztec::macros::aztec;

#[aztec]
pub contract Merchants {

    // Libs [list all required libs]
    use std::{meta::derive, ops::{Add, Sub}};

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
        assert_current_call_valid_authwit, assert_current_call_valid_authwit_public,
        compute_authwit_nullifier,
    };

    //docs:start:storage_struct
    #[storage]
    struct Storage<Context> {
        admin: PublicMutable<AztecAddress, Context>,
        tokens: Map<AztecAddress, PublicMutable<AztecAddress, Context>, Context>, // if address is merchant, key is token address
    }

    #[public]
    #[initializer]
    // annotation to mark function as a constructor
    fn constructor(admin: AztecAddress) {
        storage.admin.write(admin);
    }

    // docs:start:set_admin
    #[public]
    fn set_admin(new_admin: AztecAddress) {
        assert(storage.admin.read().eq(context.msg_sender()), "caller is not admin");
        // docs:start:write_admin
        storage.admin.write(new_admin);
        // docs:end:write_admin
    }

    // docs:add_merchant
    #[public]
    fn add_merchant(merchant: AztecAddress, token: AztecAddress) {
        storage.tokens.at(merchant).write(token);
    }

    // docs:start:get_token
    #[public]
    #[view]
    fn get_token(merchant: AztecAddress) -> pub AztecAddress {
        storage.tokens.at(merchant).read()
    }

    // unconstrained fn get_token(merchant: AztecAddress) -> pub AztecAddress {
    //     storage.merchants.at(merchant).read()
    // }


}
