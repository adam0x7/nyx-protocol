// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommitmentStorage} from "./CommitmentStorage.sol";

//TODO add necessary inheritance like reentrancy guard and merkletree

contract DepositWithdrawManager is Deployer, SPI1Verifier {
    struct Account {
        address owner;
        bytes publicKey;
    }

    struct Proof {
        bytes proof;
        bytes32 root;
        bytes32[] inputNullifiers;
        bytes32[2] outputCommitments;
        uint256 publicAmount;
        bytes32 extDataHash;
    }

    struct ExtData {
        address recipient;
        int256 extAmount;
        address relayer;
        uint256 fee;
        bytes encryptedOutput1;
        bytes encryptedOutput2;
        bool isL1Withdrawal;
        uint256 l1Fee;
    }

    event NewCommitment(bytes32 indexed commitment, uint256 index, bytes encryptedOutput);
    event NewNullifier(bytes32 indexed nullifier);
    event PublicKey(address indexed owner, bytes key);

    IERC20 public immutable token;

    mapping(bytes32 => bool) public nullifierHashes;
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
        // addLiquidity(, amount1);
    }

    //relayer will listen to this
    function addLiquidity(uint256 amount0, uint256 amount1) public {}

    function swapToOtherAccount(uint256 amountIn, uint256 amountOutMin, address recipient) public {}

    function _transact(Proof memory _args, ExtData memory _extData) internal nonReentrant {
        require(isKnownRoot(_args.root), "Invalid merkle root");
        for (uint256 i = 0; i < _args.inputNullifiers.length; i++) {
            require(!isSpent(_args.inputNullifiers[i]), "Input is already spent");
        }
        require(uint256(_args.extDataHash) == uint256(keccak256(abi.encode(_extData))) % FIELD_SIZE, "Incorrect external data hash");
        require(_args.publicAmount == calculatePublicAmount(_extData.extAmount, _extData.fee), "Invalid public amount");
        require(verifyProof(_args), "Invalid transaction proof");

        for (uint256 i = 0; i < _args.inputNullifiers.length; i++) {
            nullifierHashes[_args.inputNullifiers[i]] = true;
        }

        if (_extData.extAmount < 0) {
            require(_extData.recipient != address(0), "Can't withdraw to zero address");
            if (_extData.isL1Withdrawal) {
                token.transferAndCall(
                    omniBridge,
                    uint256(-_extData.extAmount),
                    abi.encodePacked(l1Unwrapper, abi.encode(_extData.recipient, _extData.l1Fee))
                );
            } else {
                token.transfer(_extData.recipient, uint256(-_extData.extAmount));
            }
        }
        if (_extData.fee > 0) {
            token.transfer(_extData.relayer, _extData.fee);
        }

        lastBalance = token.balanceOf(address(this));
        _insert(_args.outputCommitments[0], _args.outputCommitments[1]);
        emit NewCommitment(_args.outputCommitments[0], nextIndex - 2, _extData.encryptedOutput1);
        emit NewCommitment(_args.outputCommitments[1], nextIndex - 1, _extData.encryptedOutput2);
        for (uint256 i = 0; i < _args.inputNullifiers.length; i++) {
            emit NewNullifier(_args.inputNullifiers[i]);
        }
    }

    function _configureLimits(uint256 _maximumDepositAmount) internal {
        maximumDepositAmount = _maximumDepositAmount;
    }
}