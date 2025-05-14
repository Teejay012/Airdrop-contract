// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {

    error ClaimAirdropScript__InvalidSignatureLength();


    address private CLAIM_ADDRESS = 0x186159375129Bc6ae88dA802977FdA3D2A6f80d3;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 private proofOne = 0x3e991e48378c71cd6b59e423a0274cdbad1b8424cae0ef5136632e6d5dc99a4b;
    bytes32 private proofTwo = 0xc73f89e1361377f47a78440b3aded977e1c50414af3a4e425739283f6d126792;
    bytes32[] private PROOF = [proofOne, proofTwo];
    bytes private SIGNATURE = hex"e57de8ab296a6c4b294ee3cee25893d0cd045c3b1c0f4ad42476b21b4c26cbba18e09d56638fe3d3ea4191ced89a9d97cc2bdedffdfa2a017846f3678619e5901c";

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdrop).claim(CLAIM_ADDRESS, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() public {
        address moastRecentlyDeployedContract = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(moastRecentlyDeployedContract);
    }
}