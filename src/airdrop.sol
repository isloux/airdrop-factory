pragma solidity 0.8.23;
// SPDX-License-Identifier: MIT

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Airdrop is Ownable {
    IERC20 private immutable i_token;
    uint128 private immutable i_airdropTime;
    uint256 private immutable i_scale;
    uint256 private immutable i_registrationFee;
    address[] private s_recipients;
    bool private s_airdropSent;

    modifier onlyOnce() {
        require(!s_airdropSent, "No");
        s_airdropSent = true;
        _;
    }

    constructor(
        address _owner,
        address _tokenContract,
        uint128 _airdropTime,
        uint256 _registrationFee
    ) Ownable(msg.sender) {
        transferOwnership(_owner);
        require(_airdropTime > block.timestamp);
        i_token = IERC20(_tokenContract);
        i_airdropTime = _airdropTime;
        i_registrationFee = _registrationFee;
        s_airdropSent = false;
        uint8 decimals = i_token.decimals();
        i_scale = 10 ** (decimals - 1);
    }

    function receiveTokens(uint256 amount) external {
        require(
            i_token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed. Make sure the expense is approved."
        );
    }

    function sendAirdrop() external onlyOnce {
        require(
            block.timestamp > i_airdropTime,
            "It is too early to send airdrop out."
        );
        require(getBalance() > 0, "The contract balance must be non zero.");
        uint256 supply = getBalance() / i_scale;
        uint256 totalSubscription = 0;
        uint64 nRecipients = uint64(s_recipients.length);
        for (uint64 i = 0; i < nRecipients; ++i)
            totalSubscription += i_token.balanceOf(s_recipients[i]);
        require(
            totalSubscription > 0,
            "No airdrop recipient address holds the token"
        );
        for (uint64 i = 0; i < nRecipients; ++i) {
            uint256 amountToSend = (i_token.balanceOf(s_recipients[i]) *
                supply) / totalSubscription;
            i_token.transfer(s_recipients[i], amountToSend * i_scale);
        }
    }

    function register() external payable {
        require(msg.value >= i_registrationFee, "Insufficient payment");
        s_recipients.push(msg.sender);
    }

    function register(address[] calldata _addresses) external onlyOwner {
        uint64 nAddresses = uint64(_addresses.length);
        for (uint64 i = 0; i < nAddresses; i++)
            s_recipients.push(_addresses[i]);
    }

    function count() external view returns (uint256) {
        return s_recipients.length;
    }

    function getToken() external view returns (IERC20) {
        return i_token;
    }

    function getBalance() public view returns (uint256) {
        return i_token.balanceOf(address(this));
    }

    function withdrawTokens() external onlyOwner {
        require(s_airdropSent, "Airdrop must be sent out first.");
        i_token.transfer(msg.sender, i_token.balanceOf(address(this)));
    }

    function withdrawPaidFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function getAirdropTime() external view returns (uint128) {
        return i_airdropTime;
    }

    function getRegistrationFee() external view returns (uint256) {
        return i_registrationFee;
    }

    function airdropSent() external view returns (bool) {
        return s_airdropSent;
    }
}
