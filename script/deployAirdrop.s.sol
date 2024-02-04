// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {Airdrop} from "../src/airdrop.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployAirdrop is Script {

    function run() external returns (Airdrop) {
        HelperConfig helperConfig = new HelperConfig();
        (address token, uint128 airdropTime, uint256 registrationFee) = helperConfig.activeNetworkConfig();        
        vm.startBroadcast();
        Airdrop airdrop = new Airdrop(
            token,
            airdropTime,
            registrationFee
        );
        vm.stopBroadcast();
        return airdrop;
    }
}