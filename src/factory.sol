// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Airdrop} from "./airdrop.sol";

// Event emitted when a new contract is deployed
event ContractDeployed(address indexed newContractAddress);

contract Factory {

    // Function to deploy a new contract
    function createNewAirdrop(address _tokenContract, uint128 _airdropTime, uint256 _registrationFee) public payable {
        // Deploying a new instance of MyContract
        Airdrop newContract = new Airdrop(_tokenContract, _airdropTime, _registrationFee);

        // Emit an event with the address of the newly deployed contract
        emit ContractDeployed(address(newContract));
    }
}