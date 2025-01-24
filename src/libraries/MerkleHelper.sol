// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MerkleHelper {
    function calculateRootBySorting(bytes32[] memory hashes) public pure returns (bytes32) {
        uint256 n = hashes.length;
        while (n > 1) {
            for (uint256 i = 0; i < n; i += 2) {
                bytes32 left = hashes[i];
                bytes32 right = i + 1 < n ? hashes[i + 1] : left;
                hashes[i / 2] =
                    left < right ? keccak256(abi.encodePacked(left, right)) : keccak256(abi.encodePacked(right, left));
            }
            n = (n + 1) / 2;
        }
        return hashes[0];
    }

    function getProofBySorting(bytes32[] memory hashes, uint256 index) public pure returns (bytes32[] memory proof) {
        uint256 n = hashes.length;
        require(index < n, "MerkleHelper: Invalid index");
        // the length of the proof is the height of the tree
        proof = new bytes32[](_log2(n));
        uint256 proofIndex = 0;
        while (n > 1) {
            // get proof for this level
            uint256 siblingIndex = index % 2 == 0 ? index + 1 : index - 1;
            if (siblingIndex > n - 1) {
                siblingIndex = index;
            }
            proof[proofIndex++] = hashes[siblingIndex];

            // calculate next level hashes
            for (uint256 i = 0; i < n; i += 2) {
                bytes32 left = hashes[i];
                bytes32 right = i + 1 < n ? hashes[i + 1] : left;
                hashes[i / 2] =
                    left < right ? keccak256(abi.encodePacked(left, right)) : keccak256(abi.encodePacked(right, left));
            }
            n = (n + 1) / 2;
            index /= 2;
        }
    }

    function _log2(uint256 x) internal pure returns (uint256 result) {
        require(x > 0, "Input must be greater than zero");
        while ((1 << result) < x) {
            result++;
        }
    }
}
