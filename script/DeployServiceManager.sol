// Used to deploy service manager
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ServiceManager} from "../src/ServiceManager.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {AVSDirectory} from "eigenlayer-contracts/src/contracts/core/AVSDirectory.sol";
import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";

contract DeployServiceManager is Script {

    // Eigen Core Contracts
    address internal constant AVS_DIRECTORY = 0xdAbdB3Cd346B7D5F5779b0B614EdE1CC9DcBA5b7; 
    address internal constant DELEGATION_MANAGER = 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A;

    
    address internal deployer;
    address internal operator;
    ServiceManager serviceManager;

    // setup
    function setUp() public virtual {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY")); // derive deployers address from private key created by Anvil
        operator = vm.rememberKey(vm.envUint("OPERATOR_PRIVATE_KEY")); // derive operators address from private key created by Anvil
        vm.label(deployer, "Deployer");
        vm.label(operator, "Operator");
    }

    // Deploy contract
    function run() public {
        vm.startBroadcast(deployer);
        serviceManager = new ServiceManager(AVS_DIRECTORY);
        vm.stopBroadcast();

        // Register operator to eigenlayer
        IDelegationManager delegationManager = IDelegationManager(DELEGATION_MANAGER);
        IDelegationManager.OperatorDetails memory operators = IDelegationManager.OperatorDetails({
            rewardReceiver: operator,
            delgationApprover: address(0), // no need for now 
            stakerOptOutWindowBlocks: 0 // no need for now 
        });

        vm.startBroadcast(operator);
        delegationManager.registerAsOperator(operatorDetails, "");
        vm.stopBroadcast();

        // Register operator to AVS
        AVSDirectory avsDirectory = AVSDirectory(AVS_DIRECTORY);
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, operator)); // concat timestamp n operator
        uint256 expiry = block.timestamp + 1 hours; // signature expiry

        // create hash for signing
        bytes32 operatorRegistrationDigestHash = avsDirectory 
            .calculateOperatorAVSRegistrationDigestHash(
                operator,
                address(serviceManager),
                salt,
                expiry
            );

        // sign and bundle into 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("OPERATOR_PRIVATE_KEY"),
            operatorRegistrationDigestHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // passed to service manager during registration  
        ISignatureUtils.SignatureWithSaltAndExpiry
            memory operatorSignature = ISignatureUtil.SignatureWithSaltAndExpiry({
                    signature: signature,
                    salt: salt,
                    expiry: expiry
                });

        vm.startBroadcast(operator);
        serviceManager.registerOperatorToAVS(operator, operatorSignature);
        vm.stopBroadcast();

    }


}