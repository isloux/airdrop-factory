// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Airdrop, Ownable} from "./airdrop.sol";

struct AirdropData {
    uint256 fee;
    address contractAddress;
    address token;
    uint128 airdropTime;
    string logoUrl;
}

contract Database is Ownable {
    AirdropData[] internal s_airdrops;

    constructor() Ownable(msg.sender) {}

    function addAirdrop(
        address _contract,
        address _token,
        uint128 _airdropTime,
        uint256 _registrationFee,
        string memory _logoUrl
    ) internal {
        AirdropData memory data;
        data.contractAddress = _contract;
        data.token = _token;
        data.airdropTime = _airdropTime;
        data.fee = _registrationFee;
        data.logoUrl = _logoUrl;
        s_airdrops.push(data);
    }

    function getContract(uint256 _index) external view returns(address) {
        return s_airdrops[_index].contractAddress;
    }
}