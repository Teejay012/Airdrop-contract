// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract  MerkleAirdrop is EIP712 {

    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AccountAlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    address[] claimers;

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;

    mapping (address claimer => bool claimed) private s_hasClaimed;

    event Claim(address indexed account, uint256 indexed amount);

    constructor(IERC20 airdropToken, bytes32 merkleRoot) EIP712("MerkleAirdrop", "1.0.0") {
        i_airdropToken = airdropToken;
        i_merkleRoot = merkleRoot;
    }

    function claim(address account, uint256 amount, bytes32[] memory merkleProof, uint8 v, bytes32 r, bytes32 s) public {

        if(s_hasClaimed[account]) {
            revert MerkleAirdrop__AccountAlreadyClaimed();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)){
            revert MerkleAirdrop__InvalidProof();
        }

        if(!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        s_hasClaimed[account] = true;

        emit Claim(account, amount);

        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})))
        );
    }

    function _isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, ECDSA.RecoverError err, ) = ECDSA.tryRecover(digest, v, r, s);
        return (err == ECDSA.RecoverError.NoError && actualSigner == account);
    }

    function getHasClaimed(address account) public view returns (bool) {
        return s_hasClaimed[account];
    }

    function getClaimers() public view returns (address[] memory) {
        return claimers;
    }
}