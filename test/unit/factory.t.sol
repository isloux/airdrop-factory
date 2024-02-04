// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Test, Vm} from "forge-std/Test.sol";
import {Factory} from "../../src/factory.sol";
import {DeployFactory} from "../../script/deployFactory.s.sol";
import {HelperConfig} from "../../script/helperConfig.s.sol";

contract FactoryTest is Test {
    Factory factory;
    address s_token;
    uint256 s_registrationFee;
    uint128 s_airdropTime;
    address s_treasury;

    function setUp() external {
        DeployFactory deployFactory = new DeployFactory();
        HelperConfig helperConfig = new HelperConfig();
        (s_token, s_airdropTime, s_registrationFee, s_treasury) = helperConfig.activeNetworkConfig();
        factory = deployFactory.run();
    }

    function testGetTreasury() public {
        assertEq(factory.getTeasury(), s_treasury);
    }

    // How to check logs: https://book.getfoundry.sh/cheatcodes/get-recorded-logs?highlight=Vm.Log#examples

    function testCreateNewAirdrop() public {
        vm.recordLogs();
        vm.startBroadcast();
        factory.createNewAirdrop(s_token, s_airdropTime, s_registrationFee);
        vm.stopBroadcast();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);
        assertEq(entries[0].topics.length, 3); // Qu'est-ce qu'il y a dans l'entrée 0 ?
        assertEq(entries[1].topics.length, 2); // Pourquoi 2 ?
        assertEq(entries[1].topics[0], keccak256("ContractDeployed(address)"));
    }
}