// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import "../abstract/Ownable.sol";
contract FundMe is Ownable {
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address[] private funders;
    mapping(address => uint256) private addressToAmountFunded;
    AggregatorV3Interface private priceFeed;

    constructor(address _priceFeed) Ownable(msg.sender) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        // at least 5 USD
        require(
            PriceConverter.getConversionRate(msg.value, priceFeed) >=
                MINIMUM_USD,
            "You need spend more ETH!"
        );
        uint256 prevAmount = addressToAmountFunded[msg.sender];
        addressToAmountFunded[msg.sender] += msg.value;
        if (prevAmount == 0) {
            funders.push(msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        uint256 total;
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            total += addressToAmountFunded[funder];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = owner().call{value: total}("");
        require(success);
    }

    function getFunders() public view returns (address[] memory) {
        return funders;
    }

    function getAmountFunded(address _funder) public view returns (uint256) {
        return addressToAmountFunded[_funder];
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getAddressToAmountFunded(
        address funderAddress
    ) external view returns (uint256) {
        return addressToAmountFunded[funderAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getBalance() public view returns (uint256) {
        uint256 balance;
        for (uint256 i; i < funders.length; i++) {
            address funder = funders[i];
            balance += addressToAmountFunded[funder];
        }
        return balance;
    }
}
