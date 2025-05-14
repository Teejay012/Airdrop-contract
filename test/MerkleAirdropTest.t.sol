// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "src/MerkleAirdrop.sol";
import { BagelToken } from "src/BagelToken.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import { DeployMerkleAirdrop } from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop airdrop;
    BagelToken token;

    bytes32 private constant MERKLE_ROOT =
        0x3e991e48378c71cd6b59e423a0274cdbad1b8424cae0ef5136632e6d5dc99a4b;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 private constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 private proofOne = 0xc73f89e1361377f47a78440b3aded977e1c50414af3a4e425739283f6d126792;
    bytes32 private proofTwo = 0x6faf2a16002ed3ddb5d372bffbe0f0f3f7141a9536e983cce95f3b40a4590346;
    bytes32[] private PROOF = [
        proofOne,
        proofTwo
    ];

    address USER;
    uint256 USER_PRIVATE_KEY;
    address GAS_PAYER;

    function setUp() public {
        token = new BagelToken();
        airdrop = new MerkleAirdrop(token, MERKLE_ROOT);
        (
            USER,
            USER_PRIVATE_KEY
        ) = makeAddrAndKey("user");
        token.mint(address(airdrop), AMOUNT_TO_SEND);

        GAS_PAYER = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 userStartingBalance = token.balanceOf(USER);
        bytes32 digest = airdrop.getMessageHash(USER, AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER_PRIVATE_KEY, digest);

        vm.startPrank(GAS_PAYER);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 userEndingBalance = token.balanceOf(USER);
        vm.stopPrank();
        assert(userEndingBalance - userStartingBalance == AMOUNT_TO_CLAIM);
        assert(airdrop.getHasClaimed(USER) == true);
    }
}