// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {Factory} from "../src/factory.sol";

contract DeployFactory is Script {
    
        function run() external returns (Factory) {
        vm.startBroadcast();
        Factory factory = new Factory();
        vm.stopBroadcast();
        return factory;
    }
}