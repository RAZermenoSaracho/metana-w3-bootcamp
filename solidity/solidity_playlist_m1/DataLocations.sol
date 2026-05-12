// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Data location can be either:
// - storage: Lice state variables, defined at contract level. 
// - memory: the data is loaded on to memory.
// - calldata: call data is like memory escept it can only be used for function imputs
// But our couach told us that there are also these tipes of data locations: stack and transient
// - stack is where the actual logic of our code is executed, so we wont have access to this kind of memory.
// - transient, is a kind of memory that persissts only during a transaction is being executed.

contract DataLocations {
    uint256[] public arr;
    mapping(uint256 => address) map;

    struct MyStruct {
        uint256 foo;
    }

    mapping(uint256 => MyStruct) myStructs;

    function f() public {
        // call _f with state variables
        _f(arr, map, myStructs[1]);

        // get a struct from a mapping
        MyStruct storage myStruct = myStructs[1];
        // create a struct in memory
        MyStruct memory myMemStruct = MyStruct(0);
    }

    function _f(
        uint256[] storage _arr,
        mapping(uint256 => address) storage _map,
        MyStruct storage _myStruct
    ) internal {
        // do something with storage variables
    }

    // You can return memory variables
    function g(uint256[] memory _arr) public returns (uint256[] memory) {
        // do something with memory array
    }

    function h(uint256[] calldata _arr) external {
        // do something with calldata array
    }
}

// ChatGPT's explanation:
// Data locations in Solidity (EVM)
// They define where data lives and how long it persists.

contract StorageExample {
    // --------------------------------------------------
    // STORAGE
    // --------------------------------------------------
    // - Permanent storage of the contract (on blockchain)
    // - Persists between transactions
    // - Most expensive in gas
    // - Used by state variables
    uint public number; // stored in storage

    function setNumber(uint _n) public {
        number = _n; // writes to storage
    }

    // --------------------------------------------------
    // MEMORY
    // --------------------------------------------------
    // - Temporary memory during function execution
    // - Cleared after the function call ends
    // - Used for local variables and temporary data structures

    function exampleMemory() public pure returns (uint[] memory) {
        uint[] memory arr = new uint[](3); // stored in memory
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        return arr;
    }

    // --------------------------------------------------
    // CALLDATA
    // --------------------------------------------------
    // - Similar to memory, but read-only
    // - Used for external function parameters
    // - More efficient (no data copying)

    function exampleCalldata(uint[] calldata data) external pure returns (uint) {
        return data[0]; // cannot modify calldata
    }

    // --------------------------------------------------
    // STACK (EVM internal)
    // --------------------------------------------------
    // - Where operations are executed (add, compare, etc.)
    // - Not directly accessible from Solidity
    // - Limited size (~1024 values)
    // - Conceptual example:

    function exampleStack(uint a, uint b) public pure returns (uint) {
        return a + b; // a and b are handled in the stack internally
    }

    // --------------------------------------------------
    // TRANSIENT (EIP-1153, advanced)
    // --------------------------------------------------
    // - Temporary storage per transaction
    // - Persists across internal calls within the same tx
    // - Not stored on blockchain
    // - Cheaper than storage
    // - Still not widely used in high-level Solidity

    // Note: Mostly used at lower EVM level for optimizations.

    // --------------------------------------------------
    // SUMMARY
    // --------------------------------------------------
    // storage   = persistent (blockchain)
    // memory    = temporary per function
    // calldata  = external inputs (read-only)
    // stack     = EVM execution layer
    // transient = temporary per transaction
}