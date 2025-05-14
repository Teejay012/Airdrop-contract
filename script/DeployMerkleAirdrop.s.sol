// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { MerkleAirdrop } from "src/MerkleAirdrop.sol";
import { BagelToken } from "src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private s_merkleRoot = 0x3e991e48378c71cd6b59e423a0274cdbad1b8424cae0ef5136632e6d5dc99a4b;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 private constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    function deployMerkleAirdrop() public returns (BagelToken token, MerkleAirdrop airdrop) {
        vm.startBroadcast();
        token = new BagelToken();
        airdrop = new MerkleAirdrop(token, s_merkleRoot);
        token.mint(address(airdrop), AMOUNT_TO_SEND);
        vm.stopBroadcast();
    }

    function run() public {
        deployMerkleAirdrop();
    }
}