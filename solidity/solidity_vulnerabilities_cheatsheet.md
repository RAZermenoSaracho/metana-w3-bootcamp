# Solidity Security Cheat Sheet for Real Smart Contract Development

> A practical vulnerability manual for Solidity developers, auditors, and students learning how smart contracts break in production.

---

## How to Use This Cheatsheet

- Use it while writing Solidity, reviewing pull requests, preparing audits, or studying exploit patterns.
- Read each vulnerability in this order: what it is, why it happens, how the attack works, how to fix it.
- Copy the patterns, not the toy contracts. The examples are intentionally small so the bug is easy to see.
- Treat every external call, upgrade, oracle dependency, and authorization check as security-sensitive.

Warning: This document is for education and defensive engineering. Do not test attack code against contracts you do not own or have permission to assess.

---

## Table of Contents

### Core Vulnerabilities
- [1. Reentrancy](#1-reentrancy)
- [2. Transient Storage](#2-transient-storage)
- [3. Arithmetic Overflow and Underflow](#3-arithmetic-overflow-and-underflow)
- [4. Phishing with tx.origin](#4-phishing-with-txorigin)
- [5. Unsafe Delegatecall](#5-unsafe-delegatecall)
- [6. Insecure Source of Randomness](#6-insecure-source-of-randomness)
- [7. Front Running](#7-front-running)

### Security Practice
- [Common Security Principles](#common-security-principles)
- [Smart Contract Security Mindset](#smart-contract-security-mindset)
- [Recommended Tools](#recommended-tools)
- [Final Audit Checklist](#final-audit-checklist)

---

## 1. Reentrancy

Reentrancy happens when a contract makes an external call before it has finished updating its own state, and the external contract calls back into the original contract.

### What It Is

In Solidity, an external call transfers control to another contract:

```solidity
(bool ok,) = msg.sender.call{value: amount}("");
```

If `msg.sender` is a contract, its `receive()` or `fallback()` function can run. That code can call your contract again before the first call finishes.

### Why It Happens

The EVM is synchronous:

1. User calls `Vault.withdraw()`.
2. `Vault` sends ETH to `msg.sender`.
3. If `msg.sender` is a contract, its code executes immediately.
4. The receiver contract can call `Vault.withdraw()` again.
5. If `Vault` has not updated balances yet, the second call sees stale state.

Dangerous pattern:

```solidity
external call first
state update second
```

Safer pattern:

```solidity
checks first
state update second
external call last
```

### Real-World Impact

Reentrancy can drain:

- ETH vaults.
- ERC20 staking pools.
- NFT marketplaces.
- Lending protocols.
- Reward distributors.
- Bridges and escrow contracts.

The core issue is not "ETH transfer is bad." The issue is giving another contract control before your accounting is complete.

### Vulnerable Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send failed");

        balances[msg.sender] = 0;
    }
}
```

Bug: `balances[msg.sender] = 0` happens after the external call.

### Attacker Contract Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

contract ReentrancyAttacker {
    IVault public vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}
```

### Attack Flow

1. Attacker deposits `1 ether`.
2. Attacker calls `withdraw()`.
3. Vault reads attacker balance: `1 ether`.
4. Vault sends `1 ether` to attacker contract.
5. Attacker `receive()` runs.
6. Attacker calls `withdraw()` again before balance is set to zero.
7. Vault still sees `1 ether`.
8. Loop repeats until vault is drained or the attack stops.

### Secure Mitigation

Use Checks-Effects-Interactions:

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "no balance");

    balances[msg.sender] = 0;

    (bool ok,) = msg.sender.call{value: amount}("");
    require(ok, "send failed");
}
```

Use `ReentrancyGuard` for extra protection:

```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SafeVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        balances[msg.sender] = 0;

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }
}
```

Use pull over push payments:

- Push payment: contract sends money to users automatically.
- Pull payment: users claim their own money.

Pull payments reduce risk because each user withdrawal is isolated and can be protected.

### Cross-Function Reentrancy

Reentrancy does not always call the same function again.

Example pattern:

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];
    sendEth(msg.sender, amount); // external call
    balances[msg.sender] = 0;
}

function transferBalance(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount, "too much");
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

An attacker may reenter through `transferBalance()` while `withdraw()` still has stale accounting.

Practical rule: protect the entire accounting system, not only one function.

### Read-Only Reentrancy

Read-only reentrancy happens when an external call observes temporary inconsistent state during another function.

Simple idea:

- Function updates part of the state.
- Function makes an external call.
- External contract calls a `view` function.
- The `view` function returns a price, balance, or share value based on incomplete state.
- Another protocol trusts that read.

This is especially dangerous when other contracts read your protocol during callbacks.

### Common Misconceptions

- "Using `transfer` prevents reentrancy." Not reliable. Gas costs changed before and can change again. Prefer explicit patterns.
- "Only ETH transfers cause reentrancy." ERC721, ERC1155, ERC777, hooks, and arbitrary external calls can reenter.
- "`nonReentrant` fixes everything." It helps, but bad accounting, cross-function flows, and external reads still need design review.
- "View functions are always safe." View functions can expose inconsistent state to other protocols.

### Audit Checklist

- Are state updates done before external calls?
- Are all ETH, token, NFT, and hook calls reviewed as external control transfers?
- Can the receiver call back into the same function?
- Can the receiver call another function that touches shared state?
- Is `nonReentrant` used where useful?
- Are multiple `nonReentrant` functions calling each other internally?
- Are view functions safe during partially completed state transitions?
- Are withdrawals pull-based instead of push-based?
- Are failed sends handled safely?

### Mental Model / Intuition

Every external call is handing the microphone to someone else before your function finishes. If your internal accounting is not already correct, assume they will use that opening.

[Back to top](#table-of-contents)

---

## 2. Transient Storage

Transient storage is temporary contract storage that persists during one transaction and is cleared at the end of the transaction.

### What It Is

EIP-1153 introduced two EVM opcodes:

- `TSTORE`: write transient storage.
- `TLOAD`: read transient storage.

Transient storage behaves like transaction-scoped storage:

- It is available across calls during the same transaction.
- It is cleared after the transaction finishes.
- It is cheaper than normal persistent storage for temporary values.

### Storage vs Memory vs Calldata vs Transient Storage

| Location | Lifetime | Mutable? | Typical use |
|---|---:|---:|---|
| `storage` | Permanent blockchain state | Yes | balances, owners, config |
| `memory` | One function execution | Yes | temporary arrays, structs, calculations |
| `calldata` | One external call | No | function inputs |
| transient storage | One transaction | Yes | locks, temporary accounting, flash loan state |

### Why It Happens / Why It Exists

Many contracts need temporary state:

- Reentrancy lock active only during one transaction.
- Flash loan amount active only during one callback.
- Temporary accounting while several contracts interact.

Before transient storage, contracts often used normal storage for these values. That works, but it costs more gas because persistent storage is designed for long-term state.

### Real-World Impact

Transient storage can reduce gas and make temporary state explicit. It can also create new bugs if developers assume it behaves like memory or permanent storage.

Important behavior:

- It is not permanent.
- It is shared across calls to the same contract during the same transaction.
- In `delegatecall`, transient storage follows the caller context, similar to normal storage.

### Simple Transient Storage Example

Solidity support may vary by compiler version, so inline assembly is the most explicit way to show the EVM behavior.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TransientLock {
    bytes32 private constant LOCK_SLOT = keccak256("example.lock");

    modifier nonReentrantT() {
        bytes32 slot = LOCK_SLOT;

        assembly {
            if tload(slot) { revert(0, 0) }
            tstore(slot, 1)
        }

        _;

        assembly {
            tstore(slot, 0)
        }
    }

    function doWork() external nonReentrantT {
        // protected logic
    }
}
```

### Comparison With Normal Storage Lock

Normal persistent storage lock:

```solidity
contract StorageLock {
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "locked");
        locked = true;
        _;
        locked = false;
    }
}
```

Transient lock:

```solidity
modifier nonReentrantT() {
    uint256 slot = 0;

    assembly {
        if tload(slot) { revert(0, 0) }
        tstore(slot, 1)
    }

    _;

    assembly {
        tstore(slot, 0)
    }
}
```

Storage lock persists in contract storage. Transient lock exists only for the transaction.

### Vulnerable / Misuse Example

This example uses transient storage for data that must survive after the transaction:

```solidity
contract BadTransientBalance {
    function credit(address user, uint256 amount) external {
        bytes32 slot = keccak256(abi.encode(user, "balance"));

        assembly {
            tstore(slot, amount)
        }
    }

    function balanceOf(address user) external view returns (uint256 amount) {
        bytes32 slot = keccak256(abi.encode(user, "balance"));

        assembly {
            amount := tload(slot)
        }
    }
}
```

Bug: the "balance" disappears at the end of the transaction. User balances belong in normal storage, not transient storage.

### Attack Flow / Risk Flow

Transient storage is usually a mitigation tool, but it can be misused:

1. Contract writes a value using `tstore`.
2. Developer assumes it behaves like normal storage or like function-local memory.
3. Another function in the same transaction reads the value, or a later transaction expects it to still exist.
4. Logic changes unexpectedly because temporary state leaked across calls or disappeared after the transaction.
5. The bug is hard to debug because the state is intentionally not persistent.

### Secure Mitigation

Use transient storage only for values that truly should live for one transaction.

Good use cases:

- Reentrancy locks.
- Flash loan callback validation.
- Temporary net accounting inside one transaction.
- Preventing repeated use of a function in the same transaction.

Avoid using it for:

- User balances.
- Ownership.
- Long-term approvals.
- Protocol configuration.
- Values a frontend or later transaction needs to read.

### Common Mistakes

- Treating transient storage like memory. It can survive across external calls in the same transaction.
- Treating transient storage like normal storage. It is gone after the transaction.
- Using simple slots like `0` in complex contracts without thinking about collisions.
- Forgetting delegatecall context.
- Using transient storage for data that must be auditable later.

### Audit Checklist

- Is transient state cleared or intentionally left to auto-clear at transaction end?
- Can another function read transient values unexpectedly?
- Are slot constants unique and documented?
- Does any delegatecall path share the same transient storage context?
- Is the code deployed on chains that support EIP-1153?
- Is persistent state accidentally stored in transient storage?
- Are tests covering multi-call transaction flows?

### Mental Model / Intuition

Transient storage is a sticky note attached to the current transaction. It is more durable than memory during the transaction, but it is thrown away when the transaction ends.

[Back to top](#table-of-contents)

---

## 3. Arithmetic Overflow and Underflow

Overflow and underflow happen when integer math goes outside the range of the type.

### What It Is

For `uint256`:

- Minimum value: `0`.
- Maximum value: `2^256 - 1`.

Overflow:

```text
max uint256 + 1
```

Underflow:

```text
0 - 1
```

### Why It Happens

The EVM works with fixed-size integers. Before Solidity `0.8.0`, arithmetic wrapped by default.

Pre-0.8 behavior:

```text
uint256(0) - 1 = 2^256 - 1
```

Solidity `0.8+` adds automatic overflow and underflow checks. If checked arithmetic overflows, the transaction reverts.

### Real-World Impact

Math bugs can break:

- Token balances.
- Lending collateral calculations.
- Interest accrual.
- Reward distribution.
- AMM pricing.
- Liquidation thresholds.
- Share minting and redemption.

In DeFi, a small math error can create free money, block withdrawals, or make a protocol insolvent.

### Vulnerable Pre-0.8 Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract OldToken {
    mapping(address => uint256) public balanceOf;

    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] - amount >= 0, "too much");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}
```

Bug: in Solidity 0.7, `balanceOf[msg.sender] - amount` can underflow before the check has useful meaning.

### Solidity 0.8 Revert Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CheckedMath {
    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b; // reverts if b > a
    }
}
```

In Solidity `0.8+`, this reverts automatically if `b > a`.

### Unchecked Example

`unchecked` disables automatic arithmetic checks inside the block.

```solidity
function increment(uint256 i) external pure returns (uint256) {
    unchecked {
        return i + 1;
    }
}
```

Use `unchecked` only when you can prove overflow or underflow is impossible.

### Attack Flow

Classic underflow-style attack:

1. Contract subtracts user amount without a correct balance check.
2. Attacker transfers more than their balance.
3. Balance underflows to a huge number.
4. Attacker now appears to own a massive balance.
5. Attacker drains tokens or protocol assets.

Modern Solidity prevents many simple cases, but logic math bugs still exist.

### Precision and Rounding Issues

Solidity has no floating-point numbers.

Bad:

```solidity
uint256 fee = amount * 25 / 10_000;
```

This is okay for basis points, but small values may round to zero.

Dangerous order:

```solidity
uint256 result = amount / totalShares * totalAssets;
```

If `amount < totalShares`, `amount / totalShares` becomes zero.

Better:

```solidity
uint256 result = amount * totalAssets / totalShares;
```

Multiplication before division usually preserves precision, but check overflow and use a trusted `mulDiv` helper for high-value math.

### Fixed Point Math Basics

Common scale factors:

- `1e18` for WAD math.
- `1e27` for RAY math.
- basis points: `10_000 = 100%`.

Example:

```solidity
uint256 interest = principal * ratePerYear / 1e18;
```

### Secure Mitigation

Use Solidity `0.8+` checked arithmetic by default.

```solidity
function transfer(address to, uint256 amount) external {
    uint256 balance = balanceOf[msg.sender];
    require(balance >= amount, "too much");

    balanceOf[msg.sender] = balance - amount;
    balanceOf[to] += amount;
}
```

Safe math patterns:

- Check denominators are not zero.
- Multiply before dividing when preserving precision.
- Use `mulDiv` for full-precision multiplication and division.
- Define rounding direction intentionally.
- Avoid `unchecked` unless the invariant is obvious and tested.

### Common Mistakes

- Assuming Solidity `0.8+` fixes all math bugs.
- Using `unchecked` for gas without a proof.
- Dividing before multiplying.
- Ignoring token decimals.
- Rounding in favor of the wrong party.
- Forgetting denominator zero checks.
- Mixing `1e18`, basis points, and token decimals incorrectly.

### Audit Checklist

- Is the compiler version `0.8+`?
- Are there any `unchecked` blocks?
- Can `unchecked` overflow under fuzzing?
- Are divisions protected from zero denominators?
- Is precision lost by dividing too early?
- Is rounding direction intentional and documented?
- Are token decimals handled correctly?
- Are share/accounting invariants tested?

### Mental Model / Intuition

Solidity integers are exact but not magical. They do not know what dollars, shares, interest, or percentages mean. Your code must define safe ranges, scaling, and rounding.

[Back to top](#table-of-contents)

---

## 4. Phishing with tx.origin

`tx.origin` is the original externally owned account that started the transaction. It should almost never be used for authorization.

### What It Is

Difference:

| Value | Meaning |
|---|---|
| `msg.sender` | Immediate caller of the current function |
| `tx.origin` | Original EOA that started the whole transaction |

Call chain:

```text
Alice EOA -> MaliciousContract -> VictimWallet
```

Inside `VictimWallet`:

```text
msg.sender = MaliciousContract
tx.origin  = Alice EOA
```

### Why It Happens

Beginners sometimes think `tx.origin` means "the real user." Attackers exploit that by tricking the real user into calling a malicious contract.

If a victim contract checks `tx.origin == owner`, the malicious intermediary still passes the check because the owner started the transaction.

### Real-World Impact

`tx.origin` authorization can allow phishing attacks that drain:

- Wallet contracts.
- Admin-controlled vaults.
- Token approvals.
- Ownership-protected actions.

The user may think they are claiming an airdrop or minting an NFT, but the malicious contract uses the call to access another contract.

### Vulnerable Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TxOriginWallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function withdrawAll(address payable to) external {
        require(tx.origin == owner, "not owner");
        to.transfer(address(this).balance);
    }
}
```

Bug: authorization uses `tx.origin`.

### Attacker Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IWallet {
    function withdrawAll(address payable to) external;
}

contract PhishingAttack {
    address payable public attacker;
    IWallet public wallet;

    constructor(address _wallet) {
        attacker = payable(msg.sender);
        wallet = IWallet(_wallet);
    }

    function claimAirdrop() external {
        wallet.withdrawAll(attacker);
    }
}
```

### Attack Flow

1. Alice owns `TxOriginWallet`.
2. Attacker deploys `PhishingAttack`.
3. Attacker convinces Alice to call `claimAirdrop()`.
4. `PhishingAttack` calls `wallet.withdrawAll(attacker)`.
5. In the wallet, `tx.origin == Alice`.
6. The authorization passes.
7. Wallet sends funds to attacker.

### Secure Version

Use `msg.sender` for authorization:

```solidity
contract SafeWallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function withdrawAll(address payable to) external {
        require(msg.sender == owner, "not owner");
        to.transfer(address(this).balance);
    }
}
```

Now the malicious contract fails because:

```text
msg.sender = PhishingAttack
owner      = Alice
```

### Historical Context

`tx.origin` exists because the EVM tracks the original transaction signer. It is occasionally useful for analytics or very narrow compatibility checks, but it is unsafe for authorization.

### Common Mistakes

- Using `tx.origin` to block contracts.
- Using `tx.origin` to identify the real user.
- Mixing `tx.origin` and `msg.sender` in access control.
- Believing "the owner still signed the transaction, so it is safe."
- Forgetting that wallets, multisigs, account abstraction, and relayers may be contracts.

### Audit Checklist

- Is `tx.origin` used anywhere?
- Is it used in `require`, modifiers, ownership checks, or permissions?
- Would a malicious intermediary contract pass the check?
- Does the design support multisigs and smart wallets?
- Can `msg.sender` be used instead?
- Are signatures or explicit approvals better for the workflow?

### Mental Model / Intuition

`tx.origin` tells you who started the journey. `msg.sender` tells you who is standing at your door right now. Authorization should care who is at the door.

[Back to top](#table-of-contents)

---

## 5. Unsafe Delegatecall

`delegatecall` executes code from another contract while using the caller's storage, balance, and address context.

### What It Is

Normal `call`:

```text
Contract A calls Contract B
Code runs in B
Storage writes affect B
address(this) is B
```

`delegatecall`:

```text
Contract A delegatecalls Contract B
Code from B runs in A
Storage writes affect A
address(this) is A
msg.sender is preserved
```

### Why It Happens

`delegatecall` is used for:

- Upgradeable proxies.
- Shared library logic.
- Modular contract systems.

It is powerful because it separates storage from logic. It is dangerous because untrusted or incompatible logic can overwrite the caller's storage.

### Real-World Impact

Unsafe delegatecall can cause:

- Ownership takeover.
- Storage corruption.
- Asset theft.
- Broken upgrades.
- Proxy bricking.
- Unexpected selfdestruct behavior in older patterns.

### Minimal Delegatecall Example

```solidity
contract Caller {
    uint256 public value;

    function run(address target, bytes calldata data) external {
        (bool ok,) = target.delegatecall(data);
        require(ok, "delegatecall failed");
    }
}

contract Logic {
    uint256 public value;

    function setValue(uint256 x) external {
        value = x;
    }
}
```

Calling `Caller.run(logic, abi.encodeCall(Logic.setValue, (123)))` writes `123` into `Caller.value`, not `Logic.value`.

### Storage Collision Example

```solidity
contract ProxyStorage {
    address public owner; // slot 0
}

contract BadLogic {
    uint256 public count; // slot 0

    function setCount(uint256 x) external {
        count = x;
    }
}
```

If the proxy delegatecalls `BadLogic.setCount`, slot `0` is overwritten. That means `owner` can be corrupted.

### Unsafe Proxy Example

```solidity
contract UnsafeProxy {
    address public implementation;
    address public owner;

    function upgradeTo(address newImplementation) external {
        implementation = newImplementation; // no access control
    }

    fallback() external payable {
        (bool ok,) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}
```

Bugs:

- Anyone can upgrade implementation.
- Implementation can write proxy storage.
- Storage layout is not protected.
- No event, no delay, no admin model.

### Attack Flow

1. Attacker deploys malicious implementation.
2. Attacker calls `upgradeTo(maliciousImplementation)`.
3. Proxy now delegates all calls to attacker code.
4. Attacker calls a function that writes proxy storage or transfers funds.
5. Proxy assets are stolen or ownership is changed.

### Secure Mitigation

Use audited proxy patterns:

- OpenZeppelin Transparent Proxy.
- UUPS with `_authorizeUpgrade`.
- Beacon proxy where appropriate.

Minimal safer upgrade guard:

```solidity
function upgradeTo(address newImplementation) external onlyOwner {
    require(newImplementation.code.length > 0, "not contract");
    implementation = newImplementation;
    emit Upgraded(newImplementation);
}
```

Safer patterns:

- Strict access control for upgrades.
- Timelocks for major upgrades.
- Storage gaps for upgradeable contracts.
- Do not reorder state variables.
- Avoid arbitrary user-controlled delegatecall.
- Use implementation initialization carefully.
- Disable initializers on implementation contracts.

### Selfdestruct Risks

Historically, delegatecalling code that executed `selfdestruct` could destroy the calling contract. Network upgrades changed some `selfdestruct` behavior, but the safe rule remains:

Do not delegatecall untrusted code, and do not rely on dangerous opcodes behaving harmlessly across chains or upgrades.

### Common Mistakes

- Allowing users to choose the delegatecall target.
- Assuming storage variable names matter; storage slots matter.
- Reordering variables in upgraded implementations.
- Forgetting initializer access control.
- Leaving implementation contracts uninitialized.
- Using `delegatecall` when a normal `call` is enough.
- Not checking `success` from low-level calls.

### Audit Checklist

- Is every delegatecall target trusted?
- Can users influence target or calldata?
- Is upgrade authorization strict?
- Is storage layout compatible across versions?
- Are implementation contracts initialized or locked?
- Are upgrade events emitted?
- Is there a timelock or multisig for upgrades?
- Can delegatecalled code transfer assets or change ownership?
- Are fallback functions simple and well tested?

### Mental Model / Intuition

`delegatecall` is letting another contract drive your body. It uses your storage, your address, and your funds. Only delegate to code you would trust as your own contract.

[Back to top](#table-of-contents)

---

## 6. Insecure Source of Randomness

On-chain randomness is hard because blockchains are deterministic. Every node must compute the same result from the same inputs.

### What It Is

Bad randomness usually comes from predictable or manipulable values:

- `block.timestamp`
- `blockhash`
- `block.prevrandao`
- `msg.sender`
- `tx.origin`
- `gasleft()`
- contract balances

These values are public, partly controllable, or both.

### Why It Happens

Developers want a random number, but Solidity has no secure built-in randomness.

This is insecure:

```solidity
uint256 random = uint256(
    keccak256(abi.encodePacked(block.timestamp, msg.sender))
);
```

Anyone can inspect the formula. Some participants can influence the inputs.

### Real-World Impact

Bad randomness can break:

- Lotteries.
- NFT mint reveals.
- Games.
- Raffles.
- Validator selection.
- Loot boxes.
- Random reward distribution.

If the prize is valuable, someone will try to predict or manipulate the outcome.

### Insecure Lottery Example

```solidity
contract BadLottery {
    address[] public players;

    function enter() external payable {
        require(msg.value == 1 ether, "price");
        players.push(msg.sender);
    }

    function pickWinner() external {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))
        );

        address winner = players[random % players.length];
        payable(winner).transfer(address(this).balance);
    }
}
```

Problems:

- Timestamp can be slightly influenced.
- `block.prevrandao` is not enough by itself for high-value app randomness.
- The winner can be simulated before the transaction is included.
- Searchers may only submit transactions when the result benefits them.
- Validators and builders may have limited influence over block contents, ordering, and whether a borderline transaction is included.

### Manipulated Randomness Example

```solidity
function mintLucky() external payable {
    uint256 lucky = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
    if (lucky == 7) {
        _mint(msg.sender, rareTokenId);
    }
}
```

An attacker can:

1. Try from many addresses.
2. Simulate outcomes.
3. Send only transactions that win.
4. Use private ordering or bundles to improve execution.

### Attack Flow

1. Contract computes "randomness" from public inputs.
2. Attacker reads the formula.
3. Attacker simulates likely outcomes off-chain.
4. Attacker submits only favorable transactions.
5. If validators/searchers can influence inclusion or ordering, they get more advantage.
6. Honest users receive worse odds than expected.

### Secure Mitigation

Use commit-reveal for simple lower-value cases:

```solidity
contract CommitReveal {
    mapping(address => bytes32) public commits;

    function commit(bytes32 hash) external {
        commits[msg.sender] = hash;
    }

    function reveal(uint256 secret) external view returns (uint256) {
        require(commits[msg.sender] == keccak256(abi.encode(secret)), "bad reveal");
        return uint256(keccak256(abi.encode(secret, msg.sender)));
    }
}
```

Commit-reveal basics:

1. User commits a hash of a secret.
2. User reveals the secret later.
3. Contract verifies the reveal matches the commitment.
4. Randomness uses the secret after it can no longer be changed.

Commit-reveal still needs:

- Commit deadline.
- Reveal deadline.
- Penalty for not revealing.
- Rules for missing reveals.
- Protection against last-revealer advantage.

Use Chainlink VRF or another verified randomness system for high-value randomness.

VRF high-level idea:

- Contract requests randomness.
- Oracle network returns a random value plus cryptographic proof.
- Contract verifies or trusts the VRF coordinator flow.
- Randomness arrives asynchronously in a callback.

### Randomness Tradeoffs

| Approach | Pros | Cons |
|---|---|---|
| Block values | Simple | Predictable/manipulable |
| Commit-reveal | No oracle needed | Multi-step, liveness issues |
| VRF | Stronger randomness | Oracle dependency, async callback, cost |
| Trusted admin | Simple operations | Trust assumption |

### Common Mistakes

- Using `block.timestamp` for lottery winners.
- Thinking hashing predictable values makes them random.
- Forgetting users can simulate public formulas.
- Ignoring validators, searchers, and transaction ordering.
- Building high-value games with weak randomness.
- Not handling VRF callback failures or timing assumptions.

### Audit Checklist

- Is randomness used to distribute value?
- Are inputs public before the outcome matters?
- Can users choose inputs after seeing other inputs?
- Can validators/searchers influence outcome or ordering?
- Is commit-reveal protected against non-reveal griefing?
- Is VRF callback access restricted?
- Is the protocol safe if randomness arrives late?
- Are edge cases tested when no one reveals?

### Mental Model / Intuition

If everyone can know or influence the ingredients before the result is final, it is not secure randomness. Hashing predictable data makes it look random, not become random.

[Back to top](#table-of-contents)

---

## 7. Front Running

Front running happens when someone sees a pending transaction and submits another transaction designed to execute before it.

### What It Is

Public mempools expose pending transactions before they are included in a block.

Searchers can see:

- Function called.
- Contract address.
- Calldata.
- Token amounts.
- Slippage settings.
- Deadlines.
- Gas fee.

They can then submit competing transactions with higher priority fees or use private bundles.

### Why It Happens

Blockchains separate transaction submission from transaction inclusion.

Between those two moments:

1. Transaction is visible.
2. Other actors can analyze it.
3. Validators/builders choose ordering.
4. MEV searchers compete for profit.

MEV means Maximal Extractable Value: value that can be extracted by ordering, inserting, or censoring transactions.

### Real-World Impact

Front running affects:

- DEX swaps.
- NFT mints.
- Liquidations.
- Oracle updates.
- Governance actions.
- Token launches.
- Name registrations.

### Step-by-Step Sandwich Attack

Scenario: Alice swaps a large amount of Token A for Token B on an AMM.

1. Alice submits swap with high slippage tolerance.
2. Searcher sees Alice's pending transaction in the mempool.
3. Searcher buys Token B before Alice, moving price up.
4. Alice's swap executes at a worse price but still within slippage.
5. Searcher sells Token B after Alice, capturing profit.
6. Alice receives fewer tokens.

Transaction order:

```text
1. Searcher buy
2. Alice swap
3. Searcher sell
```

### Vulnerable Swap Example

```solidity
interface IRouter {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract BadSwap {
    IRouter public router;

    function buy(address[] calldata path) external payable {
        router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }
}
```

Problems:

- `amountOutMin = 0` accepts any price.
- `deadline = block.timestamp` is not useful user protection.
- User cannot control slippage.

### Attack Flow

1. User calls `buy()` with valuable input.
2. Searcher sees `amountOutMin = 0`.
3. Searcher moves pool price against user.
4. User transaction still succeeds because any output is accepted.
5. Searcher reverses the trade for profit.

### Secure Mitigation

Require user-defined slippage and deadline:

```solidity
contract SaferSwap {
    IRouter public router;

    function buy(
        address[] calldata path,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable {
        require(deadline >= block.timestamp, "expired");
        require(amountOutMin > 0, "bad min out");

        router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            msg.sender,
            deadline
        );
    }
}
```

Other mitigations:

- Commit-reveal for secret bids or mints.
- Batch auctions to reduce ordering advantage.
- Slippage protection.
- Deadlines.
- TWAP or robust oracle checks.
- Private mempools or bundles for sensitive transactions.
- Per-wallet mint limits or allowlists where appropriate.

Private mempools and bundles:

- Private transaction routes can hide calldata from the public mempool before inclusion.
- Bundles can request specific transaction ordering.
- They reduce some front-running risk, but they introduce trust assumptions around relays, builders, and inclusion.
- They are useful protection tools, not a replacement for slippage checks and sound protocol design.

### NFT Mint Front Running

If a mint reveals token IDs or rare traits before finalization, searchers may copy or reorder transactions to capture rare mints.

Mitigations:

- Commit-reveal minting.
- Delayed reveal.
- VRF for assignment.
- Avoid exposing rare outcome before purchase finality.

### Oracle Update Front Running

If a protocol uses an oracle update transaction, searchers may transact before or after the update to exploit stale or fresh prices.

Mitigations:

- Use robust oracle design.
- Validate price freshness.
- Add circuit breakers.
- Use TWAPs for sensitive calculations.
- Avoid single-block price dependency.

### Liquidation Races

Liquidations are naturally competitive. Bots monitor positions and race to liquidate.

Risks:

- Gas wars.
- Failed transactions.
- MEV extraction.
- Bad liquidation incentives.

Mitigations:

- Clear incentive design.
- Reliable oracle updates.
- Health factor checks at execution time.
- Reasonable close factors and bonuses.

### Practical User Protection Tips

- Set tight but realistic slippage.
- Use deadlines.
- Avoid trading large size through thin liquidity.
- Split large orders carefully.
- Use aggregators that support MEV protection.
- Consider private transaction routes for sensitive trades.
- Simulate before signing when possible.

### Common Mistakes

- Setting `amountOutMin` to zero.
- Using public mempool for sensitive bids.
- Assuming transaction order is fair.
- Revealing secret information in calldata too early.
- Depending on a single spot price.
- Not checking deadlines.
- Designing mints or auctions where first visible transaction wins too much value.

### Audit Checklist

- Can a pending transaction be profitably copied?
- Can a searcher insert before and after it?
- Are slippage and deadline parameters required?
- Are secrets revealed in calldata?
- Can oracle update timing be exploited?
- Are liquidation incentives balanced?
- Are user-supplied min/max bounds enforced?
- Does the protocol rely on fair ordering?

### Mental Model / Intuition

The mempool is public. If your transaction contains profitable information, assume professional searchers see it before it lands.

[Back to top](#table-of-contents)

---

## Common Security Principles

These principles show up across almost every Solidity vulnerability.

### Checks-Effects-Interactions

Order functions like this:

1. Checks: validate permissions and inputs.
2. Effects: update internal state.
3. Interactions: call external contracts last.

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "no balance");

    balances[msg.sender] = 0;

    (bool ok,) = msg.sender.call{value: amount}("");
    require(ok, "send failed");
}
```

### Least Privilege

Give each role only the power it needs.

Examples:

- Pauser can pause but not upgrade.
- Upgrader can upgrade but not withdraw funds.
- Keeper can trigger maintenance but not change config.
- Treasury can receive fees but not change protocol logic.

### Fail Safely

When something unexpected happens, the protocol should move into a safer state.

Examples:

- Revert on stale oracle data.
- Pause risky actions when invariant checks fail.
- Reject unknown callback senders.
- Use circuit breakers for extreme price movement.

### Minimize Trust Assumptions

Write down what must be trusted:

- Owner.
- Multisig.
- Oracle.
- Bridge.
- Upgrade admin.
- Keeper.
- External protocol.

Then ask: what happens if that actor is delayed, wrong, compromised, or malicious?

### Pull vs Push Payments

Prefer users claiming funds instead of pushing funds to many users.

Benefits:

- Isolates failures.
- Reduces reentrancy surface.
- Avoids gas griefing loops.
- Makes accounting easier.

### Input Validation

Validate:

- Nonzero addresses.
- Nonzero amounts.
- Deadline not expired.
- Array lengths match.
- Token is allowed.
- Slippage bounds are reasonable.
- Caller has permission.

### Invariant Thinking

An invariant is something that should always be true.

Examples:

- Total user shares should equal total shares.
- Contract assets should cover user liabilities.
- A user cannot withdraw more than their balance.
- A paused protocol cannot accept new deposits.
- A loan cannot be healthy and liquidatable at the same time.

### Minimize External Calls

External calls are risky because:

- They transfer control.
- They can reenter.
- They can revert.
- They can consume gas.
- They can return malicious data.
- They may depend on upgradeable or untrusted code.

### Upgradeability Caution

Upgradeable contracts add operational risk.

Use:

- Timelocks.
- Multisigs.
- Storage layout checks.
- Upgrade tests.
- Initialization protection.
- Clear upgrade events.
- Emergency rollback plans.

### Defense in Depth

Do not rely on one control.

Example for withdrawals:

- Checks-Effects-Interactions.
- `nonReentrant`.
- Pull payments.
- Balance invariant tests.
- Emergency pause.
- Access-controlled rescue functions.

[Back to top](#table-of-contents)

---

## Smart Contract Security Mindset

Security is not just a list of bugs. It is a way of thinking about adversarial systems.

### Assume Users Are Adversarial

Users can:

- Call functions in any order.
- Use contracts instead of EOAs.
- Reenter during callbacks.
- Submit transactions through private routes.
- Race other users.
- Use flash loans.
- Manipulate low-liquidity markets.
- Exploit bad assumptions in edge cases.

### Test Malicious Flows

Do not only test the happy path.

Test:

- Unauthorized callers.
- Repeated calls.
- Zero values.
- Maximum values.
- Expired deadlines.
- Reentrant receivers.
- Malicious token behavior.
- Failed external calls.
- Oracle stale data.

### Fuzz Testing Importance

Fuzzing tries many generated inputs.

Use it for:

- Amounts.
- Shares.
- Rates.
- Deadlines.
- Array lengths.
- User addresses.
- Rounding boundaries.

Good fuzz tests assert properties:

```solidity
assertLe(userWithdrawable, totalAssets);
assertEq(totalShares, sumUserShares);
```

### Invariant Testing Importance

Invariant tests run many actions and verify system-wide truths still hold.

Useful for:

- Vaults.
- AMMs.
- Lending protocols.
- Staking systems.
- Bridges.
- Reward accounting.

Example invariant:

```text
Protocol assets >= user liabilities
```

### Mainnet Fork Testing

Fork tests help with:

- Real token behavior.
- Real protocol integrations.
- Oracle addresses.
- Decimal handling.
- Upgrade scripts.
- Migration scripts.

Use fixed fork blocks for reproducibility.

### Most Exploits Are Logic Bugs

Modern Solidity prevents many low-level bugs, but protocols still fail because:

- Accounting is wrong.
- Permissions are wrong.
- External integrations behave differently than expected.
- Oracle assumptions are weak.
- Upgrade paths are unsafe.
- Edge cases are not tested.

### Simplicity Matters

Complex systems are harder to audit.

Prefer:

- Smaller functions.
- Explicit state transitions.
- Fewer roles.
- Fewer external calls.
- Clear invariants.
- Boring trusted libraries.

### Protocol Solvency Thinking

For DeFi, always ask:

- Who is owed assets?
- Where are those assets held?
- Can assets leave before liabilities decrease?
- Can shares be minted too cheaply?
- Can rewards be claimed twice?
- Can oracle prices make bad debt invisible?
- Can a paused protocol still lose funds?

### Every External Call Is Dangerous

External calls include:

- ETH sends.
- ERC20 transfers.
- ERC721 safe transfers.
- ERC1155 safe transfers.
- Oracle reads.
- Hook callbacks.
- Router swaps.
- Bridge calls.
- Delegatecalls.

Mental rule: after an external call, assume the world may have changed unless your design prevents it.

[Back to top](#table-of-contents)

---

## Recommended Tools

Tools do not replace understanding, but they catch many bugs faster than manual review alone.

### Foundry Fuzzing

Foundry turns parameterized tests into fuzz tests.

```solidity
function testFuzz_Deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);
    vault.deposit{value: amount}();
    assertEq(vault.balanceOf(address(this)), amount);
}
```

Use fuzzing for numeric boundaries and user-controlled inputs.

### Foundry Invariant Testing

Invariant tests check properties across many calls.

Good targets:

- Total assets vs total liabilities.
- No user balance below zero.
- Total shares consistency.
- Pause rules.
- Collateralization.

### Slither

Slither is a static analyzer for Solidity.

Use it to catch:

- Reentrancy patterns.
- Uninitialized variables.
- Dangerous low-level calls.
- Shadowing.
- Incorrect modifiers.
- Common ERC issues.

Typical command:

```bash
slither .
```

### Echidna

Echidna is a property-based fuzzing tool.

Use it for:

- Security properties.
- Stateful fuzzing.
- Invariants.
- Edge cases Foundry tests may not cover.

Example property style:

```solidity
function echidna_total_assets_cover_supply() external view returns (bool) {
    return asset.balanceOf(address(this)) >= totalSupply;
}
```

### Mythril

Mythril is a symbolic analysis tool.

It can help find:

- Reentrancy paths.
- Integer issues.
- Reachable asserts.
- Some authorization bugs.

Symbolic tools can produce false positives, so review results manually.

### OpenZeppelin Contracts

Use audited building blocks:

- `Ownable`
- `AccessControl`
- `ReentrancyGuard`
- `Pausable`
- ERC20 / ERC721 / ERC1155 implementations
- Safe token utilities
- Proxy patterns

Do not copy random token implementations from the internet.

### Mainnet Fork Testing

Use Foundry forks for integration reality checks:

```bash
forge test --fork-url $MAINNET_RPC_URL --fork-block-number 19000000
```

Test:

- Token decimals.
- Transfer behavior.
- Oracle responses.
- Router swaps.
- Protocol callbacks.
- Deployment scripts.

[Back to top](#table-of-contents)

---

## Final Audit Checklist

Before shipping, ask:

- Can any external call reenter?
- Is authorization based on `msg.sender`, roles, or signatures instead of `tx.origin`?
- Are all upgrade paths controlled and tested?
- Are storage layouts stable across upgrades?
- Are arithmetic operations safe and rounded intentionally?
- Can randomness be predicted or manipulated?
- Can pending transactions be front-run?
- Are user slippage and deadlines enforced?
- Are oracle values fresh and robust?
- Are external integrations trusted, upgradeable, or malicious?
- Are invariants defined and tested?
- Are emergency controls clear and limited?
- Are private keys, deployers, and admins operationally secure?

Final mental model:

Smart contracts are public, permanent, adversarial financial software. Design them as if every input is hostile, every external call is dangerous, and every assumption will eventually be tested by someone with money on the line.

[Back to top](#table-of-contents)
