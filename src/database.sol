// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Ownable} from "./airdrop.sol";

interface IAirdrop {
    function airdropSent() external view returns (bool);
}

struct AirdropData {
    uint256 fee;
    address contractAddress;
    address token;
    uint128 airdropTime;
    string logoUrl;
}

contract Database is Ownable {
    AirdropData[] internal s_airdrops;
    mapping (address=>uint64) internal s_fromOwner;

    constructor() Ownable(msg.sender) {}

    function addAirdrop(
        address _creator,
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
        s_fromOwner[_creator] = uint64(s_airdrops.length);
        s_airdrops.push(data);
    }

    function getContract(uint64 _index) public view returns (address) {
        return s_airdrops[_index].contractAddress;
    }

    function getNumberOfAirdrops() external view returns (uint256) {
        return s_airdrops.length;
    }

    function removeAirdrop() external {
        require(address(this).balance == 0, "Paid fees must be withdrawn first");
        uint64 contractIndex = s_fromOwner[msg.sender];
        require(contractIndex != 0, "No airdrop contract found");
        uint64 nAirdrops = uint64(s_airdrops.length);
        require(nAirdrops > contractIndex, "Wrong index");
        IAirdrop airdrop = IAirdrop(getContract(contractIndex));
        require(airdrop.airdropSent(), "Airdrop must be sent");
        // Clear user entry
        s_fromOwner[msg.sender] = 0;
        // Remove data from database
        for (uint64 i = contractIndex; i < nAirdrops - 1; ++i)
            s_airdrops[i] = s_airdrops[i + 1];
        s_airdrops.pop();   
    }
}