// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommitmentStorage {
    // Event declarations
    event CommitmentAdded(uint256 index, bytes32 commitment);
    event CommitmentNullified(bytes32 commitment);

    // Function declarations
    function addCommitment(bytes32 commitment) external;
    function nullifyCommitment(bytes32 commitment) external;
}

contract CommitmentStorage {
    // Array to store commitments
    bytes32[] public commitments;

    // Mapping to check if a commitment has been nullified
    mapping(bytes32 => bool) public isNullified;

    // Event to emit when a commitment is added
    event CommitmentAdded(uint256 index, bytes32 commitment);

    // Event to emit when a commitment is nullified
    event CommitmentNullified(bytes32 commitment);

    // Function to add a new commitment
    function addCommitment(bytes32 commitment) public {
        commitments.push(commitment);
        emit CommitmentAdded(commitments.length - 1, commitment);
    }

    // Function to nullify a commitment
    function nullifyCommitment(bytes32 commitment) public {
        require(!isNullified[commitment], "Commitment already nullified");
        isNullified[commitment] = true;
        emit CommitmentNullified(commitment);
    }
}

