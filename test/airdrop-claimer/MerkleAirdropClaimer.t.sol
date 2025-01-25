// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdropClaimer} from "../../src/airdrop-claimer/MerkleAirdropClaimer.sol";
import {SimpleToken} from "../../src/token/SimpleToken.sol";
import "../../src/libraries/MerkleHelper.sol";

contract MerkleAirdropClaimerTest is Test {
    using MerkleHelper for bytes32[];

    MerkleAirdropClaimer private claimer;
    SimpleToken private token;
    Reward[] private rewards;
    bytes32[] private hashes;
    uint256 constant N = 3;
    uint256 constant TOTAL_SUPPLY = 1000000 * 10 ** 18;

    struct Reward {
        address to;
        uint256 amount;
    }

    function setUp() external {
        token = new SimpleToken(TOTAL_SUPPLY);
        uint256 totalAirdrop;
        for (uint256 i = 0; i < N; i++) {
            address to = address(uint160(i + 1));
            uint256 amount = i * 10;
            totalAirdrop += amount;
            rewards.push(Reward(to, amount));
            hashes.push(keccak256(abi.encodePacked(rewards[i].to, rewards[i].amount)));
        }
        bytes32 root = MerkleHelper.calculateRootBySorting(hashes);
        claimer = new MerkleAirdropClaimer(root, block.timestamp + 100, address(this));
        token.approve(address(claimer), totalAirdrop);
    }

    function testClaimWithValidUsers() public {
        for (uint256 i = 0; i < N; i++) {
            Reward memory reward = rewards[i];
            bytes32[] memory proof = MerkleHelper.getProofBySorting(hashes, i);
            claimer.claim(address(token), reward.to, reward.amount, proof);
        }
    }

    function testClaimWithInvalidUsers() public {
        for (uint256 i = 0; i < N; i++) {
            Reward memory reward = rewards[i];
            bytes32[] memory proof = MerkleHelper.getProofBySorting(hashes, i);
            vm.expectRevert();
            claimer.claim(address(token), reward.to, reward.amount + 10, proof);
        }
    }
}
