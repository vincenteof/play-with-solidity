// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Bitmap} from "solady/utils/g/LibBitmap.sol";
import "../libraries/MerkleProof.sol";

contract MerkleAirdropClaimer {
    using MerkleProof for bytes32[];

    mapping(bytes32 => bool) internal _claimed;
    bytes32 public immutable root;
    uint256 public expiry;
    address public treasury;

    event Claimed(address by, address erc20, address to, uint256 total);

    constructor(bytes32 _root, uint256 _expiry, address _treasury) {
        root = _root;
        expiry = _expiry;
        treasury = _treasury;
    }

    function _leafHash(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }

    function claim(address erc20, address to, uint256 amount, bytes32[] memory proof) public {
        require(block.timestamp < expiry, "Expired");
        bytes32 leaf = _leafHash(to, amount);
        require(!_claimed[leaf], "Already Claimed");
        require(proof.verifyBySorting(root, leaf), "Invalid Proof");
        _claimed[leaf] = true;
        SafeTransferLib.safeTransferFrom(erc20, treasury, to, amount);
        emit Claimed(msg.sender, erc20, to, amount);
    }
}
