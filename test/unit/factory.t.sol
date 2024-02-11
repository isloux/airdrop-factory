// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Vm} from "forge-std/Test.sol";
import {BaseSetup, console} from "./baseSetup.t.sol";
import {Factory, IERC20} from "../../src/factory.sol";
import {DeployFactory} from "../../script/deployFactory.s.sol";
import {HelperConfig} from "../../script/helperConfig.s.sol";

interface IAirdrop {
    function owner() external view returns (address);
}

contract FactoryTest is BaseSetup {
    Factory factory;
    address private s_token;
    address private s_droppedToken;
    uint256 public constant REGISTRATION_FEE = 0.1 ether;
    uint128 public constant AIRDROP_TIME = 1707752147;
    string public constant LOGO_URL = "https://www.pinkswap.finance/pinkswap.png";
    address private s_treasury;

    function setUp() external {
        DeployFactory deployFactory = new DeployFactory();
        HelperConfig helperConfig = new HelperConfig();
        (s_droppedToken,,,s_treasury) = helperConfig.activeNetworkConfig();
        factory = deployFactory.run();
        s_token = factory.getFeeToken();
    }

    function testGetTreasury() public {
        address owner = factory.owner();
        vm.prank(owner);
        address treasury = factory.getTeasury();
        assertEq(treasury, s_treasury);
    }

    // How to check logs: https://book.getfoundry.sh/cheatcodes/get-recorded-logs?highlight=Vm.Log#examples

    modifier fromAlice() {
        deal(s_token, alice, 2 ether);
        deal(alice, 1 ether);
        _;
    }

    function testBalance() public fromAlice {
        IERC20 token = IERC20(s_token);
        uint256 balance = token.balanceOf(alice);
        assertEq(balance, 2 ether);
        assertEq(alice.balance, 1 ether);
    }

    function testRegistrationFee() public {
        assertEq(factory.getFee(), 1 ether);
    }

    function testFeeToken() public {
        assertEq(factory.getFeeToken(), s_token);
    }

    function testAirdropTime() public {
    }

    function testCreateNewAirdrop() public fromAlice {
        IERC20 factoryFeeToken = IERC20(s_token);
        vm.recordLogs();
        vm.startPrank(alice);
        factoryFeeToken.approve(address(factory), factory.getFee());
        factory.createNewAirdrop(s_droppedToken, AIRDROP_TIME, REGISTRATION_FEE, LOGO_URL);
        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 5);
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[1].topics.length, 3);
        assertEq(entries[4].topics[0], keccak256("ContractDeployed(address)"));
        IAirdrop airdrop = IAirdrop(factory.getContract(0));
        assertEq(airdrop.owner(), alice);
    }

    function testFactoryOwner() public {
        assertEq(factory.owner(), msg.sender);
    }
}