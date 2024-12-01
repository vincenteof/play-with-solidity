// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../src/libraries/UQ112x112.sol";

contract UniswapV2OracleSimple {
    using UQ112x112 for uint224;

    uint256 private constant MIN_WAIT = 300;
    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public updatedAt;
    uint224 public price0Average;
    uint224 public price1Average;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();
        (,, updatedAt) = pair.getReserves();
    }

    function _currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function _getCurrentCumulativePrices() internal view returns (uint256 price0Cumulative, uint256 price1Cumulative) {
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();

        uint32 currentTimestamp = _currentBlockTimestamp();
        if (block.timestamp != blockTimestampLast) {
            // It means that Pair contract is not updated since blockTimestampLast
            // So we need to estimated the newest cumulative price
            uint32 dt = currentTimestamp - blockTimestampLast;
            unchecked {
                price0Cumulative = price0Cumulative + uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * dt;
                price1Cumulative = price1Cumulative + uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * dt;
            }
        }
    }

    function update() external {
        uint32 currentTimestamp = _currentBlockTimestamp();
        uint32 dt = currentTimestamp - updatedAt;

        require(dt >= MIN_WAIT, "UniswapV2OracleSimple: PERIOD_NOT_ELAPSED");

        (uint256 price0Cumulative, uint256 price1Cumulative) = _getCurrentCumulativePrices();

        unchecked {
            price0Average = uint224((price0Cumulative - price0CumulativeLast) / dt);
            price1Average = uint224((price1Cumulative - price1CumulativeLast) / dt);
        }
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        updatedAt = currentTimestamp;
    }

    function consult(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        require(tokenIn == token0 || tokenIn == token1, "UniswapV2OracleSimple: UNSUPPORTED_TOKEN");
        if (tokenIn == token0) {
            amountOut = uint256(price0Average) * amountIn / UQ112x112.Q112;
        } else {
            amountOut = uint256(price1Average) * amountIn / UQ112x112.Q112;
        }
    }
}
