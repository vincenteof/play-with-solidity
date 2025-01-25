// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Bitmap} from "solady/utils/g/LibBitmap.sol";

contract AirdropClaimer is Ownable {
    Bitmap internal _claimed;

    address public claimSigner;

    event Claimed(address by, address erc20, address to, uint256 total, uint256[] claimIndices, bytes memo);

    constructor() {
        _initializeOwner(msg.sender);
    }

    function isClaimed(uint256 claimIndex) public view returns (bool) {
        return _claimed.get(claimIndex);
    }

    function setClaimSigner(address newClaimSigner) public onlyOwner {
        claimSigner = newClaimSigner;
    }

    function claim(
        address erc20,
        address to,
        uint256 total,
        uint256[] memory claimIndices,
        bytes memory signature,
        uint256 expiry,
        bytes memory memo
    ) public {
        require(block.timestamp < expiry, "Expired");
        bytes32 hashValue = keccak256(abi.encode(claimIndices, msg.sender, erc20, to, total, expiry, memo));
        bytes32 signedHashValue = ECDSA.toEthSignedMessageHash(hashValue);
        require(ECDSA.recover(signedHashValue, signature) == claimSigner, "Invalid Signature");
        for (uint256 i; i < claimIndices.length; i++) {
            require(_claimed.toggle(claimIndices[i]), "Already Claimed");
        }
        SafeTransferLib.safeTransferFrom(erc20, owner(), to, total);
        emit Claimed(msg.sender, erc20, to, total, claimIndices, memo);
    }
}
