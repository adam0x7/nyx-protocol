//! A simple program that creates a new UTXO and its commitment for a deposit into a Tornado Cash-like protocol,
//! and adds the commitment to the CommitmentStorage contract on the Ethereum blockchain.

#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_sol_types::{sol, SolType};
use alloy_zkvm::prelude::*;
use alloy_zkvm::poseidon::Poseidon;
use web3::contract::{Contract, Options};
use web3::types::{Address, U256};

/// Represents a UTXO (Unspent Transaction Output).
#[derive(Clone, PartialEq, sp1_zkvm::io::SolidityAbi)]
pub struct Utxo {
    pub value: u256,
    pub owner: PublicKey,
}

/// The public values encoded as a tuple that can be easily deserialized inside Solidity.
type PublicValuesTuple = sol! {
    tuple(uint256, bytes32)
};

pub fn main() {
    // Read the deposit amount.
    let deposit_amount = sp1_zkvm::io::read::<u256>();

    // Read the recipient's public key.
    let recipient_public_key = sp1_zkvm::io::read::<PublicKey>();

    // Create a new UTXO with the deposit amount and recipient's public key.
    let new_utxo = Utxo {
        value: deposit_amount,
        owner: recipient_public_key,
    };

    // Create a commitment using the Poseidon hash function.
    let commitment = create_commitment(&new_utxo);

    // Add the commitment to the CommitmentStorage contract.
    add_commitment_to_contract(commitment);

    // Encode the public values of the program.
    let bytes = PublicValuesTuple::abi_encode(&(deposit_amount, commitment));

    // Commit to the public values of the program.
    sp1_zkvm::io::commit_slice(&bytes);

    // Print out the deposit amount, recipient's public key, and commitment.
    println!("Deposit amount: {}", deposit_amount);
    println!("Recipient's public key: {}", recipient_public_key);
    println!("Commitment: {:?}", commitment);
}

/// Creates a commitment using the Poseidon hash function.
fn create_commitment(utxo: &Utxo) -> [u8; 32] {
    let mut hasher = Poseidon::new();
    hasher.update(utxo.value.to_le_bytes());
    hasher.update(utxo.owner.to_bytes());
    hasher.finalize()
}

/// Adds the commitment to the CommitmentStorage contract.
fn add_commitment_to_contract(commitment: [u8; 32]) {
    // Set up the web3 connection.
    let transport = web3::transports::Http::new("http://localhost:8545").unwrap();
    let web3 = web3::Web3::new(transport);

    // Set the contract address and ABI.
    let contract_address = Address::from_str("0x1234567890123456789012345678901234567890").unwrap();
    let contract_abi = include_bytes!("path/to/contract/abi.json");

    // Create a contract instance.
    let contract = Contract::from_json(web3.eth(), contract_address, contract_abi).unwrap();

    // Call the addCommitment function.
    let commitment_bytes32 = H256::from_slice(&commitment);
    let result = contract.call("addCommitment", (commitment_bytes32,), Options::default(), None);

    // Handle the result.
    match result {
        Ok(_) => println!("Commitment added to the contract"),
        Err(e) => println!("Error adding commitment to the contract: {}", e),
    }
}