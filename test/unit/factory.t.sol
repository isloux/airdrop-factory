// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Vm} from "forge-std/Test.sol";
import {BaseSetup, console} from "./baseSetup.t.sol";
import {Factory, IERC20} from "../../src/factory.sol";
import {DeployFactory} from "../../script/deployFactory.s.sol";
import {HelperConfig} from "../../script/helperConfig.s.sol";

interface IAirdrop {
    function owner() external view returns (address);
    function sendAirdrop() external;
    function withdrawPaidFees() external;
    function register() external payable;
    function getToken() external view returns (IERC20);
}

contract FactoryTest is BaseSetup {
    Factory factory;
    address private s_token;
    address private s_droppedToken;
    uint256 public constant REGISTRATION_FEE = 0.1 ether;
    uint128 public AIRDROP_TIME = uint128(block.timestamp) + 14 days;
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

    modifier fromAliceAndBob() {
        deal(s_token, alice, 2 ether);
        deal(s_droppedToken, alice, 2 ether);
        deal(alice, 1 ether);
        deal(s_token, bob, 2 ether);
        deal(bob, 1 ether);
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
        assertEq(factory.getNumberOfAirdrops(), 1);
    }

    function testCannotCreateTwoAirdrops() public fromAliceAndBob {
        IERC20 factoryFeeToken = IERC20(s_token);
        vm.startPrank(alice);
        factoryFeeToken.approve(address(factory), factory.getFee());
        factory.createNewAirdrop(s_droppedToken, AIRDROP_TIME, REGISTRATION_FEE, LOGO_URL);
        vm.stopPrank();
        vm.startPrank(bob);
        factoryFeeToken.approve(address(factory), factory.getFee() * 2);
        factory.createNewAirdrop(s_droppedToken, AIRDROP_TIME, REGISTRATION_FEE, LOGO_URL);
        vm.expectRevert();
        factory.createNewAirdrop(s_droppedToken, AIRDROP_TIME, REGISTRATION_FEE, LOGO_URL);
        vm.stopPrank();
    }

    function testRemoveAirdrop() public fromAliceAndBob {
        IERC20 factoryFeeToken = IERC20(s_token);
        vm.startPrank(alice);
        factoryFeeToken.approve(address(factory), factory.getFee());
        factory.createNewAirdrop(s_droppedToken, AIRDROP_TIME, REGISTRATION_FEE, LOGO_URL);
        vm.stopPrank();
        IAirdrop airdrop = IAirdrop(factory.getContract(0));
        IERC20 dropped = IERC20(s_droppedToken);
        vm.startPrank(alice);
        dropped.transfer(address(airdrop), 1 ether); // Here this is the airdropped token
        airdrop.register{value: 0.1 ether}();
        vm.stopPrank();
        assertEq(dropped.balanceOf(address(airdrop)), 1 ether);
        vm.warp(block.timestamp + 18 days);
        vm.prank(alice);
        airdrop.withdrawPaidFees();
        assertEq(dropped.balanceOf(address(airdrop)), 1 ether);
        assertEq(address(airdrop).balance, 0);
        assertEq(address(airdrop.getToken()), s_droppedToken);
        vm.prank(bob);
        airdrop.sendAirdrop();
        assertEq(dropped.balanceOf(alice), 2 ether);
        assertEq(factory.getNumberOfAirdrops(), 1); // Il faut vérifier pourquoi c'est 1 ici
    }

    function testFactoryOwner() public {
        assertEq(factory.owner(), msg.sender);
    }
}