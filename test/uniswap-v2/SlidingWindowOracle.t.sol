// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "../../lib/v2-core/contracts/interfaces/IERC20.sol";
import {DAI, WETH, UNISWAP_V2_PAIR_DAI_WETH, UNISWAP_V2_ROUTER_02, UNISWAP_V2_FACTORY} from "../../src/Constants.sol";
import {SlidingWindowOracle} from "../../src/uniswap-v2/SlidingWindowOracle.sol";

contract UniswapV2SlidingWindowOracleTest is Test {
    SlidingWindowOracle private oracle;
    IERC20 private constant weth = IERC20(WETH);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    uint256 private constant MIN_WAIT = 300;

    function setUp() public {
        oracle = new SlidingWindowOracle(address(UNISWAP_V2_FACTORY), 24 * 60 * 60, 12);
    }

    function getSpot(address pairAddress) internal view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        // DAI / WETH
        return uint256(reserve0) * 1e18 / uint256(reserve1);
    }

    function swap() internal {
        deal(WETH, address(this), 100 * 1e18);
        weth.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        // Input token amount and all subsequent output token amounts
        router.swapExactTokensForTokens({
            amountIn: 100 * 1e18,
            amountOutMin: 1,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });
    }

    function test_sliding_same_price_as_spot() public {
        uint256 periodSize = oracle.periodSize();
        uint256 granularity = oracle.granularity();

        for (uint256 i = 0; i < granularity; i++) {
            oracle.update(DAI, WETH);
            skip(periodSize + 1);
        }
        uint256 amount = oracle.consult(WETH, 1e18, DAI);
        uint256 spot = getSpot(UNISWAP_V2_PAIR_DAI_WETH);
        assertEq(amount, spot, "TWAP == spot");
    }

    function test_sliding_window_same_price() public {
        uint256 periodSize = oracle.periodSize();
        uint256 granularity = oracle.granularity();

        for (uint256 i = 0; i < granularity; i++) {
            oracle.update(DAI, WETH);
            skip(periodSize + 1);
        }
        uint256 amount0 = oracle.consult(WETH, 1e18, DAI);

        oracle.update(DAI, WETH);
        skip(periodSize + 1);

        uint256 amount1 = oracle.consult(WETH, 1e18, DAI);

        console.log("amount0: ", amount0);
        console.log("amount1: ", amount1);
        assertApproxEqAbs(amount0, amount1, 1, "ETH TWAP");
    }

    function test_sliding_window_close_to_last_spot() public {
        uint256 periodSize = oracle.periodSize();
        uint256 granularity = oracle.granularity();

        for (uint256 i = 0; i < granularity; i++) {
            oracle.update(DAI, WETH);
            skip(periodSize + 1);
        }
        uint256 amount0 = oracle.consult(WETH, 1e18, DAI);

        swap();
        uint256 spot = getSpot(UNISWAP_V2_PAIR_DAI_WETH);

        oracle.update(DAI, WETH);
        skip(periodSize + 1);
        uint256 amount1 = oracle.consult(WETH, 1e18, DAI);

        console.log("amount0: ", amount0);
        console.log("spot: ", spot);
        console.log("amount1: ", amount1);

        // Check TWAP is close to last spot
        assertLt(amount1, amount0, "twap1 >= twap0");
        assertGe(amount1, spot, "twap1 < spot");
    }
}
