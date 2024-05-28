// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DeadMansSwitch {
    // Event declarations
    event CheckIn(address indexed user, uint timestamp);
    event Deposit(address indexed depositor, uint amount);
    event Withdrawal(address indexed beneficiary, uint amount);
    event CheckInIntervalSet(address indexed user, uint interval);
    event BeneficiaryAdded(address indexed user, address indexed beneficiary);
    event BeneficiaryRemoved(address indexed user, address indexed beneficiary);

    // Struct to store user data
    struct User {
        uint balance;
        uint lastCheckIn;
        uint checkInInterval;
        mapping(address => bool) isBeneficiary;
    }

    // Mappings to store user data
    mapping(address => User) public users;

    /**
     * @dev Deposits Ether into the contract.
     * @notice This function allows users to deposit Ether into the contract.
     * Requirements:
     * - Adds the amount deposited to the balance of the sender.
     * - Updates the last check-in time to the current block timestamp.
     * - Emits a `Deposit` event with the caller's address and the amount of Ether deposited.
     */
    function deposit() public payable {
        User storage user = users[msg.sender];
        user.balance += msg.value;
        user.lastCheckIn = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Sets the check-in interval for the user.
     * @param interval The time interval (in seconds) for the user to check in.
     * Requirements:
     * - The interval must be greater than 0.
     * - Emits a `CheckInIntervalSet` event with the caller's address and the interval.
     */
    function setCheckInInterval(uint interval) public {
        require(interval > 0, "Interval must be greater than 0");
        User storage user = users[msg.sender];
        user.checkInInterval = interval;
        emit CheckInIntervalSet(msg.sender, interval);
    }

    /**
     * @dev Allows the user to check in and reset the timer.
     * Requirements:
     * - Updates the last check-in time to the current block timestamp.
     * - Emits a `CheckIn` event with the caller's address and the current timestamp.
     */
    function checkIn() public {
        User storage user = users[msg.sender];
        user.lastCheckIn = block.timestamp;
        emit CheckIn(msg.sender, block.timestamp);
    }

    /**
     * @dev Adds a beneficiary for the user's funds.
     * @param beneficiary The address of the beneficiary.
     * Requirements:
     * - The beneficiary address must not be the zero address.
     * - The beneficiary must not already be added.
     * - Emits a `BeneficiaryAdded` event with the caller's address and the beneficiary address.
     */
    function addBeneficiary(address beneficiary) public {
        require(beneficiary != address(0), "Invalid beneficiary address");
        User storage user = users[msg.sender];
        require(!user.isBeneficiary[beneficiary], "Beneficiary already added");
        user.isBeneficiary[beneficiary] = true;
        emit BeneficiaryAdded(msg.sender, beneficiary);
    }

    /**
     * @dev Removes a beneficiary for the user's funds.
     * @param beneficiary The address of the beneficiary to remove.
     * Requirements:
     * - The beneficiary must be already added.
     * - The beneficiary is removed
     * - Emits a `BeneficiaryRemoved` event with the caller's address and the beneficiary address.
     */
    function removeBeneficiary(address beneficiary) public {
        User storage user = users[msg.sender];
        require(user.isBeneficiary[beneficiary], "Beneficiary not found");
        delete user.isBeneficiary[beneficiary];
        emit BeneficiaryRemoved(msg.sender, beneficiary);
    }
    /**
     * @dev Allows the user to withdraw their funds at any time.
     * @param amount The amount of Ether to withdraw.
     * Requirements:
     * - The caller must have a balance of at least `amount`.
     * - The withdrawal must be successful and the Ether must be sent to the caller's address.
     * - Emits a `Withdrawal` event with the caller's address and the amount of Ether withdrawn.
     */
    function withdraw(uint amount) public {
        User storage user = users[msg.sender];
        require(user.balance >= amount, "Insufficient balance");
        user.balance -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Allows beneficiaries to withdraw the user's funds if the check-in interval has passed.
     * @param userAddress The address of the user.
     * Requirements:
     * - The caller must be one of the user's beneficiaries.
     * - The user's check-in interval must have passed without a check-in.
     * - The withdrawal must be successful and the Ether must be sent to the caller's address.
     * - Emits a `Withdrawal` event with the beneficiary's address and the amount of Ether withdrawn.
     */
    function withdrawAsBeneficiary(address userAddress) public {
        User storage user = users[userAddress];
        require(
            block.timestamp >= user.lastCheckIn + user.checkInInterval,
            "Check-in interval has not passed"
        );
        require(user.isBeneficiary[msg.sender], "Caller is not a beneficiary");
        uint amount = user.balance;
        user.balance = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Gets to check if there is a beneficiary.
     * @param userAddress The address of the user.
     * @param beneficiary The address of the beneficiary.
     * @return boolean representing whether the address is a beneficiary
     * Requirements:
     * - Returns true if the provided beneficiary is a given userAddresses beneficiary, otherwise false
     */
    function beneficiaryLookup(
        address userAddress,
        address beneficiary
    ) public view returns (bool) {
        return users[userAddress].isBeneficiary[beneficiary];
    }
}
