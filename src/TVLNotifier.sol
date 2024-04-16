// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract TokenDeposit {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    ERC20 public tokenABC;
    address public owner;
    address public EPNS_COMM_ADDRESS = 0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7; // Example address, replace with actual
    uint256 public totalTokenDeposited;
    uint256 public notificationTriggerThreshold;

    constructor(address _tokenABC) {
        tokenABC = ERC20(_tokenABC);
        owner = msg.sender;
        notificationTriggerThreshold = 20 * 10**tokenABC.decimals(); // Example threshold
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function deposit(uint256 amount) public {
        require(tokenABC.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        totalTokenDeposited += amount;
        //sendNotification(msg.sender, amount, "Deposit");

        // Example Notification
    }

    function withdraw(uint256 amount) public {
        require(totalTokenDeposited >= amount, "Insufficient balance");
        tokenABC.transfer(msg.sender, amount);
        totalTokenDeposited -= amount;
       // sendNotification(msg.sender, amount, "Withdrawal");
    }

    function drain(uint256 amount) public onlyOwner {
        require(totalTokenDeposited >= amount, "Insufficient balance");
        tokenABC.transfer(owner, amount);
        totalTokenDeposited -= amount;
        
        if (amount > notificationTriggerThreshold) {
            uint256 percentageDrop = (amount * 100) / totalTokenDeposited;
            sendOwnerNotification(amount, percentageDrop);
        }
    }

    function sendOwnerNotification(uint256 amount, uint256 percentageDrop) internal {
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            0x554d29160f779Adf0a4328597cD33Ea1Df4D9Ee9, // from channel
            0x8c426a6385c28163E7ddd16aF05475A9d3a09B95,
            bytes(
                string(
                    abi.encodePacked(
                        "0+3+", // Minimal identity and notification type
                        "Critical Withdrawal+", 
                        "Significant withdrawal: ", 
                        amount.toString(), " TOKEN ABC which is ",
                        percentageDrop.toString(), "% of the TVL"
                    )
                )
            )
        );
    }

    // Setters for configurable values
    function setNotificationTriggerThreshold(uint256 _newThreshold) public onlyOwner {
        notificationTriggerThreshold = _newThreshold;
    }

}
