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

    function test_sliding_window_same_price() public {
        uint256 periodSize = oracle.periodSize();
        uint256 granularity = oracle.granularity();

        for (uint256 i = 0; i < granularity; i++) {
            oracle.update(DAI, WETH);
            skip(periodSize + 1);
        }
        uint256 amount1 = oracle.consult(WETH, 1e18, DAI);

        oracle.update(DAI, WETH);
        skip(periodSize + 1);

        uint256 amount2 = oracle.consult(WETH, 1e18, DAI);
        assertApproxEqAbs(amount1, amount2, 1, "ETH TWAP");
    }
}
