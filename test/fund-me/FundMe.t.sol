// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/fund-me/FundMe.sol";
import {DeployFundMe} from "../../script/fund-me/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address user = makeAddr("Alice");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, 10 ether);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        assertEq(fundMe.owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailedWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testFundUpdatesFunderDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq(amountFunded, 10e18);
    }

    function testAddFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, user);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(user);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingFundMeBalance = fundMe.getBalance();

        vm.prank(fundMe.owner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.owner().balance;
        uint256 endingFundMeBalance = fundMe.getBalance();

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), 10 ether);
            fundMe.fund{value: 10 ether}();
        }
        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingFundMeBalance = fundMe.getBalance();

        vm.txGasPrice(1);
        vm.startPrank(fundMe.owner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.owner().balance;
        uint256 endingFundMeBalance = fundMe.getBalance();
        assertEq(endingFundMeBalance, 0);
        assert(
            startingOwnerBalance + startingFundMeBalance == endingOwnerBalance
        );
    }
}
