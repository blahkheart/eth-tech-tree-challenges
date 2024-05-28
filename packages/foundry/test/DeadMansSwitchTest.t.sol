// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/DeadMansSwitch.sol";

contract DeadMansSwitchTest is Test {
    DeadMansSwitch public deadMansSwitch;
    address THIS_CONTRACT = address(this);
    address NON_CONTRACT_USER = vm.addr(1);
    address BENEFICIARY_1 = vm.addr(2);
    uint ONE_THOUSAND = 1000 wei;
    uint INTERVAL = 1 weeks;

    // Setup the contract before each test
    function setUp() public {
        deadMansSwitch = new DeadMansSwitch();
    }

    // Test deposit functionality
    function testDeposit() public {
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        (uint balance, , ) = deadMansSwitch.users(THIS_CONTRACT);
        assertEq(balance, ONE_THOUSAND);
    }

    // Test setting the check-in interval
    function testSetCheckInInterval() public {
        deadMansSwitch.setCheckInInterval(INTERVAL);
        (, , uint checkInterval) = deadMansSwitch.users(THIS_CONTRACT);
        assertEq(checkInterval, INTERVAL);
    }

    // Test the check-in functionality
    function testCheckIn() public {
        deadMansSwitch.setCheckInInterval(INTERVAL);
        deadMansSwitch.checkIn();
        (, uint lastCheckIn, ) = deadMansSwitch.users(THIS_CONTRACT);
        assertEq(lastCheckIn, block.timestamp);
    }

    // Test adding a beneficiary
    function testAddBeneficiary() public {
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        assertEq(
            deadMansSwitch.beneficiaryLookup(THIS_CONTRACT, BENEFICIARY_1),
            true
        );
    }

    // Test removing a beneficiary
    function testRemoveBeneficiary() public {
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        assertEq(
            deadMansSwitch.beneficiaryLookup(THIS_CONTRACT, BENEFICIARY_1),
            true
        );

        deadMansSwitch.removeBeneficiary(BENEFICIARY_1);
        assertEq(
            deadMansSwitch.beneficiaryLookup(THIS_CONTRACT, BENEFICIARY_1),
            false
        );
    }

    // Test withdrawing funds by the user
    function testWithdraw() public {
        vm.deal(NON_CONTRACT_USER, ONE_THOUSAND);
        vm.startPrank(NON_CONTRACT_USER);
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        deadMansSwitch.withdraw(ONE_THOUSAND);
        (uint balance, , ) = deadMansSwitch.users(THIS_CONTRACT);
        assertEq(balance, 0);
    }

    // Test withdrawing funds by a beneficiary after the interval has passed
    function testWithdrawAsBeneficiary() public {
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        deadMansSwitch.setCheckInInterval(INTERVAL);
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        assertEq(
            deadMansSwitch.beneficiaryLookup(THIS_CONTRACT, BENEFICIARY_1),
            true
        );
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.startPrank(BENEFICIARY_1);
        uint initialBalance = address(BENEFICIARY_1).balance;
        deadMansSwitch.withdrawAsBeneficiary(THIS_CONTRACT);
        uint finalBalance = address(BENEFICIARY_1).balance;
        assertEq(finalBalance, initialBalance + ONE_THOUSAND);
        (uint balance, , ) = deadMansSwitch.users(THIS_CONTRACT);
        assertEq(balance, 0);
    }

    // Test that non-beneficiaries cannot withdraw funds
    function testWithdrawAsNonBeneficiary() public {
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        deadMansSwitch.setCheckInInterval(INTERVAL);
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.startPrank(NON_CONTRACT_USER);
        vm.expectRevert();
        deadMansSwitch.withdrawAsBeneficiary(THIS_CONTRACT);
    }

    // Test that non-beneficiaries cannot withdraw funds before the interval has passed
    function testWithdrawAsNonBeneficiaryBeforeInterval() public {
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        deadMansSwitch.setCheckInInterval(INTERVAL);
        vm.warp(block.timestamp + INTERVAL - 1);
        vm.startPrank(NON_CONTRACT_USER);
        vm.expectRevert();
        deadMansSwitch.withdrawAsBeneficiary(THIS_CONTRACT);
    }

    // Test that beneficiaries cannot withdraw funds before the interval has passed
    function testWithdrawAsBeneficiaryBeforeInterval() public {
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        deadMansSwitch.setCheckInInterval(INTERVAL);
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        vm.warp(block.timestamp + INTERVAL - 1);
        vm.startPrank(BENEFICIARY_1);
        vm.expectRevert();
        deadMansSwitch.withdrawAsBeneficiary(THIS_CONTRACT);
    }

    //Test  if user is already a beneficiary
    function testAddBeneficiaryTwice() public {
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        vm.expectRevert();
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
    }

    //Test for zero address
    function testZeroAddress() public {
        vm.expectRevert();
        deadMansSwitch.addBeneficiary(address(0));
    }

    // Test that the Deposit event is emitted correctly
    function testEmitDepositEvent() public {
        vm.expectEmit(true, true, true, true);
        emit DeadMansSwitch.Deposit(THIS_CONTRACT, ONE_THOUSAND);
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
    }

    // Test that the Withdrawal event is emitted correctly
    function testEmitWithdrawalEvent() public {
        vm.deal(NON_CONTRACT_USER, ONE_THOUSAND);
        vm.startPrank(NON_CONTRACT_USER);
        deadMansSwitch.deposit{value: ONE_THOUSAND}();
        emit DeadMansSwitch.Withdrawal(THIS_CONTRACT, ONE_THOUSAND);
        deadMansSwitch.withdraw(ONE_THOUSAND);
    }

    // Test that the CheckIn event is emitted correctly
    function testEmitCheckInEvent() public {
        deadMansSwitch.setCheckInInterval(INTERVAL);
        vm.expectEmit(true, true, true, true);
        emit DeadMansSwitch.CheckIn(THIS_CONTRACT, block.timestamp);
        deadMansSwitch.checkIn();
    }

    // Test that the BeneficiaryAdded event is emitted correctly
    function testEmitBeneficiaryAddedEvent() public {
        vm.expectEmit(true, true, true, true);
        emit DeadMansSwitch.BeneficiaryAdded(THIS_CONTRACT, BENEFICIARY_1);
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
    }

    // Test removing a beneficiary
    function testEmitBeneficiaryRemovedEvent() public {
        deadMansSwitch.addBeneficiary(BENEFICIARY_1);
        vm.expectEmit(true, true, true, true);
        emit DeadMansSwitch.BeneficiaryRemoved(THIS_CONTRACT, BENEFICIARY_1);
        deadMansSwitch.removeBeneficiary(BENEFICIARY_1);
    }

    // Test that the CheckInIntervalSet event is emitted correctly
    function testEmitCheckInIntervalSetEvent() public {
        vm.expectEmit(true, true, true, true);
        emit DeadMansSwitch.CheckInIntervalSet(THIS_CONTRACT, INTERVAL);
        deadMansSwitch.setCheckInInterval(INTERVAL);
    }
}
