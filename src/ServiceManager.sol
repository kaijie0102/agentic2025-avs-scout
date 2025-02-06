// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol"; // methods for signing
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol"; // manage operators  
import {ECDSA} from "solady/utils/ECDSA.sol"; // algo for signing

contract ServiceManager {
    using ECDSA for bytes32;

    // attributes
    address public immutable avsDirectory; // manage operators


    struct Task {
        string contents;
        uint32 taskCreatedBlock;
    }
    
    constructor(address _avsDirectory) {
        avsDirectory = _avsDirectory;
    }


    // Registering operators
    // Deregistering operators
    // Create Task
    // Respons to Task
}