// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";

contract Utils {
    function createUsers(
        uint16 _numberOfUsers
    ) public pure returns (address[] memory) {
        address[] memory users = new address[](_numberOfUsers);
        for (uint160 i = 0; i < _numberOfUsers; i++) users[i] = address(i + 1);
        return users;
    }
}

contract BaseSetup is Test {
    Utils internal utils;
    address[] internal users;
    uint16 constant NUSERS = 3;

    address internal alice;
    address internal bob;
    address internal mallory;

    constructor() {
        utils = new Utils();
        users = utils.createUsers(NUSERS);
        alice = users[0];
        vm.label(alice, "Alice"); // Labels to show names instead of addresses
        bob = users[1];
        vm.label(bob, "Bob");
        mallory = users[2];
        vm.label(mallory, "Mallory");
    }
}
