# Solidity + EVM + Web3 Developer Cheatsheet

> A practical long-term reference for learning Solidity, the EVM, smart contract security, and common Web3 development workflows.

---

## How to Use This Cheatsheet

- Use it as a quick reference while coding Solidity, reviewing contracts, or preparing for interviews.
- Use the links in the table of contents to jump directly to a topic.
- If you are newer to blockchain development, read the Foundations sections first.
- Review [Security Fundamentals](#20-security-fundamentals) before writing production contracts.
- Review [Testing and Debugging](#25-testing-and-debugging) and [Deployment Checklist](#26-deployment-checklist) before shipping.

---

## Table of Contents

### Foundations
- [1. Solidity Mental Model](#1-solidity-mental-model)

### Solidity Language Basics
- [2. Primitive & Value Types in Solidity](#2-primitive--value-types-in-solidity)
- [3. Data Locations: storage, memory, calldata, stack](#3-data-locations-storage-memory-calldata-stack)
- [4. Arrays, Mappings, Structs, Enums](#4-arrays-mappings-structs-enums)
- [5. Function Visibility](#5-function-visibility)
- [6. Function Mutability](#6-function-mutability)
- [7. Global Variables](#7-global-variables)
- [8. Errors and Validation](#8-errors-and-validation)
- [9. Modifiers](#9-modifiers)
- [10. Events and Logs](#10-events-and-logs)
- [16. Inheritance and Interfaces](#16-inheritance-and-interfaces)

### Contract Interaction
- [11. ETH Handling](#11-eth-handling)
- [12. ABI Encoding](#12-abi-encoding)
- [13. Low-Level Calls: call, delegatecall, staticcall](#13-low-level-calls-call-delegatecall-staticcall)
- [17. ERC Standards](#17-erc-standards)
- [23. Signatures and Hashing](#23-signatures-and-hashing)

### EVM Internals
- [14. Assembly & Yul](#14-assembly--yul)
- [15. Storage Layout](#15-storage-layout)

### Security
- [18. Access Control](#18-access-control)
- [19. Arithmetic Safety: Overflow & Underflow](#19-arithmetic-safety-overflow--underflow)
- [20. Security Fundamentals](#20-security-fundamentals)

### Gas Optimization
- [21. Gas Optimization](#21-gas-optimization)

### Upgradeability
- [22. Upgradeable Contracts](#22-upgradeable-contracts)

### Web3 Frontend
- [24. Common Web3 Frontend Interactions](#24-common-web3-frontend-interactions)

### Testing & Deployment
- [25. Testing and Debugging](#25-testing-and-debugging)
- [26. Deployment Checklist](#26-deployment-checklist)

### Interview Prep
- [27. Common Interview Questions](#27-common-interview-questions)

---

## 1. Solidity Mental Model

### What a Smart Contract Is

A smart contract is a program stored on a blockchain. It has:

- Code: the contract logic deployed to an address.
- State: persistent variables stored in the blockchain state.
- Balance: native ETH held by the contract address.
- Public interface: functions and events other users, contracts, and frontends interact with.

Think of a contract as a public backend service whose code and state live on-chain. Users do not "run" the contract locally in the usual backend sense. They submit transactions or calls to an Ethereum node, and the EVM executes the contract according to deterministic rules.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Counter {
    uint256 public count;

    function increment() external {
        count += 1;
    }
}
```

### EVM as a Deterministic State Machine

The Ethereum Virtual Machine is a deterministic state machine:

- Given the same starting state and the same transaction, every node must compute the same result.
- Contracts cannot access random internet APIs, system clocks, files, or external services directly.
- State changes happen only through transactions.
- The final result is consensus: every honest node agrees on the new blockchain state.

Mental model:

- `storage` = persistent contract database.
- `memory` = temporary RAM for one function execution.
- `calldata` = read-only request payload.
- `stack` = small temporary EVM working area.

### Transactions vs Calls

| Concept | Changes state? | Costs gas? | Requires signer? | Example |
|---|---:|---:|---:|---|
| Transaction | Yes, if successful | Yes | Yes | `increment()` |
| Call | No | Usually free off-chain | No signer required for reads | `count()` |

Transactions are submitted to the network, included in blocks, and can modify state.

Calls simulate execution locally on a node. They are used for reads and do not persist changes.

```solidity
uint256 public count;

function increment() external {
    count += 1; // transaction required
}

function getCount() external view returns (uint256) {
    return count; // read-only call
}
```

### Gas Basics

Gas is the unit of computation. Users pay gas to execute transactions because validators and nodes must spend resources processing them.

Important gas ideas:

- Writing to storage is expensive.
- Reading from storage is cheaper than writing but still more expensive than memory/calldata.
- Complex loops can make a function too expensive or impossible to execute.
- Reverted transactions still pay for gas used before the revert.
- Read-only calls from a frontend are usually free for the user because they are simulated by a node.

### State Changes vs Read-Only Calls

```solidity
contract Example {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue; // state change
    }

    function doubleValue() external view returns (uint256) {
        return value * 2; // read-only
    }
}
```

**When to use this**

- Use transactions for writes: minting, transferring, updating balances, changing ownership.
- Use calls for reads: balances, names, metadata, configuration, previews.

**Common mistake**

Calling a write function from a frontend as if it were a read. A write needs a wallet signature and a mined transaction.

[Back to top](#table-of-contents)

---

## 2. Primitive & Value Types in Solidity

### In this section
- [Integer Types](#integer-types)
- [Boolean](#boolean)
- [Address](#address)
- [String vs Bytes](#string-vs-bytes)
- [Fixed-Size Bytes](#fixed-size-bytes)
- [Default Values Table](#default-values-table)
- [Type Casting](#type-casting)
- [Gas Considerations](#gas-considerations)

Primitive/value types are copied when assigned or passed around. They are different from reference types such as arrays, mappings, structs, strings, and dynamic `bytes`, which may involve storage, memory, or calldata behavior.

Use this section as the companion to [Arrays, Mappings, Structs, Enums](#4-arrays-mappings-structs-enums): this section covers the basic building blocks, while the next section covers compound/reference-style data structures.

### Integer Types

Solidity supports signed and unsigned integers from 8 bits to 256 bits, in steps of 8.

| Type family | Examples | Range |
|---|---|---|
| Unsigned integers | `uint8`, `uint16`, `uint128`, `uint256`, `uint` | `0` to `2**N - 1` |
| Signed integers | `int8`, `int16`, `int128`, `int256`, `int` | `-2**(N-1)` to `2**(N-1) - 1` |

`uint` is an alias for `uint256`. `int` is an alias for `int256`.

Examples:

```solidity
uint256 public totalSupply; // default: 0
int256 public delta;        // default: 0, can be negative
```

Common ranges:

```solidity
type(uint8).max;   // 255
type(uint256).max; // 2**256 - 1
type(int256).min;  // -2**255
type(int256).max;  // 2**255 - 1
```

**When to use this**

Use `uint256` for balances, token amounts, counters, prices, and most protocol accounting. Use signed integers only when negative values are genuinely part of the model, such as profit/loss deltas or signed price movement.

### Boolean

`bool` stores `true` or `false`. Its default value is `false`.

```solidity
bool public isActive; // default: false

function activate() external {
    isActive = true;
}
```

**When to use this**

Use booleans for flags: paused state, allowlist status, initialization state, or simple yes/no configuration.

### Address

`address` stores a 20-byte Ethereum address. Its default value is the zero address.

```solidity
address public owner;
```

`address payable` is an address that can receive native ETH through Solidity value-transfer operations.

```solidity
address payable public user = payable(msg.sender);
```

Difference:

| Type | Can hold an address? | Can receive `.transfer` / `.send` directly? | Typical use |
|---|---:|---:|---|
| `address` | Yes | No | Owners, users, token contracts, registries |
| `address payable` | Yes | Yes | ETH recipients |

Convert from `address` to `address payable` explicitly:

```solidity
address recipient = msg.sender;
address payable payableRecipient = payable(recipient);
```

Send ETH with `call` in modern Solidity:

```solidity
(bool ok, ) = payable(recipient).call{value: amount}("");
require(ok, "ETH transfer failed");
```

**Common mistake**

Using `address payable` everywhere. Most addresses do not need payable behavior. Keep addresses nonpayable until you actually need to send ETH.

### String vs Bytes

`string` is for UTF-8 text. It is convenient for names, symbols, URIs, and human-readable metadata, but string operations are expensive and limited in Solidity.

`bytes` is a dynamic byte array. It is cheaper and more flexible for raw binary data, encoded calldata, signatures, and arbitrary payloads.

```solidity
string public name;
bytes public rawData;
```

Comparison:

| Type | Best for | Notes |
|---|---|---|
| `string` | Human-readable UTF-8 text | Expensive to manipulate on-chain |
| `bytes` | Raw binary data | Flexible; can inspect length and individual bytes |

```solidity
function setName(string calldata newName) external {
    name = newName;
}

function setRawData(bytes calldata data) external {
    rawData = data;
}
```

**Common mistake**

Trying to compare strings directly with `==`. Hash the encoded values instead.

```solidity
function same(string calldata a, string calldata b) external pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
}
```

### Fixed-Size Bytes

Fixed-size byte arrays range from `bytes1` to `bytes32`.

```solidity
bytes32 public hash;
bytes4 public selector;
```

Use fixed-size bytes for:

- Hashes: `bytes32`.
- Function selectors: `bytes4`.
- Compact identifiers.
- Packed protocol data.
- Values with a known byte length.

```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes4 public constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
```

### Default Values Table

| Type | Default |
|---|---|
| `uint` / `uint256` | `0` |
| `int` / `int256` | `0` |
| `bool` | `false` |
| `address` | `0x0000000000000000000000000000000000000000` |
| `address payable` | `0x0000000000000000000000000000000000000000` |
| `bytes32` | `0x0000000000000000000000000000000000000000000000000000000000000000` |
| `string` | `""` |
| `bytes` | empty byte array |

### Type Casting

Solidity requires explicit casts when converting between many types.

```solidity
uint256 a = 300;
uint8 b = uint8(a); // truncation: b becomes 44
```

The value `300` does not fit into `uint8`, whose max value is `255`. The cast keeps only the lower 8 bits.

Safer version:

```solidity
uint256 a = 300;
require(a <= type(uint8).max, "Too large");
uint8 b = uint8(a);
```

Casting between address-like types:

```solidity
address userAddress = msg.sender;
address payable payableUser = payable(userAddress);
```

Casting to fixed-size bytes can also truncate or pad depending on the conversion. Be explicit and test boundary cases.

**When to use this**

Use casting when interacting with interfaces, packing data, downscaling values for storage, or converting between payable and nonpayable addresses. Validate before narrowing a value.

### Gas Considerations

`uint256` is commonly used because the EVM operates naturally on 256-bit words. Smaller integer types do not automatically make computation cheaper.

Smaller types help most when they are packed together in storage:

```solidity
struct PackedConfig {
    uint128 cap;
    uint64 start;
    uint64 end;
}
```

Here all three values can fit into one 32-byte storage slot. But using small integer types as isolated local variables can add extra masking/conversion work and may not save gas.

**When packing matters**

- State variables stored next to other small values.
- Struct fields written to storage.
- Large arrays of compact structs.
- Upgradeable contracts where layout must stay stable.

### ⚠️ Common Mistakes

- Unsafe casting from a larger type to a smaller type.
- Confusing `string` for human-readable text with `bytes` for raw data.
- Assuming smaller integer types are always cheaper.
- Forgetting default values, especially zero address and `false`.
- Using `address payable` when no ETH transfer is needed.
- Storing large strings on-chain when an event, hash, or off-chain URI would be better.

### ✅ Best Practices

- Prefer `uint256` for most balances, supplies, counters, and amounts.
- Use `bytes32` for hashes and fixed identifiers.
- Avoid unnecessary string usage in on-chain logic.
- Validate before casting to a smaller type.
- Use `address` by default and convert to `address payable` only when sending ETH.
- Group smaller storage fields intentionally when packing improves gas without hurting readability.

[Back to top](#table-of-contents)

---

## 3. Data Locations: storage, memory, calldata, stack

### In this section
- [Comparison Table](#comparison-table)
- [Storage](#storage)
- [Memory](#memory)
- [Calldata](#calldata)
- [Stack](#stack)
- [Reference vs Copy Behavior](#reference-vs-copy-behavior)

Data location tells Solidity where a variable lives and whether it is persistent, temporary, copied, or referenced.

### Comparison Table

| Location | Where it lives | Lifetime | Mutability | Gas profile | Typical use |
|---|---|---|---|---|---|
| `storage` | Contract state on-chain | Persistent | Read/write | Expensive | State variables, persistent structs, mappings, arrays |
| `memory` | Temporary execution memory | One function call | Read/write | Medium | Temporary arrays, structs, return values |
| `calldata` | Transaction or call input data | One external call | Read-only | Cheap | External function parameters |
| `stack` | EVM stack | During execution | Read/write | Very cheap | Local primitive values, internal computation |

### Storage

`storage` is permanent contract state. State variables always live in storage.

```solidity
contract StorageExample {
    uint256[] public numbers;

    function add(uint256 n) external {
        numbers.push(n); // writes to storage
    }
}
```

**When to use this**

Use `storage` when data must persist after the transaction: balances, owners, votes, positions, token metadata.

**Common mistake**

Unnecessary storage writes. Storage is one of the most expensive things you can do in Solidity.

### Memory

`memory` is temporary and disappears after the function finishes.

```solidity
function makeArray() external pure returns (uint256[] memory) {
    uint256[] memory values = new uint256[](3);
    values[0] = 10;
    values[1] = 20;
    values[2] = 30;
    return values;
}
```

**When to use this**

Use `memory` for temporary data that needs to be modified during execution or returned from a function.

### Calldata

`calldata` is read-only input data for external functions. It is usually cheaper than copying data into memory.

```solidity
function sum(uint256[] calldata nums) external pure returns (uint256 total) {
    for (uint256 i = 0; i < nums.length; i++) {
        total += nums[i];
    }
}
```

**When to use this**

Use `calldata` for external function parameters, especially arrays, strings, bytes, and structs that do not need modification.

**Common mistake**

Trying to modify calldata:

```solidity
function bad(uint256[] calldata nums) external pure {
    // nums[0] = 1; // Error: calldata is read-only
}
```

### Stack

The EVM stack holds small local values during execution. You usually do not explicitly mark variables as stack; Solidity handles it.

```solidity
function add(uint256 a, uint256 b) external pure returns (uint256) {
    uint256 result = a + b; // primitive local value lives on the stack when possible
    return result;
}
```

### Reference vs Copy Behavior

Assigning a storage reference modifies the original state:

```solidity
contract ReferenceExample {
    struct User {
        uint256 balance;
    }

    User public user;

    function storageRef() external {
        User storage u = user;
        u.balance = 100; // modifies user.balance in storage
    }
}
```

Assigning to memory creates a copy:

```solidity
function memoryCopy() external view returns (uint256) {
    User memory u = user;
    u.balance = 100; // modifies only the memory copy
    return user.balance; // original storage value unchanged
}
```

Copying from calldata to memory lets you modify the temporary copy:

```solidity
function copyAndEdit(uint256[] calldata input) external pure returns (uint256[] memory) {
    uint256[] memory copy = input;
    copy[0] = 999;
    return copy;
}
```

Related: [Storage Layout](#15-storage-layout) explains how persistent state is physically arranged in slots.

[Back to top](#table-of-contents)

---

## 4. Arrays, Mappings, Structs, Enums

### In this section
- [Arrays](#arrays)
- [Mappings](#mappings)
- [Structs](#structs)
- [Enums](#enums)

### Arrays

```solidity
uint256[] public dynamicArray;
uint256[3] public fixedArray;
```

Common operations:

```solidity
dynamicArray.push(10);
uint256 x = dynamicArray[0];
dynamicArray[0] = 20;
dynamicArray.pop();
uint256 len = dynamicArray.length;
```

Deleting an array element resets it to the default value but does not shrink the array.

```solidity
delete dynamicArray[0]; // sets element to 0
```

**Common mistake**

Looping over an unbounded storage array in a function that must complete on-chain.

### Mappings

```solidity
mapping(address => uint256) public balances;
mapping(address => mapping(address => uint256)) public allowance;
```

Common operations:

```solidity
balances[msg.sender] += msg.value;
uint256 bal = balances[user];
delete balances[user];
```

Mappings return default values for missing keys.

```solidity
balances[unknownUser]; // 0 if never set
```

**Common mistake**

Trying to get all keys from a mapping. Solidity mappings are not iterable by themselves.

### Structs

```solidity
struct User {
    uint128 balance;
    uint64 joinedAt;
    bool active;
}

mapping(address => User) public users;
```

Create and update:

```solidity
function createUser() external {
    users[msg.sender] = User({
        balance: 0,
        joinedAt: uint64(block.timestamp),
        active: true
    });
}

function addBalance(uint128 amount) external {
    User storage user = users[msg.sender];
    user.balance += amount;
}
```

### Enums

Enums represent a fixed set of named states.

```solidity
enum Status {
    Pending,
    Active,
    Closed
}

Status public status;

function activate() external {
    require(status == Status.Pending, "Wrong status");
    status = Status.Active;
}
```

**Common mistake**

Forgetting that enum values are stored as integers starting from 0.

[Back to top](#table-of-contents)

---

## 5. Function Visibility

Visibility controls who can call a function.

| Visibility | Who can call it? | Inherited contracts? | Practical use |
|---|---|---:|---|
| `public` | External users/contracts and internal code | Yes | Public API and generated getters |
| `external` | External users/contracts | Not directly by name internally | Cheaper external APIs with large calldata |
| `internal` | Current contract and children | Yes | Shared internal logic |
| `private` | Current contract only | No | Implementation details |

### Public

```solidity
function balanceOf(address user) public view returns (uint256) {
    return balances[user];
}
```

`public` functions can be called externally and internally. Public state variables automatically get public getter functions.

### External

```solidity
function deposit(uint256 amount, bytes calldata data) external {
    // External API
}
```

`external` is often ideal for functions meant to be called from wallets, frontends, or other contracts.

**Common mistake**

Trying to call an external function internally by name:

```solidity
function a() external {}

function b() external {
    // a(); // Not allowed directly
    this.a(); // External call to self, more expensive and changes msg.sender to address(this)
}
```

If internal reuse is needed, put logic in an `internal` function.

```solidity
function deposit(uint256 amount) external {
    _deposit(msg.sender, amount);
}

function _deposit(address user, uint256 amount) internal {
    // shared logic
}
```

### Internal

```solidity
function _calculateFee(uint256 amount) internal pure returns (uint256) {
    return amount / 100;
}
```

Use `internal` for helper functions and logic shared with inherited contracts.

### Private

```solidity
function _secretFormula(uint256 x) private pure returns (uint256) {
    return x * 42;
}
```

`private` means private to the Solidity contract, not private on-chain. The bytecode and storage are still publicly inspectable.

**Common mistake**

Assuming `private` hides sensitive information. Never store secrets on-chain.

---

---

## 6. Function Mutability

Mutability describes how a function interacts with state and ETH.

| Modifier | Can read state? | Can write state? | Can receive ETH? | Example use |
|---|---:|---:|---:|---|
| `view` | Yes | No | No | Read balances |
| `pure` | No | No | No | Math helpers |
| `payable` | Yes | Yes | Yes | Deposits, mint with ETH |
| default nonpayable | Yes | Yes | No | Normal state-changing functions |

### View

```solidity
function getBalance(address user) external view returns (uint256) {
    return balances[user];
}
```

Use `view` when reading contract state without modifying it.

### Pure

```solidity
function add(uint256 a, uint256 b) external pure returns (uint256) {
    return a + b;
}
```

Use `pure` when the result depends only on inputs and not on blockchain or contract state.

### Payable

```solidity
function deposit() external payable {
    require(msg.value > 0, "No ETH sent");
    balances[msg.sender] += msg.value;
}
```

Use `payable` when a function should accept native ETH.

### Nonpayable by Default

```solidity
function setName(string calldata newName) external {
    name = newName;
}
```

Functions are nonpayable unless marked `payable`. If ETH is sent to a nonpayable function, the transaction reverts.

---

---

## 7. Global Variables

Solidity exposes global variables for transaction, message, block, and contract context.

| Variable | Meaning | Practical use |
|---|---|---|
| `msg.sender` | Immediate caller | Access control, user identity |
| `msg.value` | ETH sent with the call | Deposits, paid minting |
| `msg.data` | Raw calldata | Proxies, fallback logic |
| `tx.origin` | Original EOA that started the transaction | Almost never for auth |
| `block.timestamp` | Current block timestamp | Time windows, vesting |
| `block.number` | Current block number | Block-based delays |
| `address(this)` | Current contract address | Contract balance, self-reference |

### msg.sender

```solidity
address public owner;

function onlyOwnerAction() external {
    require(msg.sender == owner, "Not owner");
}
```

`msg.sender` is the immediate caller. If a user calls Contract A, and Contract A calls Contract B, then inside Contract B, `msg.sender` is Contract A.

### msg.value

```solidity
function mint() external payable {
    require(msg.value == 0.05 ether, "Wrong price");
}
```

`msg.value` is denominated in wei.

### msg.data

`msg.data` contains the raw bytes sent to the function. It includes the 4-byte function selector and encoded arguments.

```solidity
fallback() external payable {
    bytes memory raw = msg.data;
}
```

### tx.origin

`tx.origin` is the original externally owned account that started the transaction.

Warning: Do not use `tx.origin` for authorization.

```solidity
// Dangerous
require(tx.origin == owner, "Not owner");
```

An attacker can trick the owner into calling a malicious contract, which then calls your contract. `tx.origin` would still be the owner.

Use `msg.sender` for access control.

### block.timestamp

```solidity
require(block.timestamp >= saleStart, "Sale not started");
```

Miners/validators have limited influence over timestamps. It is okay for broad time windows, but not secure randomness.

### block.number

```solidity
require(block.number >= unlockBlock, "Too early");
```

Useful for block-based delays, but block times are not perfectly constant.

### address(this)

```solidity
function contractBalance() external view returns (uint256) {
    return address(this).balance;
}
```

---

---

## 8. Errors and Validation

### require

Use `require` for validating inputs, permissions, and external conditions.

```solidity
require(amount > 0, "Amount is zero");
require(msg.sender == owner, "Not owner");
```

### revert

Use `revert` when the condition is more naturally expressed with an `if`.

```solidity
if (amount == 0) {
    revert("Amount is zero");
}
```

### assert

Use `assert` for internal invariants that should never be false.

```solidity
uint256 oldTotal = totalSupply;
totalSupply += amount;
assert(totalSupply >= oldTotal);
```

In Solidity 0.8+, arithmetic overflow checks are built in, so many old `assert` examples are unnecessary.

### Custom Errors

Custom errors are cheaper than revert strings because they avoid storing long strings in bytecode and return compact encoded error data.

```solidity
error NotOwner(address caller);
error AmountZero();

function withdraw(uint256 amount) external {
    if (msg.sender != owner) revert NotOwner(msg.sender);
    if (amount == 0) revert AmountZero();
}
```

| Pattern | Readability | Gas profile | Use |
|---|---|---:|---|
| `require(x, "message")` | Very simple | More expensive | Quick validation, simple contracts |
| `revert CustomError()` | Clear and efficient | Cheaper | Production contracts |
| `assert(x)` | For invariants | Special failure | Internal impossible states |

---

---

## 9. Modifiers

Modifiers wrap reusable checks or behavior around functions.

### onlyOwner

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

function setFee(uint256 newFee) external onlyOwner {
    fee = newFee;
}
```

The `_` means "run the function body here."

### nonReentrant

```solidity
uint256 private locked = 1;

modifier nonReentrant() {
    require(locked == 1, "Reentrant");
    locked = 2;
    _;
    locked = 1;
}
```

Practical version: use a trusted implementation like OpenZeppelin `ReentrancyGuard`.

### When Modifiers Are Useful

Use modifiers for:

- Access control.
- Reentrancy protection.
- Pausing.
- Repeated input validation.

### When Modifiers Reduce Readability

Avoid modifiers when:

- They modify important state in non-obvious ways.
- They contain complex branching.
- They perform external calls.
- The function behavior becomes hard to audit.

**Common mistake**

Hiding important business logic inside modifiers. Auditors and maintainers should not have to hunt for core behavior.

---

---

## 10. Events and Logs

Events write logs to the transaction receipt. They are cheap compared with storage and useful for off-chain systems.

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

function transfer(address to, uint256 amount) external {
    balances[msg.sender] -= amount;
    balances[to] += amount;
    emit Transfer(msg.sender, to, amount);
}
```

### indexed Parameters

`indexed` parameters can be filtered efficiently by frontends and indexers.

```solidity
event Deposit(address indexed user, uint256 amount);
```

You can have up to 3 indexed parameters in a normal event.

### Why Events Are Useful

Events are used for:

- Frontend updates.
- Analytics.
- Indexers such as The Graph.
- Audit trails.
- Token transfer history.

**Common mistake**

Using events as on-chain storage. Contracts cannot easily read old logs. Events are for off-chain consumers.

---

---

## 11. ETH Handling

### In this section
- [receive()](#receive)
- [fallback()](#fallback)
- [receive vs fallback](#receive-vs-fallback)
- [transfer](#transfer)
- [send](#send)
- [call{value: amount}("")](#callvalue-amount)
- [Safe Withdraw Example](#safe-withdraw-example)

Native ETH is not an ERC20 token. It is held directly by addresses and moved with value transfers.

### receive()

`receive()` runs when ETH is sent with empty calldata.

```solidity
receive() external payable {
    // Accept plain ETH transfers
}
```

### fallback()

`fallback()` runs when no function matches the calldata. It can also receive ETH if marked `payable`.

```solidity
fallback() external payable {
    // Handle unknown function calls or proxy forwarding
}
```

### receive vs fallback

| Scenario | Function called |
|---|---|
| Empty calldata and `receive()` exists | `receive()` |
| Empty calldata and no `receive()` | payable `fallback()` |
| Non-empty calldata and no matching function | `fallback()` |
| ETH sent to nonpayable fallback/receive | Revert |

### transfer

```solidity
payable(to).transfer(amount);
```

`transfer` forwards 2300 gas and reverts on failure. It was once common, but it can fail when recipient contracts need more gas.

### send

```solidity
bool ok = payable(to).send(amount);
require(ok, "Send failed");
```

`send` forwards 2300 gas and returns `false` on failure instead of reverting automatically.

### call{value: amount}("")

```solidity
(bool ok, ) = payable(to).call{value: amount}("");
require(ok, "ETH transfer failed");
```

`call` forwards configurable gas and returns success plus return data. It is preferred today because fixed 2300 gas assumptions became fragile after gas cost changes.

Warning: `call` can trigger arbitrary code in the recipient. Use Checks-Effects-Interactions and reentrancy protection.

### Safe Withdraw Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PullPayments {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        balances[msg.sender] = 0; // effect before interaction

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
}
```

**When to use this**

Prefer pull payments, where users withdraw their funds, over pushing ETH to many recipients in a loop.

**Common mistake**

Sending ETH before updating balances. That creates reentrancy risk.

[Back to top](#table-of-contents)

---

## 12. ABI Encoding

### In this section
- [Function Selectors](#function-selectors)
- [abi.encode](#abiencode)
- [abi.encodePacked](#abiencodepacked)
- [abi.decode](#abidecode)
- [abi.encodeWithSignature](#abiencodewithsignature)
- [abi.encodeWithSelector](#abiencodewithselector)
- [Practical Example](#practical-example)

ABI means Application Binary Interface. It defines how function calls, arguments, return values, and events are encoded.

### Function Selectors

A function selector is the first 4 bytes of:

```solidity
bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
```

The canonical function signature has no spaces and uses canonical types:

- `uint` becomes `uint256`
- `int` becomes `int256`
- `address payable` becomes `address`

### abi.encode

`abi.encode` produces standard ABI-encoded bytes with padding and type boundaries.

```solidity
bytes memory data = abi.encode(address(0x1234), uint256(100));
(address user, uint256 amount) = abi.decode(data, (address, uint256));
```

Use it for safe encoding and decoding.

### abi.encodePacked

`abi.encodePacked` produces compact packed bytes.

```solidity
bytes memory packed = abi.encodePacked("hello", uint256(123));
```

Warning: Packed encoding can collide with dynamic types.

```solidity
keccak256(abi.encodePacked("ab", "c"));
keccak256(abi.encodePacked("a", "bc"));
// Same packed bytes: "abc"
```

Use `abi.encode` when hashing multiple dynamic values unless you add clear separators or fixed-size fields.

### abi.decode

```solidity
bytes memory data = abi.encode(uint256(7), true);
(uint256 n, bool ok) = abi.decode(data, (uint256, bool));
```

Types must match the encoded data.

### abi.encodeWithSignature

```solidity
bytes memory callData = abi.encodeWithSignature(
    "approve(address,uint256)",
    spender,
    amount
);
```

Useful for low-level calls when you know the function signature as a string.

### abi.encodeWithSelector

```solidity
bytes memory callData = abi.encodeWithSelector(
    IERC20.approve.selector,
    spender,
    amount
);
```

Prefer this when you have an interface because the selector is compiler-checked.

### Practical Example

```solidity
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

function lowLevelTransfer(address token, address to, uint256 amount) external {
    bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, to, amount);
    (bool ok, bytes memory result) = token.call(data);
    require(ok, "Call failed");

    if (result.length > 0) {
        require(abi.decode(result, (bool)), "Transfer returned false");
    }
}
```

[Back to top](#table-of-contents)

---

## 13. Low-Level Calls: call, delegatecall, staticcall

### In this section
- [call](#call)
- [delegatecall](#delegatecall)
- [staticcall](#staticcall)
- [abi.encodeWithSignature](#abiencodewithsignature-1)
- [abi.encodeWithSelector](#abiencodewithselector-1)
- [Security Risks](#security-risks)

Low-level calls let contracts interact using raw calldata instead of typed Solidity interfaces.

| Operation | Can modify target state? | Preserves caller context? | Common use |
|---|---:|---:|---|
| `call` | Yes | No | Generic external calls, ETH transfers |
| `delegatecall` | Writes to caller storage | Yes, in caller context | Proxies, libraries |
| `staticcall` | No | No | Read-only external calls |

### call

Input:

- Target address.
- Optional ETH value.
- Encoded calldata.

Output:

- `bool success`
- `bytes memory returnData`

```solidity
(bool success, bytes memory data) = target.call(
    abi.encodeWithSignature("setValue(uint256)", 123)
);
require(success, "Call failed");
```

Use `call` for generic interactions when you do not have or cannot use a typed interface.

### delegatecall

`delegatecall` executes target code in the calling contract's context:

- `address(this)` remains the calling contract.
- `msg.sender` remains the original caller.
- Storage writes modify the calling contract's storage.

```solidity
(bool success, bytes memory data) = implementation.delegatecall(msg.data);
require(success, "Delegatecall failed");
```

Use `delegatecall` for proxy patterns and some library patterns.

Warning: `delegatecall` is dangerous. If storage layouts do not match, state can be corrupted. If the implementation is malicious, it can take over the proxy's storage and funds.

### staticcall

`staticcall` is a read-only low-level call. The target cannot modify state during the call.

```solidity
(bool success, bytes memory data) = target.staticcall(
    abi.encodeWithSignature("balanceOf(address)", user)
);
require(success, "Staticcall failed");
uint256 balance = abi.decode(data, (uint256));
```

Use `staticcall` for low-level reads.

### abi.encodeWithSignature

```solidity
bytes memory data = abi.encodeWithSignature(
    "transfer(address,uint256)",
    recipient,
    amount
);
```

The function name and parameter types are provided as a string.

### abi.encodeWithSelector

```solidity
bytes4 selector = IERC20.transfer.selector;
bytes memory data = abi.encodeWithSelector(selector, recipient, amount);
```

Prefer selectors when available because they are checked by the compiler.

### Security Risks

- Ignoring the `success` boolean.
- Calling untrusted contracts before updating state.
- Using `delegatecall` with untrusted implementations.
- Assuming return data exists or has the expected type.
- Accidentally sending ETH to arbitrary addresses.

**When to use this**

Use typed interfaces for normal contract interactions. Reach for low-level calls only for proxies, optional return handling, generic routers, plugin systems, or advanced integrations.

Related: [ABI Encoding](#12-abi-encoding) explains how calldata is built, and [Assembly & Yul](#14-assembly--yul) shows low-level proxy mechanics.

[Back to top](#table-of-contents)

---

## 14. Assembly & Yul

### In this section
- [What Assembly Is](#what-assembly-is)
- [What Yul Is](#what-yul-is)
- [Assembly vs unchecked](#assembly-vs-unchecked)
- [Basic Syntax](#basic-syntax)
- [Common Yul Operations](#common-yul-operations)
- [Memory Basics](#memory-basics)
- [Storage Basics](#storage-basics)
- [Calldata Basics](#calldata-basics)
- [Delegatecall Proxy Example](#delegatecall-proxy-example)

Inline assembly lets you write low-level Yul code inside Solidity using `assembly { ... }`. It is useful for advanced EVM work, but it removes many of Solidity's safety rails.

### What Assembly Is

Solidity assembly:

- Is written inside `assembly { ... }` blocks.
- Uses Yul syntax.
- Is not JavaScript.
- Is not the same as `unchecked`.
- Is lower-level than normal Solidity.
- Gives direct access to EVM-like operations for memory, storage, calldata, return data, and calls.

```solidity
function addRaw() external pure returns (uint256 result) {
    assembly {
        result := add(1, 2)
    }
}
```

**Common mistake**

Thinking assembly is just "faster Solidity." It is closer to manual EVM programming, where you are responsible for layout, offsets, and safety.

### What Yul Is

Yul is a low-level intermediate language used by Solidity and the EVM toolchain. Solidity can compile through an intermediate representation, and Yul is also available directly inside inline assembly blocks.

Yul can manipulate:

- Memory.
- Storage.
- Calldata.
- Return data.
- Low-level calls.
- Opcodes-like operations.

Yul is intentionally small and close to the EVM. That makes it powerful for infrastructure code, but it also means fewer guardrails.

### Assembly vs unchecked

| Feature | `unchecked` | `assembly` / Yul |
|---|---|---|
| Purpose | Disable arithmetic overflow checks | Low-level EVM programming |
| Scope | Arithmetic only | Memory, storage, calldata, calls, return data |
| Safety | Less safe than normal Solidity | Much more dangerous |
| Use case | Gas optimization in safe loops | Proxies, custom encoding, gas-critical code |

`unchecked` only affects Solidity arithmetic checks. Assembly can read and write raw memory, raw storage slots, raw calldata, and perform low-level calls.

### Basic Syntax

```solidity
assembly {
    let x := add(1, 2)
}
```

Syntax notes:

- `let` declares a Yul variable.
- `:=` assigns a value.
- `add(1, 2)` uses a low-level operation.
- Yul variables exist only inside the assembly block.

### Solidity vs Yul Comparison

Solidity:

```solidity
uint256 x = a + b;
```

Equivalent-ish Yul:

```solidity
assembly {
    let x := add(a, b)
}
```

They look similar logically, but Yul has fewer safety checks. In normal Solidity 0.8+, `a + b` reverts on overflow. In assembly, `add(a, b)` wraps like raw EVM arithmetic.

### Common Yul Operations

| Operation | Meaning |
|---|---|
| `add(x, y)` | Addition |
| `sub(x, y)` | Subtraction |
| `mul(x, y)` | Multiplication |
| `div(x, y)` | Division |
| `mload(p)` | Load 32 bytes from memory |
| `mstore(p, v)` | Store 32 bytes in memory |
| `sload(p)` | Load storage slot |
| `sstore(p, v)` | Store storage slot |
| `calldataload(p)` | Load calldata |
| `returndatacopy(...)` | Copy returned data |
| `call(...)` | Low-level external call |
| `delegatecall(...)` | Execute target code in caller storage context |
| `revert(p, s)` | Revert with memory range |
| `return(p, s)` | Return memory range |

### Memory Basics

Memory in Solidity and Yul is byte-addressed, but values are usually handled in 32-byte words. Solidity reserves memory slot `0x40` for the free memory pointer. `mload(0x40)` gives the next free memory location.

```solidity
function getFreeMemoryPointer() external pure returns (uint256 ptr) {
    assembly {
        ptr := mload(0x40)
    }
}
```

This reads the memory word at address `0x40`. Solidity stores the pointer to the next unused memory location there. If you manually write to memory, you must avoid corrupting memory Solidity expects to manage.

### Storage Basics

Storage is organized into 32-byte slots. State variables are assigned slots according to Solidity's storage layout rules.

```solidity
uint256 public x = 10;

function readSlotZero() external view returns (uint256 value) {
    assembly {
        value := sload(0)
    }
}
```

If `x` is the first state variable, it is stored in slot `0`. `sload(0)` reads slot `0` directly.

Warning: Direct storage slot access is dangerous. Storage layout, packing, inheritance, mappings, dynamic arrays, and upgradeable proxies all affect where data actually lives.

### Calldata Basics

Calldata is the raw input sent to the contract.

- The first 4 bytes are the function selector.
- The following bytes are ABI-encoded arguments.

```solidity
function readFirstArg(uint256) external pure returns (uint256 arg) {
    assembly {
        arg := calldataload(4)
    }
}
```

Offset `4` skips the function selector and reads the first 32-byte ABI argument.

**Common mistake**

Miscalculating calldata offsets for dynamic types such as `bytes`, `string`, and arrays. Dynamic ABI encoding uses offsets and length fields, not just inline values.

### Return and Revert in Assembly

Return 32 bytes:

```solidity
assembly {
    mstore(0x00, 123)
    return(0x00, 0x20)
}
```

This stores `123` in memory at `0x00`, then returns `0x20` bytes, which is 32 bytes.

Revert with no data:

```solidity
assembly {
    revert(0, 0)
}
```

`revert(p, s)` reverts with the memory range starting at `p` and length `s`.

### Delegatecall Proxy Example

Many proxy patterns work by copying calldata, delegating execution to an implementation, then bubbling up the return data or revert data.

```solidity
address public implementation;

fallback() external payable {
    address impl = implementation;

    assembly {
        calldatacopy(0, 0, calldatasize())

        let result := delegatecall(
            gas(),
            impl,
            0,
            calldatasize(),
            0,
            0
        )

        returndatacopy(0, 0, returndatasize())

        switch result
        case 0 {
            revert(0, returndatasize())
        }
        default {
            return(0, returndatasize())
        }
    }
}
```

Step by step:

- `calldatacopy(0, 0, calldatasize())` copies the user's calldata into memory.
- `delegatecall(...)` executes the implementation code in the proxy's storage context.
- `returndatacopy(0, 0, returndatasize())` copies whatever the implementation returned.
- `switch result` checks whether the delegatecall succeeded.
- `revert(0, returndatasize())` bubbles up the implementation's revert data.
- `return(0, returndatasize())` bubbles up the implementation's return data.

Warning: This example is simplified. Production proxies need carefully chosen storage slots, admin controls, upgrade authorization, initialization protection, and tests.

### Why Assembly Is Useful

Assembly is useful for:

- Gas optimization.
- Proxy patterns.
- Low-level memory manipulation.
- Custom ABI encoding/decoding.
- Reading or writing specific storage slots.
- Advanced libraries.
- Audits and exploit analysis.

### Why Assembly Is Dangerous

Assembly is dangerous because:

- There is no Solidity type safety.
- There are no automatic overflow checks.
- It is easy to corrupt memory.
- It is easy to corrupt storage.
- It is harder to audit.
- Small mistakes can create critical vulnerabilities.

### When to Use Assembly

Use assembly when:

- Solidity cannot express the operation cleanly.
- You need critical gas optimization.
- You are implementing low-level infrastructure.
- You fully understand the memory/storage/calldata layout.

Avoid assembly when:

- Normal Solidity is clear enough.
- The code handles business-critical funds and assembly is unnecessary.
- You are not sure how the EVM layout works.
- Readability and auditability matter more than micro-optimization.

### ✅ Best Practices

- Prefer normal Solidity first.
- Keep assembly blocks small.
- Comment every non-trivial assembly line.
- Never use assembly just to look advanced.
- Avoid writing to arbitrary storage slots unless you fully understand layout.
- Test assembly-heavy code with unit tests, fuzz tests, and edge cases.
- Be extra careful with `delegatecall`.
- Use audited libraries when possible.

### ⚠️ Common Mistakes

- Thinking Yul is JavaScript because the syntax looks similar.
- Thinking assembly is the same as `unchecked`.
- Forgetting that assembly arithmetic can wrap.
- Reading the wrong storage slot.
- Miscalculating calldata offsets.
- Returning the wrong memory range.
- Corrupting the free memory pointer.
- Using `delegatecall` with incompatible storage layout.

### Mental Model

Solidity is the high-level safer language. `unchecked` disables arithmetic checks only. Assembly/Yul gives low-level manual control over EVM execution. Use it like a scalpel, not a hammer.

Related: review [Low-Level Calls: call, delegatecall, staticcall](#13-low-level-calls-call-delegatecall-staticcall), [ABI Encoding](#12-abi-encoding), and [Storage Layout](#15-storage-layout) before writing assembly-heavy code.

[Back to top](#table-of-contents)

---

## 15. Storage Layout

### In this section
- [Storage Slots](#storage-slots)
- [Variable Packing](#variable-packing)
- [Struct Packing](#struct-packing)
- [Dynamic Arrays](#dynamic-arrays)
- [Mappings](#mappings-1)
- [Why Storage Layout Matters](#why-storage-layout-matters)

Storage layout describes how Solidity places state variables into 32-byte storage slots.

### Storage Slots

Each storage slot is 32 bytes.

```solidity
contract Layout {
    uint256 a; // slot 0
    uint256 b; // slot 1
}
```

### Variable Packing

Small variables can share one slot if they are adjacent and fit into 32 bytes.

```solidity
contract Packed {
    uint128 a; // slot 0, first half
    uint128 b; // slot 0, second half
    uint256 c; // slot 1
}
```

Bad packing:

```solidity
contract Unpacked {
    uint128 a; // slot 0
    uint256 b; // slot 1
    uint128 c; // slot 2
}
```

### Struct Packing

Struct fields are packed similarly.

```solidity
struct Position {
    uint128 amount;
    uint64 start;
    uint64 end;
}
```

All three fields fit into one 32-byte slot.

### Dynamic Arrays

For a dynamic array at slot `p`:

- Slot `p` stores the array length.
- Elements start at `keccak256(p)`.

```solidity
uint256[] public values; // length at slot 0, elements at keccak256(0)
```

### Mappings

For a mapping at slot `p`, the value for key `k` is stored at:

```text
keccak256(abi.encode(k, p))
```

```solidity
mapping(address => uint256) public balances; // slot p
```

Mappings do not store keys and cannot be iterated without storing a separate key list.

### Why Storage Layout Matters

Storage layout matters for:

- Gas: fewer slots can mean cheaper writes and reads.
- Upgradeable contracts: changing slot order can corrupt state.
- Audits: understanding where important values live.
- Low-level debugging: inspecting storage with tools.

**Common mistake**

Reordering variables in an upgradeable contract. This can make a proxy interpret old state as a different variable.

[Back to top](#table-of-contents)

---

## 16. Inheritance and Interfaces

### Contract Inheritance

```solidity
contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}

contract Vault is Ownable {
    function sweep() external onlyOwner {
        // owner-only logic
    }
}
```

### virtual and override

Parent functions must be marked `virtual` to allow child contracts to override them. Child functions use `override`.

```solidity
contract Base {
    function fee() public pure virtual returns (uint256) {
        return 100;
    }
}

contract Child is Base {
    function fee() public pure override returns (uint256) {
        return 50;
    }
}
```

### Interfaces

Interfaces define external function signatures without implementation.

```solidity
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

function pay(address token, address to, uint256 amount) external {
    IERC20(token).transfer(to, amount);
}
```

### Abstract Contracts

Abstract contracts can contain both implemented and unimplemented functions.

```solidity
abstract contract Strategy {
    function name() external pure virtual returns (string memory);

    function version() external pure returns (uint256) {
        return 1;
    }
}
```

**When to use this**

- Use interfaces for external compatibility.
- Use abstract contracts for shared base logic.
- Use inheritance carefully; deep inheritance trees are harder to audit.

---

---

## 17. ERC Standards

ERC standards define common interfaces so wallets, marketplaces, and protocols can interact with tokens consistently.

### ERC20

ERC20 represents fungible tokens. Every unit is equivalent to every other unit.

Examples:

- Stablecoins.
- Governance tokens.
- Utility tokens.

Common functions:

```solidity
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address to, uint256 amount) external returns (bool);
function approve(address spender, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function transferFrom(address from, address to, uint256 amount) external returns (bool);
```

Key terms:

- `mint`: create new tokens and increase total supply.
- `burn`: destroy tokens and decrease total supply.
- `transfer`: move tokens from `msg.sender` to another address.
- `approve`: allow a spender to use tokens on your behalf.
- `allowance`: amount a spender is allowed to spend.
- `transferFrom`: move tokens using an allowance.

Approval flow:

1. Alice calls `approve(spender, 100)`.
2. Spender calls `transferFrom(alice, recipient, 100)`.
3. Token contract checks and decreases allowance.

### ERC721

ERC721 represents non-fungible tokens. Each token ID is unique.

Examples:

- Art NFTs.
- Collectibles.
- Unique game assets.
- Membership passes.

Common functions:

- `ownerOf(tokenId)`
- `balanceOf(owner)`
- `approve(to, tokenId)`
- `setApprovalForAll(operator, approved)`
- `transferFrom(from, to, tokenId)`
- `safeTransferFrom(from, to, tokenId)`

`safeTransferFrom` checks whether a receiving contract supports ERC721 receiving hooks, which helps avoid locking NFTs in contracts that cannot handle them.

### ERC1155

ERC1155 supports multiple token types in one contract. Each ID can be fungible, non-fungible, or semi-fungible.

Examples:

- Game items.
- Editions.
- Mixed collections.

Common functions:

- `balanceOf(account, id)`
- `balanceOfBatch(accounts, ids)`
- `safeTransferFrom(from, to, id, amount, data)`
- `safeBatchTransferFrom(from, to, ids, amounts, data)`
- `setApprovalForAll(operator, approved)`

### Fungible vs Non-Fungible

| Standard | Token type | Identity | Example |
|---|---|---|---|
| ERC20 | Fungible | Units are interchangeable | 1 USDC equals another 1 USDC |
| ERC721 | Non-fungible | Each token ID is unique | NFT #123 |
| ERC1155 | Multi-token | Depends on ID and amount | 100 swords, 1 rare item |

---

---

## 18. Access Control

Access control decides who can perform privileged actions.

### Owner Pattern

```solidity
contract OwnableSimple {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
```

### Ownable

In production, prefer audited libraries such as OpenZeppelin `Ownable`.

Typical owner-only actions:

- Set protocol fees.
- Pause/unpause.
- Upgrade implementation.
- Withdraw protocol revenue.

### Role-Based Access Control

Role-based access control gives different permissions to different accounts.

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
mapping(bytes32 => mapping(address => bool)) public hasRole;

modifier onlyRole(bytes32 role) {
    require(hasRole[role][msg.sender], "Missing role");
    _;
}

function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    // mint logic
}
```

### Common Mistakes

- Forgetting to initialize the owner.
- Using `tx.origin` for authorization.
- Giving admin roles to a hot wallet.
- No way to transfer or renounce ownership safely.
- Over-centralizing controls without transparency.
- Missing access control on upgrade, mint, pause, or withdraw functions.

[Back to top](#table-of-contents)

---

## 19. Arithmetic Safety: Overflow & Underflow

Arithmetic safety is about making sure numeric operations cannot silently produce values outside the intended range. This matters for balances, shares, token supply, voting power, accounting, and almost every financial invariant in a smart contract.

### Definitions

| Term | Meaning | Intuitive model |
|---|---|---|
| Overflow | A value exceeds the maximum range of its type | Going past the ceiling |
| Underflow | A value goes below the minimum range of its type | Going below the floor |
| Wrap-around | The value loops around to the other side of the range | Ceiling/floor wraps like a circular counter |

EVM integers are fixed-size. A `uint8` can hold values from `0` to `255`; a `uint256` can hold values from `0` to `2**256 - 1`. At the raw EVM arithmetic level, exceeding these limits wraps around modulo `2**N`, where `N` is the integer size.

### Overflow Example

```solidity
uint8 x = 255;
x += 1; // overflow
```

Old behavior in Solidity `< 0.8.0`:

```solidity
uint8 x = 255;
x += 1;
// x becomes 0 because uint8 wraps around after 255
```

New behavior in Solidity `>= 0.8.0`:

```solidity
uint8 x = 255;
x += 1;
// reverts automatically because checked arithmetic is enabled by default
```

### Underflow Example

```solidity
uint8 x = 0;
x -= 1; // underflow
```

Old behavior in Solidity `< 0.8.0`:

```solidity
uint8 x = 0;
x -= 1;
// x becomes 255 because uint8 wraps below 0
```

New behavior in Solidity `>= 0.8.0`:

```solidity
uint8 x = 0;
x -= 1;
// reverts automatically because checked arithmetic is enabled by default
```

Solidity 0.8+ automatically reverts on overflow and underflow in normal arithmetic. This is one of the most important safety improvements in modern Solidity, and it is called out in both the [Solidity documentation](https://docs.solidity.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic) and [OWASP Smart Contract Security guidance](https://scs.owasp.org/sctop10/SC09-IntegerOverflowUnderflow/).

### Old vs New Behavior

| Operation | Solidity `< 0.8.0` | Solidity `>= 0.8.0` |
|---|---|---|
| `uint8(255) + 1` | Wraps to `0` | Reverts |
| `uint8(0) - 1` | Wraps to `255` | Reverts |
| `uint256 max + 1` | Wraps to `0` | Reverts |
| `0 - amount` for unsigned ints | Wraps to a huge number | Reverts |

⚠️ Common mistake

Assuming Solidity 0.8+ prevents every possible numeric wrap. It protects normal checked arithmetic, but not every edge case. See [Edge Cases Where Overflow Still Happens](#edge-cases-where-overflow-still-happens).

### unchecked Blocks

`unchecked` disables Solidity's automatic overflow and underflow checks inside a block.

```solidity
uint256 x = 1;

unchecked {
    x++; // no overflow check
}
```

Why it exists:

- Checked arithmetic costs extra gas.
- Some operations are provably safe.
- Tight loops can save gas by using `unchecked` increments.
- Low-level code sometimes intentionally relies on modulo arithmetic.

Example of a commonly safe use:

```solidity
function sum(uint256[] calldata values) external pure returns (uint256 total) {
    uint256 length = values.length;

    for (uint256 i = 0; i < length; ) {
        total += values[i];

        unchecked {
            ++i; // safe because i is bounded by values.length
        }
    }
}
```

Dangerous use:

```solidity
function subtract(uint256 a, uint256 b) external pure returns (uint256) {
    unchecked {
        return a - b; // dangerous if b > a
    }
}
```

✅ Best practice

Use `unchecked` only when you can explain the invariant that makes overflow or underflow impossible. If the explanation is not obvious, add a short comment or avoid `unchecked`.

### Security Implications

Overflow and underflow caused real smart contract exploits before checked arithmetic became the default. The usual failure mode was broken accounting: balances, allowances, supplies, or counters wrapped into values the developer never intended.

Classic underflow risk:

```solidity
mapping(address => uint256) public balance;

function withdraw(uint256 amount) external {
    balance[msg.sender] -= amount; // old Solidity: underflows if amount > balance

    // send funds or tokens...
}
```

In old Solidity, if `balance[msg.sender]` was `0` and `amount` was `1`, the subtraction could wrap to `2**256 - 1`, giving the attacker a massive apparent balance.

Modern Solidity `>= 0.8.0` reverts in this situation, but you should still validate intent explicitly:

```solidity
function withdraw(uint256 amount) external {
    require(amount > 0, "Amount is zero");
    require(balance[msg.sender] >= amount, "Insufficient balance");

    balance[msg.sender] -= amount;

    // send funds or tokens...
}
```

⚠️ Common mistake

Relying only on automatic arithmetic checks for user-facing validation. A revert is safer than wrap-around, but clear `require` checks produce better errors and make business rules explicit.

### Best Practices

- Use Solidity `>= 0.8.0`.
- Validate inputs with `require`, especially balances, limits, and user-supplied amounts.
- Avoid `unchecked` unless it is provably safe.
- Use `uint256` for balances, supplies, and most accounting values.
- Test edge cases: `0`, `1`, max values, empty arrays, full balances, and insufficient balances.
- Be extra careful around casts, assembly, and low-level arithmetic.
- Prefer audited libraries for complex math such as fixed-point arithmetic.

### Edge Cases Where Overflow Still Happens

Solidity 0.8+ protects normal arithmetic, but wrap-around can still happen in specific places.

#### unchecked Blocks

```solidity
uint8 x = 255;

unchecked {
    x += 1;
}

// x is now 0
```

#### Inline Assembly / Yul

Arithmetic in inline assembly uses raw EVM behavior. It does not automatically use Solidity's checked arithmetic.

```solidity
function addRaw(uint256 a, uint256 b) external pure returns (uint256 result) {
    assembly {
        result := add(a, b) // wraps on overflow
    }
}
```

#### Type Casting

Explicit casts to a smaller integer type can truncate high bits.

```solidity
uint256 a = 258;
uint8 b = uint8(a); // overflow/truncation: b becomes 2
```

This does not revert just because `a` is too large for `uint8`.

Safer version:

```solidity
uint256 a = 258;
require(a <= type(uint8).max, "Too large for uint8");
uint8 b = uint8(a);
```

### Mental Model

Overflow is going past the ceiling. Underflow is going below the floor. In raw EVM arithmetic, both wrap around like a circular counter. Solidity 0.8+ adds guardrails for normal arithmetic, but `unchecked`, assembly, and narrowing casts can still expose wrap-around behavior.

Related sections:

- [Security Fundamentals](#20-security-fundamentals): arithmetic bugs are accounting and invariant bugs.
- [Gas Optimization](#21-gas-optimization): `unchecked` can save gas when the bounds are proven.

[Back to top](#table-of-contents)

---

## 20. Security Fundamentals

### In this section
- [Reentrancy](#reentrancy)
- [Checks-Effects-Interactions](#checks-effects-interactions)
- [Access Control Bugs](#access-control-bugs)
- [Integer Overflow and Underflow](#integer-overflow-and-underflow)
- [Front-Running](#front-running)
- [Timestamp Manipulation](#timestamp-manipulation)
- [Denial of Service](#denial-of-service)
- [Delegatecall Risks](#delegatecall-risks)
- [Signature Replay Attacks](#signature-replay-attacks)
- [Approval Risks](#approval-risks)
- [Randomness Risks](#randomness-risks)

Security is not a final checklist. It is a design habit.

### Reentrancy

Reentrancy happens when an external call lets another contract call back into your contract before your first function finishes.

Dangerous:

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "Nothing");

    (bool ok, ) = msg.sender.call{value: amount}("");
    require(ok, "Failed");

    balances[msg.sender] = 0; // too late
}
```

Safer:

```solidity
function withdraw() external nonReentrant {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "Nothing");

    balances[msg.sender] = 0;

    (bool ok, ) = msg.sender.call{value: amount}("");
    require(ok, "Failed");
}
```

### Checks-Effects-Interactions

Order your function:

1. Checks: validate permissions and inputs.
2. Effects: update internal state.
3. Interactions: call external contracts or send ETH.

### Access Control Bugs

Any privileged function must answer:

- Who can call it?
- What happens if the admin key is compromised?
- Is the role initialized?
- Can roles be transferred safely?

### Integer Overflow and Underflow

Solidity 0.8+ checks overflow and underflow by default.

```solidity
uint256 x = 0;
// x -= 1; // reverts in Solidity 0.8+
```

Use `unchecked` only when you can prove overflow is impossible.

For the full production-focused guide, see [Arithmetic Safety: Overflow & Underflow](#19-arithmetic-safety-overflow--underflow).

### Front-Running

Transactions sit in the mempool before inclusion. Attackers can see pending transactions and submit their own with higher priority fees.

Risks:

- DEX trades.
- Auctions.
- Public claims.
- NFT mint reveals.

Mitigations:

- Commit-reveal schemes.
- Slippage limits.
- Deadlines.
- Private order flow where appropriate.

### Timestamp Manipulation

`block.timestamp` can be slightly influenced. Do not use it for secure randomness.

### Denial of Service

DoS can happen if a function becomes impossible to execute.

Common causes:

- Unbounded loops over growing arrays.
- Pushing ETH to many users in one transaction.
- Depending on an external call that can revert.

### Delegatecall Risks

`delegatecall` can modify the caller's storage. A malicious or incompatible implementation can corrupt state or steal funds.

### Signature Replay Attacks

If a signed message can be reused, an attacker may replay it.

Mitigate with:

- Nonces.
- Deadlines.
- `chainId`.
- Contract address in the signed domain.
- EIP-712 structured data.

### Approval Risks

ERC20 approvals can be dangerous:

- Unlimited approvals expose users if the spender is compromised.
- Changing allowance from nonzero to nonzero can create race conditions in some flows.
- Users may forget old approvals.

### Randomness Risks

Bad randomness:

```solidity
uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
```

This can be influenced or predicted.

Use a secure randomness oracle such as Chainlink VRF for high-value randomness.

Related: [Access Control](#18-access-control), [ETH Handling](#11-eth-handling), and [Low-Level Calls: call, delegatecall, staticcall](#13-low-level-calls-call-delegatecall-staticcall) are common sources of production vulnerabilities.

[Back to top](#table-of-contents)

---

## 21. Gas Optimization

### In this section
- [calldata over memory](#calldata-over-memory)
- [Caching Storage Reads](#caching-storage-reads)
- [Avoiding Unnecessary Storage Writes](#avoiding-unnecessary-storage-writes)
- [Variable Packing](#variable-packing-1)
- [unchecked](#unchecked)
- [Custom Errors](#custom-errors-1)
- [Events vs Storage](#events-vs-storage)
- [Loop Risks](#loop-risks)

Gas optimization should not come before correctness and security. Optimize after you understand the behavior.

### calldata over memory

```solidity
function process(uint256[] calldata values) external pure returns (uint256 total) {
    for (uint256 i = 0; i < values.length; i++) {
        total += values[i];
    }
}
```

Use `calldata` for external read-only parameters.

### Caching Storage Reads

```solidity
uint256 length = users.length;
for (uint256 i = 0; i < length; i++) {
    // use length instead of reading users.length every time
}
```

Storage reads cost more than stack/memory reads.

### Avoiding Unnecessary Storage Writes

```solidity
function setFee(uint256 newFee) external onlyOwner {
    if (fee == newFee) return;
    fee = newFee;
}
```

Writing the same value still costs gas.

### Variable Packing

Put smaller variables together when it makes the code clearer.

```solidity
uint128 amount;
uint64 start;
uint64 end;
```

### unchecked

```solidity
for (uint256 i = 0; i < length; ) {
    // logic
    unchecked {
        ++i;
    }
}
```

Use `unchecked` only when overflow is impossible.

See [Arithmetic Safety: Overflow & Underflow](#19-arithmetic-safety-overflow--underflow) for the security tradeoffs, old Solidity behavior, and edge cases where wrap-around can still happen.

### Custom Errors

```solidity
error Unauthorized();

if (msg.sender != owner) revert Unauthorized();
```

Custom errors reduce deployment and revert data costs compared with long strings.

### Events vs Storage

Events are cheaper than storage but cannot be read by contracts.

Use storage for on-chain state. Use events for off-chain history and indexing.

### Loop Risks

Avoid loops over arrays that can grow without a fixed upper bound.

```solidity
function payEveryone() external {
    for (uint256 i = 0; i < recipients.length; i++) {
        // Could become too expensive and permanently fail
    }
}
```

Prefer pull-based claims or batched processing.

[Back to top](#table-of-contents)

---

## 22. Upgradeable Contracts

### In this section
- [Proxy Pattern](#proxy-pattern)
- [Transparent Proxy](#transparent-proxy)
- [UUPS](#uups)
- [Initializers Instead of Constructors](#initializers-instead-of-constructors)
- [Storage Collision Risks](#storage-collision-risks)
- [Why Upgradeability Is Dangerous](#why-upgradeability-is-dangerous)

Normal deployed contract code is immutable. Upgradeability is usually implemented with proxies.

### Proxy Pattern

A proxy stores state and delegates calls to an implementation contract.

```text
User -> Proxy -> delegatecall -> Implementation
```

The proxy's address stays the same. The implementation address can change.

### Transparent Proxy

Transparent proxies separate admin calls from user calls:

- Admin can upgrade the implementation.
- Users interact with implementation functions through the proxy.
- Admin is prevented from accidentally calling implementation functions through the proxy.

### UUPS

UUPS puts upgrade logic in the implementation contract itself. The proxy is lighter, but the implementation must protect upgrade functions carefully.

```solidity
function _authorizeUpgrade(address newImplementation) internal onlyOwner {
    // required authorization hook
}
```

### Initializers Instead of Constructors

Constructors run on the implementation contract, not through the proxy. Upgradeable contracts use initializer functions.

```solidity
bool private initialized;
address public owner;

function initialize(address initialOwner) external {
    require(!initialized, "Already initialized");
    initialized = true;
    owner = initialOwner;
}
```

Use trusted libraries such as OpenZeppelin `Initializable` in production.

### Storage Collision Risks

Because the proxy stores state, implementation storage layout must remain compatible across upgrades.

Bad upgrade:

```solidity
contract V1 {
    address owner; // slot 0
    uint256 value; // slot 1
}

contract V2 {
    uint256 value; // slot 0, corrupts owner interpretation
    address owner; // slot 1
}
```

Safe pattern:

```solidity
contract V2 {
    address owner; // slot 0
    uint256 value; // slot 1
    uint256 newValue; // slot 2
}
```

### Why Upgradeability Is Dangerous

Upgradeability adds risk:

- Admin key compromise can compromise the contract.
- Bad upgrades can corrupt storage.
- Initializer bugs can leave contracts takeoverable.
- Users must trust upgrade governance.
- Implementation selfdestruct or delegatecall issues can be catastrophic.

**When to use this**

Use upgradeability when the product genuinely needs future changes and you have strong governance, testing, monitoring, and audit discipline.

Related: upgradeability relies heavily on [delegatecall](#delegatecall) and stable [Storage Layout](#15-storage-layout).

[Back to top](#table-of-contents)

---

## 23. Signatures and Hashing

### keccak256

Ethereum commonly uses `keccak256` for hashing.

```solidity
bytes32 hash = keccak256(abi.encode(user, amount, nonce));
```

Prefer `abi.encode` over `abi.encodePacked` when hashing multiple dynamic values.

### ECDSA

Ethereum accounts use ECDSA signatures. A private key signs a message; anyone can verify that the signature corresponds to an address.

### ecrecover

`ecrecover` recovers the signer address from a hash and signature parts.

```solidity
function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    external
    pure
    returns (address)
{
    return ecrecover(hash, v, r, s);
}
```

In production, prefer audited ECDSA libraries that check malleability and message formatting.

### Signed Messages

Wallets often sign an Ethereum signed message:

```text
"\x19Ethereum Signed Message:\n32" + hash
```

This prevents a signature intended as a message from being reused directly as a transaction.

### EIP-712

EIP-712 defines structured typed data signing. It is more readable for users and safer for protocols.

EIP-712 domain usually includes:

- Name.
- Version.
- `chainId`.
- Verifying contract address.

### Replay Protection

A secure signed action should include:

- Signer address.
- Action data.
- Nonce.
- Deadline.
- `chainId`.
- Verifying contract address.

```solidity
bytes32 digest = keccak256(
    abi.encode(
        user,
        amount,
        nonce,
        block.chainid,
        address(this)
    )
);
```

**Common mistake**

Verifying a signature without marking the nonce as used. That allows replay.

---

---

## 24. Common Web3 Frontend Interactions

Modern frontends commonly use `ethers.js` or `viem` to talk to contracts.

### Mental Model

| Concept | ethers.js style | viem style | Meaning |
|---|---|---|---|
| Read-only connection | Provider | Public client | Reads blockchain data |
| User wallet | Signer | Wallet client | Signs transactions |
| Contract wrapper | Contract instance | Contract calls/actions | Encodes ABI calls |
| Read | `contract.balanceOf()` | `readContract` | Free off-chain call |
| Write | `contract.transfer(...)` | `writeContract` | Wallet transaction |

### Provider

A provider/public client connects to an RPC node.

```ts
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const block = await provider.getBlockNumber();
```

### Signer / Wallet Client

A signer can sign transactions.

```ts
const browserProvider = new ethers.BrowserProvider(window.ethereum);
const signer = await browserProvider.getSigner();
```

### Contract Instance

```ts
const contract = new ethers.Contract(address, abi, signer);
```

Connect with a provider for reads. Connect with a signer for writes.

### Read Contract

```ts
const balance = await contract.balanceOf(userAddress);
```

Reads do not ask the wallet to sign unless the library needs an account for context.

### Write Contract

```ts
const tx = await contract.transfer(to, amount);
const receipt = await tx.wait();
```

Writes require wallet approval and gas.

### Send ETH

```ts
const tx = await signer.sendTransaction({
  to: recipient,
  value: ethers.parseEther("0.1"),
});
await tx.wait();
```

### Listen to Events

```ts
contract.on("Transfer", (from, to, amount, event) => {
  console.log(from, to, amount, event.log.transactionHash);
});
```

**Common mistake**

Assuming a transaction succeeded as soon as the wallet returns a transaction hash. Wait for confirmation if your UI depends on final state.

[Back to top](#table-of-contents)

---

## 25. Testing and Debugging

### In this section
- [Hardhat Basics](#hardhat-basics)
- [Foundry Basics](#foundry-basics)
- [console.log](#consolelog)
- [Unit Tests](#unit-tests)
- [Fuzz Tests](#fuzz-tests)
- [Invariant Tests](#invariant-tests)
- [Mainnet Forking](#mainnet-forking)

### Hardhat Basics

Hardhat is a JavaScript/TypeScript Ethereum development framework.

Common tasks:

```bash
npx hardhat test
npx hardhat compile
npx hardhat node
npx hardhat ignition deploy ignition/modules/Example.ts
```

### Foundry Basics

Foundry is a fast Solidity-native toolkit.

Common tasks:

```bash
forge build
forge test
forge test -vvv
anvil
cast call
cast send
```

### console.log

Hardhat and Foundry both support Solidity logging during tests.

```solidity
import "forge-std/console.sol";

console.log("balance", balance);
```

Remove or avoid logs in production deployments.

### Unit Tests

Unit tests check specific behavior.

Test cases should cover:

- Expected success paths.
- Reverts.
- Access control.
- Events.
- State changes.
- Edge cases.

### Fuzz Tests

Fuzz tests run the same test with many generated inputs.

```solidity
function testFuzz_Deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);
    // test deposit behavior
}
```

### Invariant Tests

Invariant tests check properties that should always hold.

Examples:

- Total user balances never exceed contract assets.
- Total supply equals sum of balances.
- A vault share price never decreases unless designed to.

### Mainnet Forking

Mainnet forking runs tests against a local copy of real chain state.

Useful for:

- DeFi integrations.
- Token behavior quirks.
- Oracle integrations.
- Upgrade simulations.

**Common mistake**

Only testing happy paths. Most smart contract bugs live in edge cases and adversarial flows.

[Back to top](#table-of-contents)

---

## 26. Deployment Checklist

### Before Deploying

- Confirm compiler version and optimizer settings.
- Confirm constructor arguments.
- Confirm initializer arguments for proxies.
- Confirm network and chain ID.
- Confirm deployer address and balance.
- Confirm environment variables.
- Run full test suite.
- Run static analysis if available.
- Deploy to testnet first.

### Constructor Arguments

```solidity
constructor(address initialOwner, uint256 initialFee) {
    owner = initialOwner;
    fee = initialFee;
}
```

Make sure addresses are correct for the target network.

### Verify Contract Source Code

Verification lets users inspect source code on block explorers.

Common requirements:

- Exact source code.
- Compiler version.
- Optimizer settings.
- Constructor arguments.
- Libraries.

### Environment Variables

Keep secrets out of source code.

```text
RPC_URL=...
PRIVATE_KEY=...
ETHERSCAN_API_KEY=...
```

### Private Key Safety

Warning:

- Never commit private keys.
- Never paste production private keys into random scripts.
- Prefer hardware wallets or multisigs for admin actions.
- Use separate keys for testnets and mainnet.

### Network Config

Check:

- RPC URL.
- Chain ID.
- Explorer URL.
- Gas settings.
- Deployed dependency addresses.

### Testnet Before Mainnet

Deploy and interact with the contract on a testnet or local fork before mainnet.

Recommended final checks:

- Can users perform expected actions?
- Do events appear correctly?
- Can the frontend read and write?
- Are ownership and roles correct?
- Are funds withdrawable by the intended account?
- Is source verified?

[Back to top](#table-of-contents)

---

## 27. Common Interview Questions

### storage vs memory vs calldata

`storage` is persistent on-chain state. `memory` is temporary mutable data for one function execution. `calldata` is temporary read-only input data, usually cheapest for external parameters.

### call vs delegatecall

`call` executes code in the target contract's context. `delegatecall` executes target code in the caller's context, preserving `msg.sender` and writing to the caller's storage.

### receive vs fallback

`receive()` handles plain ETH transfers with empty calldata. `fallback()` handles unknown function calls and can receive ETH if payable.

### ERC20 approve/transferFrom flow

The token owner calls `approve(spender, amount)`. The spender later calls `transferFrom(owner, recipient, amount)`. The token contract checks allowance and balance, transfers tokens, and decreases allowance.

### Reentrancy

Reentrancy occurs when an external call allows a contract to call back before state updates are complete. Mitigate with Checks-Effects-Interactions and `nonReentrant`.

### ABI/function selector

The function selector is the first 4 bytes of `keccak256` of the canonical function signature, such as `transfer(address,uint256)`.

### Proxy storage collision

Proxy contracts use `delegatecall`, so implementation code writes to proxy storage. If a new implementation changes variable order, old storage slots can be misinterpreted and corrupted.

### msg.sender vs tx.origin

`msg.sender` is the immediate caller. `tx.origin` is the original EOA that started the transaction. Use `msg.sender` for authorization; using `tx.origin` can enable phishing-style attacks through malicious intermediary contracts.

[Back to top](#table-of-contents)

---

## Final Study Tips

- Solidity is about managing state, permissions, gas, and external calls safely.
- Most serious bugs come from wrong assumptions about trust boundaries.
- Prefer simple designs, audited libraries, explicit access control, and strong tests.
- When in doubt, ask: who can call this, what state changes, what external calls happen, and what can be reentered?

[Back to top](#table-of-contents)
