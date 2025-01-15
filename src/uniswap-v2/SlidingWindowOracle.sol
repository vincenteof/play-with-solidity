// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../src/libraries/UQ112x112.sol";

contract SlidingWindowOracle {
    using UQ112x112 for uint224;

    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    address public immutable factory;

    uint256 public immutable windowSize;

    uint8 public immutable granularity;

    uint256 public immutable periodSize;

    mapping(address => Observation[]) public pairObservations;

    constructor(address factory_, uint256 windowSize_, uint8 granularity_) {
        require(granularity_ > 1, "SlidingWindowOracle: GRANULARITY");
        require(
            (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
            "SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE"
        );
        factory = factory_;
        windowSize = windowSize_;
        granularity = granularity_;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SlidingWindowOracle: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SlidingWindowOracle: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(address factory_, address tokenA, address tokenB) internal pure returns (address) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory_,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    function observationIndexOf(uint256 timestamp) public view returns (uint8 index) {
        uint256 epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    function _getFirstObservationInWindow(address pair) internal view returns (Observation storage firstObservation) {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = pairObservations[pair][firstObservationIndex];
    }

    function _currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function _currentCumulativePrices(address pairAddress)
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative)
    {
        uint32 blockTimestamp = _currentBlockTimestamp();
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        if (blockTimestamp != blockTimestampLast) {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            unchecked {
                price0Cumulative = price0Cumulative + uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
                price1Cumulative = price1Cumulative + uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
            }
        }
    }

    function _computeAmountOut(
        uint256 priceCumulativeStart,
        uint256 priceCumulativeEnd,
        uint256 timeElapsed,
        uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        amountOut = (priceCumulativeEnd - priceCumulativeStart) * amountIn / timeElapsed / UQ112x112.Q112;
    }

    function update(address tokenA, address tokenB) external {
        address pair = _pairFor(factory, tokenA, tokenB);

        for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
            pairObservations[pair].push();
        }

        uint8 observationIndex = observationIndexOf(block.timestamp);
        // console.log("observationIndex: ", observationIndex);

        Observation storage observation = pairObservations[pair][observationIndex];

        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            // console.log("timeElapsed: ", timeElapsed);
            (uint256 price0Cumulative, uint256 price1Cumulative) = _currentCumulativePrices(pair);
            // console.log("price0Cumulative: ", price0Cumulative);
            // console.log("price1Cumulative: ", price1Cumulative);
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }
    }

    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns (uint256 amountOut) {
        address pair = _pairFor(factory, tokenIn, tokenOut);
        Observation storage firstObservation = _getFirstObservationInWindow(pair);

        uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, "SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION");
        require(timeElapsed >= windowSize - periodSize * 2, "SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED");
        (uint256 price0Cumulative, uint256 price1Cumulative) = _currentCumulativePrices(pair);
        (address token0,) = _sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            amountOut = _computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            amountOut = _computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}
