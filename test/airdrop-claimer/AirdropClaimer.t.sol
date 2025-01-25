// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {AirdropClaimer} from "../../src/airdrop-claimer/AirdropClaimer.sol";
import {SimpleToken} from "../../src/token/SimpleToken.sol";

contract AirdropClaimerTest is Test {
    AirdropClaimer private claimer;
    uint256 private pk;
    address private signer;
    SimpleToken private token;
    uint256 constant TOTAL_SUPPLY = 1000000 * 10 ** 18;
    uint256 constant TOTAL_AIRDROP = 1 * 10 ** 18;

    function setUp() external {
        claimer = new AirdropClaimer();
        token = new SimpleToken(TOTAL_SUPPLY);
        (signer, pk) = makeAddrAndKey("alice");
        claimer.setClaimSigner(signer);
        token.approve(address(claimer), TOTAL_AIRDROP);
    }

    function testValidClaim() public {
        uint256 expiry = block.timestamp + 100;
        bytes memory memo = "test claim";
        uint256 total = TOTAL_AIRDROP / 2;
        uint256[] memory claimIndices = new uint256[](3);
        claimIndices[0] = 0;
        claimIndices[1] = 1;
        claimIndices[2] = 2;
        bytes32 hashValue = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(claimIndices, address(this), address(token), address(this), total, expiry, memo))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hashValue);
        bytes memory signature = abi.encodePacked(r, s, v);
        claimer.claim(address(token), address(this), total, claimIndices, signature, expiry, memo);
    }
}
