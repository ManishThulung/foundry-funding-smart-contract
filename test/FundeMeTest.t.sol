// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant ETH_VALUE = 0.1 ether; // 1e17
    uint256 constant STARTING_VALUE = 100 ether; // 1e17

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, ) = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE); // initialize the 100 ETH as a balance to this USER
    }

    function testMinimumDollorIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testGetVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // the following statement should revert if it doesnt it will fail
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        // the next address is gonna be this
        vm.prank(USER);
        fundMe.fund{value: ETH_VALUE}();
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedAmount, ETH_VALUE);
    }

    function testAddsFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: ETH_VALUE}();
        assertEq(fundMe.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: ETH_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdraWithSingleFunder() public funded {
        address ownerAddress = fundMe.getOwner();
        uint256 startingOwnerBalance = ownerAddress.balance;
        uint256 startingFundeMeBalance = address(fundMe).balance;

        vm.prank(ownerAddress);
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundeMeBalance = address(fundMe).balance;

        assertEq(endingFundeMeBalance, 0);
        assertEq(
            startingFundeMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
