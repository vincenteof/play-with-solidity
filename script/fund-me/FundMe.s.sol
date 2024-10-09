// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../../src/fund-me/FundMe.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe fundMe) {
        HelperConfig helperConfig = new HelperConfig();
        (address priceFeed) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        // for Sepolia
        fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
    }
}
