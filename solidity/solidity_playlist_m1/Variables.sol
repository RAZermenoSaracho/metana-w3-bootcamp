// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Variables {
    // State variables are stored on the blockchain.
    string public text = "Hello";
    uint256 public num = 123;

    function doSomething() public view returns (uint256, uint256, address, uint256) {
        // Local variables are not saved to the blockchain.
        uint256 i = 456;

        // Here are some global variables (provides information about the blockchain)
        uint256 timestamp = block.timestamp; // Current block timestamp
        address sender = msg.sender; // address of the caller
        uint blockNum = block.number; // current block number

        return (i, timestamp, sender, blockNum);
    }
}
