// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommitmentStorage} from "./CommitmentStorage.sol";

//TODO add necessary inheritance like reentrancy guard and merkletree

contract DepositWithdrawManager is Deployer, SPI1Verifier {

    ICommitmentStorage commitmentStorage;

    constructor(ICommitmentStorage _commStorage) {
        commitmentStorage = _commStorage;
    }

    function register(Account memory _account) public {
        require(_account.owner == msg.sender, "only owner can register");
        emit PublicKey(_account.owner, _account.publicKey);
    }

    function transact(Proof memory _args, ExtData memory _extData) public {
        require(_extData.extAmount == 1 ether, "Deposit amount must be only 1 ether");
        token.transferFrom(msg.sender, address(this), uint256(_extData.extAmount));
        _transact(_args, _extData);
    }

    function registerAndTransact(Account memory _account, Proof memory _proof, ExtData memory _extData) public {
        register(_account);
        transact(_proof, _extData);

    }

    //relayer will listen to this
    function addLiquidity(uint256 amount0, uint256 amount1) public {}

    function swapToOtherAccount(uint256 amountIn, uint256 amountOutMin, address recipient) public {}


}