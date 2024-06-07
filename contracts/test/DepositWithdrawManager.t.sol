// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Fibonacci} from "../src/Fibonacci.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {DespoitWithdrawManager} from "../src/DepositWithdrawManager.sol";
import {CommitmentStorage, ICommitmentStorage} from "../src/CommitmentStorage.sol";
import {UTXO} from "../src/UTXO.sol"

contract DepositWithdrawManagerTest is Test {

    DepositWithdrawManager manager;
    CommitmentStorage commitmentStorage;
    UTXO utxoManager;
    address bob = address(0x1)

    function setUp() public {
        commitmentStorage = new CommitmentStorage;
        manager = new DepositWithdrawManager(commitmentStorage);
        utxoManager = new UTXO;
        createNewWallet
    }

    function testRegisterAndDeposit() public {

        //some proving logic or something
        manager.verifyProof
        manager.registerAndTransact(

        )
    }


}
