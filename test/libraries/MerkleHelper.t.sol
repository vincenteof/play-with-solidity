// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../../src/libraries/MerkleHelper.sol";
import "../../src/libraries/MerkleProof.sol";

contract MerkleHelperTest is Test {
    function logBytes32Array(bytes32[] memory array) internal pure {
        for (uint256 i = 0; i < array.length; i++) {
            console.logBytes32(array[i]);
        }
    }

    function testCalculateRootBySorting() public pure {
        // Arrange
        bytes32[] memory hashes = new bytes32[](4);
        hashes[0] = keccak256("leaf1");
        hashes[1] = keccak256("leaf2");
        hashes[2] = keccak256("leaf3");
        hashes[3] = keccak256("leaf4");

        // Calculate expected root with sorting
        bytes32 tempHash1 = hashes[0] < hashes[1]
            ? keccak256(abi.encodePacked(hashes[0], hashes[1]))
            : keccak256(abi.encodePacked(hashes[1], hashes[0]));
        bytes32 tempHash2 = hashes[2] < hashes[3]
            ? keccak256(abi.encodePacked(hashes[2], hashes[3]))
            : keccak256(abi.encodePacked(hashes[3], hashes[2]));
        bytes32 expectedRoot = tempHash1 < tempHash2
            ? keccak256(abi.encodePacked(tempHash1, tempHash2))
            : keccak256(abi.encodePacked(tempHash2, tempHash1));

        // Act
        bytes32 actualRoot = MerkleHelper.calculateRootBySorting(hashes);

        // Assert
        assertEq(actualRoot, expectedRoot, "Roots do not match");
    }

    function testCalculateRootBySortingWithOddLeaves() public pure {
        // Arrange
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = keccak256("leaf1");
        hashes[1] = keccak256("leaf2");
        hashes[2] = keccak256("leaf3");

        // Calculate expected root with sorting
        bytes32 tempHash1 = hashes[0] < hashes[1]
            ? keccak256(abi.encodePacked(hashes[0], hashes[1]))
            : keccak256(abi.encodePacked(hashes[1], hashes[0]));

        bytes32 tempHash2 = keccak256(abi.encodePacked(hashes[2], hashes[2]));
        bytes32 expectedRoot = tempHash1 < tempHash2
            ? keccak256(abi.encodePacked(tempHash1, tempHash2))
            : keccak256(abi.encodePacked(tempHash2, tempHash1));
        // Act
        bytes32 actualRoot = MerkleHelper.calculateRootBySorting(hashes);

        // Assert
        assertEq(actualRoot, expectedRoot, "Roots do not match");
    }

    function testGetProofBySorting() public pure {
        bytes32[] memory hashes = new bytes32[](4);
        hashes[0] = keccak256("leaf1");
        hashes[1] = keccak256("leaf2");
        hashes[2] = keccak256("leaf3");
        hashes[3] = keccak256("leaf4");
        bytes32 root = MerkleHelper.calculateRootBySorting(hashes);
        bytes32[] memory proof = MerkleHelper.getProofBySorting(hashes, 2);
        logBytes32Array(proof);
        assertTrue(MerkleProof.verifyBySorting(proof, root, hashes[2]), "Proof is not valid");
    }

    function testGetProofBySortingWithFiveElements() public pure {
        bytes32[] memory hashes = new bytes32[](5);
        hashes[0] = keccak256("leaf1");
        hashes[1] = keccak256("leaf2");
        hashes[2] = keccak256("leaf3");
        hashes[3] = keccak256("leaf4");
        hashes[4] = keccak256("leaf5");
        bytes32 root = MerkleHelper.calculateRootBySorting(hashes);
        bytes32[] memory proof = MerkleHelper.getProofBySorting(hashes, 4);
        logBytes32Array(proof);
        assertTrue(MerkleProof.verifyBySorting(proof, root, hashes[4]), "Proof is not valid");
    }

    function testGetProofBySortingWithSixElements() public pure {
        bytes32[] memory hashes = new bytes32[](6);
        hashes[0] = keccak256("leaf1");
        hashes[1] = keccak256("leaf2");
        hashes[2] = keccak256("leaf3");
        hashes[3] = keccak256("leaf4");
        hashes[4] = keccak256("leaf5");
        hashes[4] = keccak256("leaf6");
        bytes32 root = MerkleHelper.calculateRootBySorting(hashes);
        bytes32[] memory proof = MerkleHelper.getProofBySorting(hashes, 5);
        logBytes32Array(proof);
        assertTrue(MerkleProof.verifyBySorting(proof, root, hashes[5]), "Proof is not valid");
    }
}
