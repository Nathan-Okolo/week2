//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint32 public treelevels;
    mapping (uint256 => uint256) internal zeros;
    uint8 internal constant MAX_DEPTH = 3;
    uint8 internal constant LEAVES_PER_NODE = 5;
    uint256 internal nextLeafIndex = 0;
    mapping (uint256 => mapping (uint256 => uint256)) internal filledSubtrees;
    mapping (uint256 => bool) public rootHistory;
    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);






    constructor(uint8 _treeLevels, uint256 _zeroValue) {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
                require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            "IncrementalQuinTree: _treeLevels must be between 0 and 3"
        );
        treelevels = _treeLevels;
        uint256 currentZero = _zeroValue;

        uint256[LEAVES_PER_NODE] memory temp;

        for (uint8 i = 0; i < _treeLevels; i++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = currentZero;
            }

            zeros[i] = currentZero;
            // currentZero = hash5(temp);
        }

        root = currentZero;
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        // Ensure that the tree is not full
        require(
            nextLeafIndex < uint256(LEAVES_PER_NODE) ** uint256(treelevels),
            "IncrementalQuinTree: tree is full"
        );

        uint256 currentIndex = nextLeafIndex;

        uint256 currentLevelHash = hashedLeaf;
        

        // hash5 requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        // The leaf's relative position within its node
        uint256 m = currentIndex % LEAVES_PER_NODE;

        for (uint8 i = 0; i < treelevels; i++) {
            // If the leaf is at relative index 0, zero out the level in
            // filledSubtrees
            if (m == 0) {
                for (uint8 j = 1; j < LEAVES_PER_NODE; j ++) {
                    filledSubtrees[i][j] = zeros[i];
                }
            }

            // Set the leaf in filledSubtrees
            filledSubtrees[i][m] = currentLevelHash;

            // Hash the level
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = filledSubtrees[i][j];
            }
            // currentLevelHash = temp;


            currentIndex /= LEAVES_PER_NODE;
            m = currentIndex % LEAVES_PER_NODE;
        }

        root = currentLevelHash;
        rootHistory[root] = true; 


        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(hashedLeaf, n);

        return currentIndex;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}