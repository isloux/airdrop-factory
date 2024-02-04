// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Airdrop} from "./airdrop.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// Event emitted when a new contract is deployed
event ContractDeployed(address indexed newContractAddress);

contract Factory {
    IERC20 private immutable i_token;
    address private immutable i_treasury;
    uint256 private s_fee;

    constructor(address _feeTokenAddress, uint256 _fee, address _treasury) {
        i_token = IERC20(_feeTokenAddress);
        s_fee = _fee;
        i_treasury = _treasury;
    }

    // Function to deploy a new contract
    function createNewAirdrop(
        address _tokenContract,
        uint128 _airdropTime,
        uint256 _registrationFee
    ) external {
        // Ajouter cela pour le paiement
        // require(i_token.transfer(i_treasury, s_fee), "Transfer failed");
        // Deploying a new instance of MyContract
        Airdrop newContract = new Airdrop(_tokenContract, _airdropTime, _registrationFee);

        // Emit an event with the address of the newly deployed contract
        emit ContractDeployed(address(newContract));

        // Appeler une fonction ici pour écrire dans la base
    }

    function updateFee(uint256 _fee) external {
        s_fee = _fee;
    }

    function getTeasury() external view returns (address) {
        return i_treasury;
    }
}