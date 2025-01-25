// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(uint256 _totalSupply) ERC20("SimpleToken", "SIM") {
        _mint(msg.sender, _totalSupply);
    }
}
