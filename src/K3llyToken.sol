// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract K3llyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("K3llyToken", "WKT") {
        _mint(msg.sender, initialSupply);
    }
}
