// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Airdrop, IERC20} from "./airdrop.sol";
import {Database} from "./database.sol";

// Event emitted when a new contract is deployed
event ContractDeployed(address indexed newContractAddress);

contract Factory is Database {
    IERC20 private immutable i_token;
    address private immutable i_treasury;
    uint256 private s_factoryFee;

    constructor(address _feeTokenAddress, uint256 _fee, address _treasury) Database() {
        i_token = IERC20(_feeTokenAddress);
        s_factoryFee = _fee;
        i_treasury = _treasury;
    }

    // Function to deploy a new contract
    function createNewAirdrop(
        address _tokenContract,
        uint128 _airdropTime,
        uint256 _registrationFee,
        string memory _logoUrl
    ) external {
        require(s_fromOwner[msg.sender] == 0, "Only one airdrop at a time");
        require(i_token.transferFrom(msg.sender, i_treasury, s_factoryFee), "Transfer failed");
        // Deploying a new instance of MyContract
        Airdrop newContract = new Airdrop(msg.sender, _tokenContract, _airdropTime, _registrationFee);

        // Emit an event with the address of the newly deployed contract
        emit ContractDeployed(address(newContract));

        // Write relevant data in the database
        addAirdrop(msg.sender, address(newContract), _tokenContract, _airdropTime, _registrationFee, _logoUrl);
    }

    function updateFee(uint256 _fee) external onlyOwner {
        s_factoryFee = _fee;
    }

    function getTeasury() external view onlyOwner returns (address) {
        return i_treasury;
    }

    function getFee() external view returns (uint256) {
        return s_factoryFee;
    }

    function getFeeToken() external view returns (address) {
        return address(i_token);
    }
}