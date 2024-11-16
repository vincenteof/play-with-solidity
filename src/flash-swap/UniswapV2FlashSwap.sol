// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV2Callee} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Pair} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "../../lib/v2-core/contracts/interfaces/IERC20.sol";

contract UniswapV2FlashSwap is IUniswapV2Callee {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint256 amount) external {
        require(token == token0 || token == token1, "Invalid token");

        (uint256 amount0Out, uint256 amount1Out) = token == token0 ? (amount, uint256(0)) : (uint256(0), amount);
        bytes memory data = abi.encode(token, msg.sender);
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(msg.sender == address(pair), "Not pair");
        require(sender == address(this), "Not sender");
        (address token, address caller) = abi.decode(data, (address, address));
        uint256 amount = token == token0 ? amount0 : amount1;
        uint256 fee = amount * 3 / 997 + 1;
        uint256 amountToRepay = amount + fee;
        IERC20(token).transferFrom(caller, address(this), fee);
        IERC20(token).transfer(address(pair), amountToRepay);
    }
}
