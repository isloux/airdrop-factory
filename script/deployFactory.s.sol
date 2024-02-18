// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {Factory} from "../src/factory.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployFactory is Script {
    function run() external returns (Factory) {
        HelperConfig helperConfig = new HelperConfig();
        (address token, , uint256 fee, address treasury) = helperConfig
            .activeNetworkConfig();
        vm.startBroadcast();
        Factory factory = new Factory(token, fee, treasury);
        vm.stopBroadcast();
        return factory;
    }
}
