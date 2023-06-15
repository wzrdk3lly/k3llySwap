// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress;

    error InvalidTokenAddress(address _invalidAddres);

    constructor(address _tokenAddress) {
        // 0 address checks to ensure we don't deploy a pool with a token address as the 0 address
        if (_tokenAddress == address(0))
            revert InvalidTokenAddress(_tokenAddress);

        tokenAddress = _tokenAddress;
    }

    function addLiquditity(uint _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount); // msg.sender needs to approve address(this) allowance first
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
