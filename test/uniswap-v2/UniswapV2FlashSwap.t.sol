// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DAI, UNISWAP_V2_PAIR_DAI_WETH} from "../../src/Constants.sol";
import {IERC20} from "../../lib/v2-core/contracts/interfaces/IERC20.sol";
import {UniswapV2FlashSwap} from "../../src/uniswap-v2/UniswapV2FlashSwap.sol";

contract UniswapV2FlashSwapTest is Test {
    IERC20 private constant dai = IERC20(DAI);
    UniswapV2FlashSwap private flashSwap;
    address private user = address(0);

    function setUp() public {
        flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);
        deal(DAI, user, 10000 ether);
        vm.prank(user);
        dai.approve(address(flashSwap), type(uint256).max);
    }

    function test_flashSwap() public {
        uint256 dai0 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        vm.prank(user);
        flashSwap.flashSwap(DAI, 1e6 ether);
        uint256 dai1 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        console.log("DAI fee", dai1 - dai0);
        assertGe(dai1, dai0, "Dai balance if pair");
    }
}
