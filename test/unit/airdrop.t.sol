// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {BaseSetup, console} from "./baseSetup.t.sol";
import {Airdrop, IERC20} from "../../src/airdrop.sol";
import {DeployAirdrop} from "../../script/deployAirdrop.s.sol";

contract AirdropTest is BaseSetup {
    Airdrop airdrop;
    uint256 public constant TOKEN_AMOUNT = 12 ether;
    uint256 public constant STARTING_BALANCE = 3 ether;    
    uint256 public constant MINIMUM_FEE = 1 ether;

    function setUp() external {
        DeployAirdrop deployAirdrop = new DeployAirdrop();
        airdrop = deployAirdrop.run();
        vm.deal(alice, STARTING_BALANCE);
        vm.deal(bob, STARTING_BALANCE);
        vm.deal(mallory, STARTING_BALANCE);        
    }

    function testAirdropTime() public {
        assertEq(airdrop.getAirdropTime(), block.timestamp + 14 days);
    }

    function testFundAirdrop() public {
        IERC20 token = airdrop.getToken();
        vm.startBroadcast();
        token.transfer(alice, TOKEN_AMOUNT);
        vm.stopBroadcast();
        vm.prank(alice);
        token.transfer(address(airdrop), TOKEN_AMOUNT);
        assertEq(airdrop.getBalance(), TOKEN_AMOUNT);
    }

    modifier funded() {
        IERC20 token = airdrop.getToken();
        vm.startBroadcast();
        token.transfer(address(airdrop), TOKEN_AMOUNT);
        vm.stopBroadcast();
        _;
    }

    modifier registered() {
        vm.prank(alice);
        airdrop.register{value: MINIMUM_FEE}();
        vm.prank(bob);
        airdrop.register{value: MINIMUM_FEE}();
        vm.prank(mallory);
        airdrop.register{value: MINIMUM_FEE}();
        _;
    }

    function testOwner() public funded {
        assertEq(airdrop.owner(), address(this));
    }

    function testRegister() public registered {
        assertEq(airdrop.count(), 3);
    }

    function testNotEnoughPaid() public {
        vm.expectRevert();
        vm.prank(alice);
        airdrop.register{value: 0.01 ether}();
    }

    function testNoOneRegistered() public funded {
        assertEq(airdrop.count(), 0);
    }

    function testRecoverFees() public registered {
        uint256 ownerInitialBalance = address(this).balance;
        vm.prank(address(this));
        airdrop.withdrawPaidFees();
        assertEq(address(this).balance - ownerInitialBalance, STARTING_BALANCE);        
    }

    // Have these functions to receive ether when withdrawing
    fallback() external payable {}
    receive() external payable {}

    function testTooEarlyAirdrop() public funded {
        vm.warp(block.timestamp + 3600);
        vm.expectRevert();
        vm.prank(alice);
        airdrop.sendAirdrop();
    }

    function testAirdrop() public funded registered {
        IERC20 token = airdrop.getToken();
        vm.warp(block.timestamp + 18 days);
        vm.startBroadcast();
        token.transfer(alice, 1 ether);
        token.transfer(bob, 2 ether);
        token.transfer(mallory, 3 ether);
        vm.stopBroadcast();
        vm.prank(bob);
        airdrop.sendAirdrop();
        assertEq(token.balanceOf(alice), 3 ether);     
        assertEq(token.balanceOf(bob), 6 ether);     
        assertEq(token.balanceOf(mallory), 9 ether);     
    }

    function testWithdrawBeforeAirdropSent() public funded {
        vm.warp(block.timestamp + 18 days);
        vm.startBroadcast();
        vm.expectRevert();
        airdrop.withdrawTokens();
        vm.stopBroadcast();
    }

    function testLeftOverTokens() public funded registered {
        IERC20 token = airdrop.getToken();
        vm.warp(block.timestamp + 18 days);
        vm.startBroadcast();
        token.transfer(alice, 2.109 ether);
        token.transfer(bob, 0.342 ether);
        vm.stopBroadcast();
        vm.prank(bob);
        airdrop.sendAirdrop();
        assertEq(token.balanceOf(address(airdrop)), 0.1 ether); 
        uint256 initialTokenBalance = token.balanceOf(address(this));
        vm.prank(address(this));
        airdrop.withdrawTokens();
        assertEq(token.balanceOf(address(this)) - initialTokenBalance, 0.1 ether);
    }

    function testRegistrationFee() public {
        assertEq(airdrop.getRegistrationFee(), MINIMUM_FEE);
    }
}