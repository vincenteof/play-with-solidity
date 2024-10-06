// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/MerkleProof.sol";

contract MerkleProofTest is Test {
    using MerkleProof for bytes32[];

    bytes32 private root;
    bytes32 private leaf1;
    bytes32 private leaf2;
    bytes32 private leaf3;
    bytes32 private leaf4;

    bytes32[] private proofForLeaf1;
    bytes32[] private proofForLeaf2;
    bytes32[] private proofForLeaf3;
    bytes32[] private proofForLeaf4;
    bytes32 private sortedRoot;
    bytes32[] private sortedProofForLeaf1;
    bytes32[] private sortedProofForLeaf2;
    bytes32[] private sortedProofForLeaf3;
    bytes32[] private sortedProofForLeaf4;

    function setUp() public {
        // Example Merkle Tree:
        //        root
        //       /    \
        //   hash12  hash34
        //   /  \    /   \
        //leaf1 leaf2 leaf3 leaf4

        leaf1 = keccak256(abi.encodePacked("leaf1"));
        leaf2 = keccak256(abi.encodePacked("leaf2"));
        leaf3 = keccak256(abi.encodePacked("leaf3"));
        leaf4 = keccak256(abi.encodePacked("leaf4"));

        bytes32 hash12 = keccak256(abi.encodePacked(leaf1, leaf2));
        bytes32 hash34 = keccak256(abi.encodePacked(leaf3, leaf4));
        bytes32 sortedHash12 = leaf1 < leaf2
            ? keccak256(abi.encodePacked(leaf1, leaf2))
            : keccak256(abi.encodePacked(leaf2, leaf1));
        bytes32 sortedHash34 = leaf3 < leaf4
            ? keccak256(abi.encodePacked(leaf3, leaf4))
            : keccak256(abi.encodePacked(leaf4, leaf3));

        root = keccak256(abi.encodePacked(hash12, hash34));
        sortedRoot = sortedHash12 < sortedHash34
            ? keccak256(abi.encodePacked(sortedHash12, sortedHash34))
            : keccak256(abi.encodePacked(sortedHash34, sortedHash12));

        // Proof for leaf1: [leaf2, hash34]
        proofForLeaf1 = new bytes32[](2);
        proofForLeaf1[0] = leaf2;
        proofForLeaf1[1] = hash34;
        sortedProofForLeaf1 = new bytes32[](2);
        sortedProofForLeaf1[0] = leaf2;
        sortedProofForLeaf1[1] = sortedHash34;

        // Proof for leaf2: [leaf1, hash34]
        proofForLeaf2 = new bytes32[](2);
        proofForLeaf2[0] = leaf1;
        proofForLeaf2[1] = hash34;
        sortedProofForLeaf2 = new bytes32[](2);
        sortedProofForLeaf2[0] = leaf1;
        sortedProofForLeaf2[1] = sortedHash34;

        // Proof for leaf3: [leaf4, hash12]
        proofForLeaf3 = new bytes32[](2);
        proofForLeaf3[0] = leaf4;
        proofForLeaf3[1] = hash12;
        sortedProofForLeaf3 = new bytes32[](2);
        sortedProofForLeaf3[0] = leaf4;
        sortedProofForLeaf3[1] = sortedHash12;

        // Proof for leaf4: [leaf3, hash12]
        proofForLeaf4 = new bytes32[](2);
        proofForLeaf4[0] = leaf3;
        proofForLeaf4[1] = hash12;
        sortedProofForLeaf4 = new bytes32[](2);
        sortedProofForLeaf4[0] = leaf3;
        sortedProofForLeaf4[1] = sortedHash12;
    }

    // --------------------- Tests for verify ---------------------

    function test_verify_ValidProofLeaf1() public view {
        bool valid = MerkleProof.verify(proofForLeaf1, root, leaf1, 0);
        assertTrue(valid, "Valid proof for leaf1 should pass");
    }

    function test_verify_ValidProofLeaf2() public view {
        bool valid = MerkleProof.verify(proofForLeaf2, root, leaf2, 1);
        assertTrue(valid, "Valid proof for leaf2 should pass");
    }

    function test_verify_ValidProofLeaf3() public view {
        bool valid = MerkleProof.verify(proofForLeaf3, root, leaf3, 2);
        assertTrue(valid, "Valid proof for leaf3 should pass");
    }

    function test_verify_ValidProofLeaf4() public view {
        bool valid = MerkleProof.verify(proofForLeaf4, root, leaf4, 3);
        assertTrue(valid, "Valid proof for leaf4 should pass");
    }

    function test_verify_InvalidProof_WrongLeaf() public view {
        bool valid = MerkleProof.verify(proofForLeaf1, root, leaf2, 0);
        assertFalse(valid, "Invalid proof with wrong leaf should fail");
    }

    function test_verify_InvalidProof_WrongProofElement() public view {
        bytes32[] memory wrongProof = proofForLeaf1;
        wrongProof[0] = keccak256(abi.encodePacked("wrong"));
        bool valid = MerkleProof.verify(wrongProof, root, leaf1, 0);
        assertFalse(
            valid,
            "Invalid proof with wrong proof element should fail"
        );
    }

    function test_verify_InvalidProof_WrongRoot() public view {
        bytes32 wrongRoot = keccak256(abi.encodePacked("wrong root"));
        bool valid = MerkleProof.verify(proofForLeaf1, wrongRoot, leaf1, 0);
        assertFalse(valid, "Invalid proof with wrong root should fail");
    }

    function test_verify_EmptyProof() public view {
        bytes32[] memory emptyProof;
        bool valid = MerkleProof.verify(emptyProof, leaf1, leaf1, 0);
        assertTrue(valid, "Empty proof where leaf equals root should pass");

        bool invalid = MerkleProof.verify(emptyProof, root, leaf1, 0);
        assertFalse(
            invalid,
            "Empty proof where leaf does not equal root should fail"
        );
    }

    // --------------------- Tests for verifyBySorting ---------------------

    function test_verifyBySorting_ValidProofLeaf1() public view {
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf1,
            sortedRoot,
            leaf1
        );
        assertTrue(valid, "Valid sorted proof for leaf1 should pass");
    }

    function test_verifyBySorting_ValidProofLeaf2() public view {
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf2,
            sortedRoot,
            leaf2
        );
        assertTrue(valid, "Valid sorted proof for leaf2 should pass");
    }

    function test_verifyBySorting_ValidProofLeaf3() public view {
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf3,
            sortedRoot,
            leaf3
        );
        assertTrue(valid, "Valid sorted proof for leaf3 should pass");
    }

    function test_verifyBySorting_ValidProofLeaf4() public view {
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf4,
            sortedRoot,
            leaf4
        );
        assertTrue(valid, "Valid sorted proof for leaf4 should pass");
    }

    function test_verifyBySorting_InvalidProof_WrongLeaf() public view {
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf1,
            sortedRoot,
            leaf2
        );
        assertFalse(valid, "Invalid sorted proof with wrong leaf should fail");
    }

    function test_verifyBySorting_InvalidProof_WrongProofElement() public view {
        bytes32[] memory wrongProof = proofForLeaf1;
        wrongProof[0] = keccak256(abi.encodePacked("wrong"));
        bool valid = MerkleProof.verifyBySorting(wrongProof, sortedRoot, leaf1);
        assertFalse(
            valid,
            "Invalid sorted proof with wrong proof element should fail"
        );
    }

    function test_verifyBySorting_InvalidProof_WrongRoot() public view {
        bytes32 wrongRoot = keccak256(abi.encodePacked("wrong root"));
        bool valid = MerkleProof.verifyBySorting(
            sortedProofForLeaf1,
            wrongRoot,
            leaf1
        );
        assertFalse(valid, "Invalid sorted proof with wrong root should fail");
    }

    function test_verifyBySorting_EmptyProof() public view {
        bytes32[] memory emptyProof;
        bool valid = MerkleProof.verifyBySorting(emptyProof, leaf1, leaf1);
        assertTrue(
            valid,
            "Empty sorted proof where leaf equals root should pass"
        );

        bool invalid = MerkleProof.verifyBySorting(emptyProof, root, leaf1);
        assertFalse(
            invalid,
            "Empty sorted proof where leaf does not equal root should fail"
        );
    }
}
