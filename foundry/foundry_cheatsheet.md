# Foundry Cheatsheet

Foundry is a fast, Solidity-native smart contract development toolkit. It is powerful because it lets you compile, test, fuzz, debug, deploy, fork networks, and interact with contracts from a tight command-line workflow, with tests and scripts written directly in Solidity.

Use this as a daily development reference: start with project setup and Forge basics, then come back for cheatcodes, fuzzing, invariant testing, deployment, debugging, and Cast commands when you need them.

---

## Table of Contents

### Foundations
- [1. Foundry Overview](#1-foundry-overview)
- [2. Foundry Toolkit](#2-foundry-toolkit)
- [3. Installation](#3-installation)
- [4. Project Setup](#4-project-setup)

### Forge Development
- [5. Forge Core Tool](#5-forge-core-tool)
- [6. Writing Tests in Solidity](#6-writing-tests-in-solidity)
- [7. Cheatcodes](#7-cheatcodes)
- [8. Logging](#8-logging)
- [9. Fuzz Testing](#9-fuzz-testing)
- [10. Invariant Testing](#10-invariant-testing)

### CLI, Local Chains, and REPL
- [11. Cast CLI Tool](#11-cast-cli-tool)
- [12. Anvil Local Node](#12-anvil-local-node)
- [13. Chisel REPL](#13-chisel-repl)

### Deployment and Automation
- [14. Deploying Contracts](#14-deploying-contracts)
- [15. Forge Scripts Advanced](#15-forge-scripts-advanced)
- [16. foundry.toml Configuration](#16-foundrytoml-configuration)

### Debugging and Production Practice
- [17. Debugging](#17-debugging)
- [18. Best Practices](#18-best-practices)
- [19. Common Errors](#19-common-errors)
- [20. Mental Model](#20-mental-model)
- [21. Daily Command Reference](#21-daily-command-reference)

### Testing Roadmap
- [22. Complete Foundry Testing Guide + Video Roadmap](#22-complete-foundry-testing-guide--video-roadmap)

---

## 1. Foundry Overview

Foundry is a smart contract development framework focused on speed, Solidity-native testing, and powerful command-line workflows.

At a high level, Foundry helps you:

- Compile Solidity contracts.
- Run unit tests written in Solidity.
- Run fuzz tests and invariant tests.
- Simulate and broadcast deployments.
- Fork live networks locally.
- Inspect storage, calldata, traces, and transactions.
- Interact with contracts directly from the terminal.
- Debug failed transactions and test traces.

### Why Foundry Is Popular

Foundry is especially popular with smart contract engineers because it is:

- Fast: the tools are written in Rust.
- Solidity-native: tests are written in Solidity instead of JavaScript or TypeScript.
- CLI-first: common tasks are scriptable and easy to automate.
- Good for security work: fuzzing, invariant testing, traces, and forks are first-class workflows.
- Lightweight: projects usually have less framework overhead.

### Foundry vs Hardhat

| Feature | Foundry | Hardhat |
|---|---|---|
| Primary test language | Solidity | JavaScript / TypeScript |
| Runtime | Rust tooling | Node.js tooling |
| Speed | Very fast compilation/test loop | Flexible but usually slower |
| Fuzz testing | Built in | Usually plugin or custom setup |
| Invariant testing | Built in | Usually plugin or custom setup |
| Local node | `anvil` | Hardhat Network |
| Contract interaction CLI | `cast` | Hardhat tasks/scripts, ethers |
| Best fit | Solidity-heavy testing, audits, protocol dev | JS-heavy apps, plugin ecosystem, frontend integration |

Foundry and Hardhat are not enemies. Many teams use Foundry for contract testing and Hardhat or custom scripts for frontend/deployment workflows. Foundry shines when you want fast Solidity-native feedback.

### Typical Foundry Workflow

```bash
forge build
forge test
forge test -vvv
anvil
forge script script/Deploy.s.sol --rpc-url <url> --broadcast
cast call <address> "balanceOf(address)(uint256)" <user> --rpc-url <url>
```

### When to Use Foundry

Use Foundry when:

- You want tests written close to the contracts.
- You want fuzzing and invariants without extra setup.
- You need fast feedback while developing Solidity.
- You are building protocols, tokens, vaults, governance systems, or low-level infrastructure.
- You care about traces, forks, and reproducible command-line workflows.

> Related video: [Introduction | Testing with Foundry](https://www.youtube.com/watch?v=tgs5q-GJmg4)

[Back to top](#table-of-contents)

---

## 2. Foundry Toolkit

Foundry is not one program. It is a toolkit made of several command-line tools.

| Tool | Purpose | Common use |
|---|---|---|
| `forge` | Build, test, script, deploy, inspect | Main development tool |
| `cast` | Interact with chains and contracts | Calls, transactions, ABI encoding, storage reads |
| `anvil` | Local Ethereum node | Local dev chain, mainnet forks |
| `chisel` | Solidity REPL | Quick experiments and snippets |

### Forge

Forge is the core development tool.

Use it for:

- `forge init`
- `forge build`
- `forge test`
- `forge script`
- `forge create`
- `forge inspect`
- `forge fmt`
- `forge coverage`

### Cast

Cast is the Swiss army knife for chain interaction.

Use it for:

- Reading contract state.
- Sending transactions.
- Encoding calldata.
- Decoding return data.
- Inspecting storage.
- Replaying transactions with traces.
- Checking chain IDs, blocks, gas, balances, and nonces.

### Anvil

Anvil is a local Ethereum-compatible node.

Use it for:

- Local development.
- Test accounts with funded private keys.
- Forking mainnet or testnets.
- Simulating transactions against real deployed contracts.

### Chisel

Chisel is an interactive Solidity REPL.

Use it for:

- Trying Solidity expressions quickly.
- Checking ABI encoding behavior.
- Testing type conversions.
- Experimenting with small snippets.

[Back to top](#table-of-contents)

---

## 3. Installation

Install Foundry with the official installer:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

The first command installs `foundryup`, the Foundry version manager. The second command downloads and installs the Foundry tools.

### PATH Setup

After installation, restart your terminal or source your shell profile.

Common shell files:

```bash
~/.bashrc
~/.zshrc
~/.profile
```

Foundry tools are usually installed under:

```bash
~/.foundry/bin
```

If your terminal cannot find `forge`, add Foundry to your `PATH`:

```bash
export PATH="$HOME/.foundry/bin:$PATH"
```

For `zsh`, you can add that line to:

```bash
~/.zshrc
```

Then reload:

```bash
source ~/.zshrc
```

### Verify Installation

```bash
forge --version
cast --version
anvil --version
chisel --version
```

### Version Management

Use `foundryup` to update Foundry:

```bash
foundryup
```

Useful options:

```bash
foundryup --help
foundryup --version
```

Practical guidance:

- Run `foundryup` when you need the latest features or bug fixes.
- Pin important CI environments when reproducibility matters.
- If a project behaves differently after updating Foundry, check the installed version first.

### Common Installation Issues

| Problem | Likely cause | Fix |
|---|---|---|
| `forge: command not found` | PATH not updated | Add `~/.foundry/bin` to PATH and restart shell |
| Installer works but tools missing | `foundryup` not run | Run `foundryup` |
| Different version in CI | Unpinned toolchain | Pin Foundry version in CI setup |
| Shell still cannot find tools | Profile not sourced | Run `source ~/.zshrc` or open a new terminal |

[Back to top](#table-of-contents)

---

## 4. Project Setup

Create and test a new project:

```bash
forge init my_project
cd my_project
forge build
forge test
```

> Related video: [Introduction | Testing with Foundry](https://www.youtube.com/watch?v=tgs5q-GJmg4)

### Standard Folder Structure

| Path | Purpose |
|---|---|
| `src/` | Production Solidity contracts |
| `test/` | Solidity test files |
| `script/` | Deployment and automation scripts |
| `lib/` | Dependencies installed as git submodules |
| `foundry.toml` | Project configuration |
| `out/` | Build artifacts generated by Forge |
| `cache/` | Compiler cache generated by Forge |

### Example Layout

```text
my_project/
  foundry.toml
  src/
    Counter.sol
  test/
    Counter.t.sol
  script/
    Counter.s.sol
  lib/
    forge-std/
```

### Install Dependencies

Foundry commonly installs libraries into `lib/`.

```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
```

By default, dependencies are git submodules.

### Remappings

Remappings tell Solidity how to resolve imports.

Example import:

```solidity
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
```

View remappings:

```bash
forge remappings
```

Generate remappings:

```bash
forge remappings > remappings.txt
```

> Related video: [Remappings | Testing with Foundry](https://www.youtube.com/watch?v=7DK75j8csTA)

### Formatting

```bash
forge fmt
```

Check formatting without changing files:

```bash
forge fmt --check
```

> Related video: [Auto Format Code | Testing with Foundry](https://www.youtube.com/watch?v=k55TIWUFLbQ)

### Clean Build Artifacts

```bash
forge clean
forge build
```

Use this when build output seems stale or dependency paths changed.

[Back to top](#table-of-contents)

---

## 5. Forge Core Tool

Forge is the main Foundry command for compilation, testing, scripting, deployment, formatting, and inspection.

### Compilation

```bash
forge build
```

Useful build commands:

```bash
forge build --sizes
forge build --force
forge clean
forge inspect <ContractName> abi
forge inspect <ContractName> storage-layout
```

| Command | Use |
|---|---|
| `forge build` | Compile the project |
| `forge build --sizes` | Show contract bytecode sizes |
| `forge build --force` | Force recompilation |
| `forge clean` | Delete cache and artifacts |
| `forge inspect` | Inspect ABI, bytecode, storage layout, metadata |

### Testing

```bash
forge test
forge test -vvv
forge test --match-test testName
```

More filters:

```bash
forge test --match-contract CounterTest
forge test --match-path test/Counter.t.sol
forge test --match-test "testDeposit*"
```

### Verbosity Levels

| Flag | Output |
|---|---|
| `-v` | Basic extra output |
| `-vv` | Logs emitted during tests |
| `-vvv` | Traces for failing tests |
| `-vvvv` | Traces for all tests |
| `-vvvvv` | Very detailed traces, including setup |

Practical default:

```bash
forge test -vvv
```

Use `-vvv` when debugging failures. Use `-vvvv` or `-vvvvv` when you need deeper traces.

### Running Specific Tests

Run one test:

```bash
forge test --match-test testIncrement
```

Run tests in one contract:

```bash
forge test --match-contract CounterTest
```

Run one file:

```bash
forge test --match-path test/Counter.t.sol
```

Run tests matching a pattern:

```bash
forge test --match-test "testFuzz_*"
```

### Gas Reports

```bash
forge test --gas-report
```

Use gas reports to compare optimization changes, but do not optimize before correctness and security.

### Coverage

```bash
forge coverage
```

Coverage is useful, but high coverage does not mean high security. Fuzzing, invariant tests, review, and threat modeling still matter.

### Inspecting Contracts

```bash
forge inspect src/Counter.sol:Counter abi
forge inspect src/Counter.sol:Counter bytecode
forge inspect src/Counter.sol:Counter deployedBytecode
forge inspect src/Counter.sol:Counter storage-layout
forge inspect src/Counter.sol:Counter methods
```

Use `forge inspect` when debugging ABI signatures, selectors, storage layout, or generated bytecode.

> Related video: [Print Storage, Functions and ABI with Foundry](https://www.youtube.com/watch?v=puUL_vTrXhA)

[Back to top](#table-of-contents)

---

## 6. Writing Tests in Solidity

Foundry tests are Solidity contracts. This makes tests feel close to the contracts they verify and gives you direct access to Solidity types, inheritance, interfaces, events, and low-level calls.

> Related video: [How to Write Basic Tests | Testing with Foundry](https://www.youtube.com/watch?v=HA0GWauMOsU)

### Basic Test Contract

Most tests inherit from `forge-std/Test.sol`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter counter;

    function setUp() public {
        counter = new Counter();
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.count(), 1);
    }
}
```

### Test Contract Inheritance

`Test` gives you:

- Assertion helpers such as `assertEq`, `assertTrue`, `assertFalse`.
- The `vm` cheatcode interface.
- Logging utilities when imported separately.
- Helpers for addresses, labels, and expected failures.

### setUp()

`setUp()` runs before each test function.

Use it to:

- Deploy contracts.
- Create users.
- Fund accounts.
- Set approvals.
- Initialize shared state.

```solidity
function setUp() public {
    owner = makeAddr("owner");
    alice = makeAddr("alice");
    counter = new Counter();
}
```

### Test Function Naming

Foundry treats functions starting with `test` as tests.

```solidity
function testDeposit() public {}
function test_RevertWhen_NotOwner() public {}
function testFuzz_Deposit(uint256 amount) public {}
```

Common naming style:

```text
test_Action()
test_RevertWhen_Condition()
testFuzz_Action(uint256 input)
```

### Assertions

```solidity
assertEq(actual, expected);
assertTrue(condition);
assertFalse(condition);
assertGt(a, b);
assertGe(a, b);
assertLt(a, b);
assertLe(a, b);
```

Example:

```solidity
function testIncrement() public {
    counter.increment();
    assertEq(counter.count(), 1);
}
```

### Testing Reverts

```solidity
function test_RevertWhen_NotOwner() public {
    vm.prank(alice);
    vm.expectRevert("Not owner");
    vault.sweep();
}
```

> Related video: [Error | Testing with Foundry](https://www.youtube.com/watch?v=yY9lL4Jxkd8)

### Testing Events

```solidity
event Deposit(address indexed user, uint256 amount);

function testEmitDeposit() public {
    vm.expectEmit(true, false, false, true);
    emit Deposit(alice, 1 ether);

    vm.prank(alice);
    vault.deposit{value: 1 ether}();
}
```

> Related video: [Event | Testing with Foundry](https://www.youtube.com/watch?v=GYwKDSSpzjQ)

### Arrange, Act, Assert

A clean test usually follows:

```solidity
function testWithdraw() public {
    // Arrange
    vm.deal(alice, 10 ether);
    vm.prank(alice);
    vault.deposit{value: 1 ether}();

    // Act
    vm.prank(alice);
    vault.withdraw();

    // Assert
    assertEq(vault.balanceOf(alice), 0);
}
```

[Back to top](#table-of-contents)

---

## 7. Cheatcodes

Cheatcodes are special testing functions exposed through the `vm` object. They let tests control blockchain state, caller identity, balances, timestamps, blocks, expected reverts, events, storage, forks, and more.

Cheatcodes are one of Foundry's biggest strengths because they let you write precise, adversarial tests directly in Solidity.

> Related videos:
> - [Authentication | Testing with Foundry](https://www.youtube.com/watch?v=gYwO3Jbi4O4)
> - [Error | Testing with Foundry](https://www.youtube.com/watch?v=yY9lL4Jxkd8)
> - [Event | Testing with Foundry](https://www.youtube.com/watch?v=GYwKDSSpzjQ)

### Cheatcode Quick Reference

| Cheatcode | Purpose |
|---|---|
| `vm.prank(user)` | Make the next call come from `user` |
| `vm.startPrank(user)` | Make all following calls come from `user` |
| `vm.stopPrank()` | Stop an active prank |
| `vm.expectRevert(...)` | Expect the next call to revert |
| `vm.expectEmit(...)` | Expect an event emission |
| `vm.roll(blockNumber)` | Set block number |
| `vm.warp(timestamp)` | Set block timestamp |
| `vm.deal(user, amount)` | Set ETH balance |
| `vm.label(addr, name)` | Label address in traces |
| `vm.assume(condition)` | Filter fuzz inputs |
| `vm.bound(value, min, max)` | Bound fuzz input range |

### vm.prank

`vm.prank(address)` changes `msg.sender` for the next call only.

```solidity
function testOnlyOwner() public {
    address alice = makeAddr("alice");

    vm.prank(alice);
    vm.expectRevert("Not owner");
    vault.setFee(100);
}
```

Use it when you need one action from a specific account.

### vm.startPrank / vm.stopPrank

`vm.startPrank(address)` changes `msg.sender` for all following calls until `vm.stopPrank()`.

```solidity
function testUserFlow() public {
    address alice = makeAddr("alice");
    vm.deal(alice, 10 ether);

    vm.startPrank(alice);
    vault.deposit{value: 1 ether}();
    vault.withdraw();
    vm.stopPrank();
}
```

Use it for multi-step user flows.

Common mistake:

```solidity
vm.startPrank(alice);
// calls...
// forgot vm.stopPrank()
```

Forgetting `stopPrank()` can make later calls appear to come from the wrong user.

### vm.expectRevert

Expect a revert from the next external call.

```solidity
function test_RevertWhen_ZeroAmount() public {
    vm.expectRevert("Amount is zero");
    vault.deposit(0);
}
```

For custom errors:

```solidity
error NotOwner(address caller);

function test_RevertWhen_NotOwner() public {
    address alice = makeAddr("alice");

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, alice));
    vault.adminAction();
}
```

For any revert:

```solidity
vm.expectRevert();
contractCallThatShouldFail();
```

### vm.expectEmit

Use `expectEmit` to check events.

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

function testTransferEmits() public {
    vm.expectEmit(true, true, false, true);
    emit Transfer(alice, bob, 100);

    token.transferFrom(alice, bob, 100);
}
```

Parameters:

```solidity
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
```

For most ERC20 transfers:

```solidity
vm.expectEmit(true, true, false, true);
```

This checks indexed `from`, indexed `to`, and data `amount`.

### vm.roll

Set the block number.

```solidity
function testAfterBlocks() public {
    vm.roll(block.number + 100);
    assertTrue(protocol.canExecute());
}
```

Use it for block-based delays, voting periods, timelocks, or mining simulations.

> Related video: [Time | Testing with Foundry](https://www.youtube.com/watch?v=B_3Kax70sF4)

### vm.warp

Set the timestamp.

```solidity
function testVestingUnlocks() public {
    vm.warp(block.timestamp + 365 days);
    vesting.claim();
}
```

Use it for vesting, deadlines, auctions, staking rewards, and time locks.

> Related video: [Time | Testing with Foundry](https://www.youtube.com/watch?v=B_3Kax70sF4)

### vm.deal

Set an address ETH balance.

```solidity
function testDeposit() public {
    vm.deal(alice, 10 ether);

    vm.prank(alice);
    vault.deposit{value: 1 ether}();

    assertEq(address(vault).balance, 1 ether);
}
```

> Related video: [Send ETH | Testing with Foundry](https://www.youtube.com/watch?v=GuwUC-Wy_B0)

### makeAddr

`makeAddr` is a helper from `forge-std/Test.sol`.

```solidity
address alice = makeAddr("alice");
```

It creates a deterministic test address and labels it nicely in traces.

### hoax

`hoax` combines `vm.deal` and `vm.prank`.

```solidity
hoax(alice, 10 ether);
vault.deposit{value: 1 ether}();
```

Use it when one funded call is enough.

### vm.assume

Use `assume` in fuzz tests to reject invalid inputs.

```solidity
function testFuzz_Deposit(uint256 amount) public {
    vm.assume(amount > 0);
    vm.assume(amount < 100 ether);

    // test logic
}
```

Avoid overusing `assume`; too many rejected inputs can make fuzzing inefficient.

### vm.bound

Use `bound` to constrain fuzz inputs.

```solidity
function testFuzz_Deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);
    // test logic
}
```

This is often cleaner than many `assume` calls.

### vm.sign

`vm.sign` signs a digest with a private key inside a test. It is useful for testing ECDSA verification, permit-style approvals, off-chain authorizations, and replay protection.

```solidity
function testSignature() public {
    uint256 privateKey = 0xA11CE;
    address signer = vm.addr(privateKey);

    bytes32 digest = keccak256(abi.encodePacked("authorize", signer));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

    address recovered = ecrecover(digest, v, r, s);
    assertEq(recovered, signer);
}
```

When testing production signature flows, make sure the digest matches the exact scheme your contract verifies, such as Ethereum signed messages or EIP-712 typed data.

> Related video: [Signature | Testing with Foundry](https://www.youtube.com/watch?v=cs5IeYqviSQ)

### Cheatcode Safety Notes

- Cheatcodes work in tests and scripts, not production contracts.
- Cheatcodes can create states that are impossible on a real chain if misused.
- Use cheatcodes to model realistic adversarial conditions, not to hide bugs.
- Keep test setup explicit so future readers understand what the chain state is.

[Back to top](#table-of-contents)

---

## 8. Logging

Foundry supports Solidity logging through `forge-std/console.sol`.

```solidity
import "forge-std/console.sol";

console.log("value:", x);
```

> Related video: [Console Log | Testing with Foundry](https://www.youtube.com/watch?v=pO3kfXCFLuE)

### Basic Logging

```solidity
console.log("hello");
console.log("value:", uint256Value);
console.log("address:", user);
console.log("balance:", address(user).balance);
```

Run with verbosity:

```bash
forge test -vv
```

If you do not see logs, increase verbosity.

### Typed Logging

Depending on the imported console helper, you can log common Solidity types:

```solidity
console.logUint(amount);
console.logInt(delta);
console.logAddress(user);
console.logBool(ok);
console.logBytes32(hash);
```

Practical examples:

```solidity
console.log("msg.sender", msg.sender);
console.log("totalSupply", token.totalSupply());
console.log("vault balance", address(vault).balance);
```

### When to Use Logs

Use logs for:

- Understanding test setup.
- Inspecting fuzz failure values.
- Debugging math.
- Checking caller identity.
- Reading balances during a flow.

Avoid leaving noisy logs in committed tests unless they are intentionally useful.

[Back to top](#table-of-contents)

---

## 9. Fuzz Testing

Fuzz testing means Foundry automatically generates randomized inputs for test function arguments.

If a test function accepts parameters, Foundry treats it as a fuzz test.

> Related video: [Fuzz | Testing with Foundry](https://www.youtube.com/watch?v=6sMOeuqwk-U)

```solidity
function testFuzz(uint256 x) public {
    assert(x >= 0);
}
```

This example always passes because `uint256` is never negative. Real fuzz tests should assert meaningful properties.

### Practical Fuzz Example

```solidity
function testFuzz_Deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);

    vm.deal(alice, amount);
    vm.prank(alice);
    vault.deposit{value: amount}();

    assertEq(vault.balanceOf(alice), amount);
}
```

### Why Fuzzing Is Powerful

Fuzzing finds edge cases humans forget:

- `0`
- `1`
- Very large numbers.
- Max uint values.
- Empty arrays.
- Duplicate addresses.
- Weird ordering.
- Boundary values around caps, limits, deadlines, or precision math.

### Fuzz Failure Output

When Foundry finds a failing input, it prints the counterexample.

Example style:

```text
Failing tests:
Encountered 1 failing test in test/Vault.t.sol:VaultTest
[FAIL. Reason: assertion failed; counterexample: calldata=..., args=[0]]
```

Use the failing input to write a regression test.

### vm.assume vs bound

| Tool | Use | Warning |
|---|---|---|
| `vm.assume(condition)` | Reject invalid generated inputs | Too many rejects can slow fuzzing |
| `bound(value, min, max)` | Force input into useful range | Can hide behavior outside range |

Prefer `bound` when the valid range is simple. Use `assume` for relational constraints.

### Fuzz Configuration

Configure fuzz runs in `foundry.toml`:

```toml
[fuzz]
runs = 1000
```

Run more fuzz cases in CI than during local development if tests become slow.

### Good Fuzz Properties

Good fuzz tests assert properties that should always hold:

- Depositing increases user balance by deposited amount.
- Withdrawing never pays more than a user's balance.
- Total supply equals sum of balances.
- A function never reverts for valid inputs.
- A function always reverts for invalid inputs.
- Fees never exceed a maximum.

[Back to top](#table-of-contents)

---

## 10. Invariant Testing

Invariant testing checks that important properties remain true after many randomized sequences of calls.

Unit tests usually check one specific scenario. Fuzz tests randomize inputs for one function. Invariant tests let Foundry call multiple functions in many orders to try to break assumptions.

### Simple Invariant Example

```solidity
function invariantAlwaysEven() public {
    assert(counter.number() % 2 == 0);
}
```

If Foundry can find a sequence of calls that makes `counter.number()` odd, the invariant fails.

### What Is an Invariant?

An invariant is a property that should always be true.

Examples:

- Contract ETH balance is at least total user deposits.
- Total ERC20 supply equals the sum of all balances.
- A vault's assets are never less than user shares imply.
- A protocol cannot become insolvent.
- A paused contract cannot execute sensitive actions.

### Handler-Based Invariants

Real invariant tests often use a handler contract. The handler exposes actions Foundry is allowed to call.

```solidity
contract VaultHandler {
    Vault vault;

    constructor(Vault _vault) {
        vault = _vault;
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        vault.deposit{value: amount}();
    }

    function withdraw(uint256 amount) public {
        vault.withdraw(amount);
    }
}
```

Then the invariant test targets the handler.

```solidity
function setUp() public {
    vault = new Vault();
    handler = new VaultHandler(vault);
    targetContract(address(handler));
}

function invariantSolvent() public {
    assertGe(address(vault).balance, vault.totalDeposits());
}
```

### How Foundry Breaks Assumptions

Foundry may:

- Call functions in unexpected order.
- Repeat the same call many times.
- Use edge-case input values.
- Use addresses you did not think about.
- Hit states your unit tests never created.

This is exactly why invariant testing is valuable.

### Invariant Configuration

```toml
[invariant]
runs = 256
depth = 64
fail_on_revert = false
```

| Setting | Meaning |
|---|---|
| `runs` | Number of invariant campaigns |
| `depth` | Number of calls per campaign |
| `fail_on_revert` | Whether a revert fails the invariant run |

### Invariant Testing Tips

- Start with one simple invariant.
- Use handlers to constrain actions to realistic behavior.
- Track ghost variables when needed.
- Label addresses for readable traces.
- Treat every invariant failure as a design question, not just a test bug.
- Add regression unit tests for minimized failing sequences.

[Back to top](#table-of-contents)

---

## 11. Cast CLI Tool

Cast is Foundry's command-line tool for interacting with Ethereum data, contracts, transactions, ABI encoding, and RPC endpoints.

### Read Calls

```bash
cast call <address> "function()(type)" --rpc-url <url>
```

Example:

```bash
cast call 0xToken "balanceOf(address)(uint256)" 0xUser --rpc-url $RPC_URL
```

Another example:

```bash
cast call 0xContract "owner()(address)" --rpc-url $RPC_URL
```

### Send Transactions

```bash
cast send <address> "function(args)" --private-key <key>
```

Example:

```bash
cast send 0xToken "transfer(address,uint256)" 0xRecipient 1000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Useful Cast Commands

| Command | Purpose |
|---|---|
| `cast calldata` | Encode function calldata |
| `cast abi-encode` | ABI-encode values |
| `cast decode-abi` | Decode ABI return or calldata values |
| `cast interface` | Generate an interface from verified contract ABI |
| `cast run` | Replay and debug a transaction |
| `cast storage` | Read raw contract storage |
| `cast chain-id` | Get chain ID |
| `cast balance` | Get ETH balance |
| `cast block` | Read block data |
| `cast tx` | Read transaction data |
| `cast receipt` | Read transaction receipt |
| `cast wallet import` | Import a private key into an encrypted keystore |
| `cast wallet list` | List configured keystore wallets |
| `cast wallet remove` | Remove a wallet from the keystore |
| `cast sig` | Compute function selector |
| `cast keccak` | Compute keccak256 hash |
| `cast to-wei` | Convert ETH units to wei |
| `cast from-wei` | Convert wei to ETH units |

### cast calldata

Encode calldata for a function call:

```bash
cast calldata "transfer(address,uint256)" 0xRecipient 1000
```

Use this when debugging low-level calls or building raw transaction data.

### cast abi-encode

Encode ABI values:

```bash
cast abi-encode "f(address,uint256)" 0xRecipient 1000
```

This is useful when constructing calldata manually or debugging ABI encoding.

### cast decode-abi

Decode ABI-encoded output:

```bash
cast decode-abi "balanceOf(address)(uint256)" <hexdata>
```

You can also decode custom errors and event data when you know the ABI shape.

### cast interface

Generate an interface from a verified contract:

```bash
cast interface <address> --chain mainnet
```

This is useful when integrating with deployed contracts.

### cast run

`cast run` replays a transaction and shows execution details.

```bash
cast run <tx_hash> --rpc-url <url>
```

Why it matters:

- Debug failed transactions.
- Inspect traces.
- See internal calls.
- Understand where a revert happened.
- Analyze production incidents.

Use it when a transaction on a live network failed and you need to understand why.

### cast storage

Read raw storage:

```bash
cast storage <address> <slot> --rpc-url <url>
```

Example:

```bash
cast storage 0xContract 0 --rpc-url $RPC_URL
```

Storage reads are low-level. You need to understand Solidity storage layout to interpret the result.

### cast chain-id

```bash
cast chain-id --rpc-url $RPC_URL
```

Use this to confirm you are pointed at the correct network before sending transactions.

### Wallet Management

Cast can manage encrypted local keystores so you do not need to paste raw private keys into every command.

Import a private key interactively:

```bash
cast wallet import deployer --interactive
```

List wallets:

```bash
cast wallet list
```

Remove a wallet:

```bash
cast wallet remove --name deployer
```

Use an imported account with Cast or Forge commands:

```bash
cast send <address> "function()" \
  --rpc-url $RPC_URL \
  --account deployer
```

```bash
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL \
  --account deployer \
  --broadcast
```

> Related videos:
> - [Manager Wallet and Send Transaction with Foundry Cast](https://www.youtube.com/watch?v=0AugPHQpmKQ)
> - [Import wallet into Foundry script using cast](https://www.youtube.com/watch?v=7HRhRw3vrUI)

### Unit Conversion

```bash
cast to-wei 1 ether
cast from-wei 1000000000000000000 ether
```

### Function Selectors

```bash
cast sig "transfer(address,uint256)"
```

Output:

```text
0xa9059cbb
```

[Back to top](#table-of-contents)

---

## 12. Anvil Local Node

Anvil is Foundry's local Ethereum node.

Start it with:

```bash
anvil
```

It launches a local blockchain, usually at:

```text
http://127.0.0.1:8545
```

### What Anvil Gives You

- Local chain.
- Funded test accounts.
- Private keys for local-only use.
- Fast mining.
- Deterministic development environment.
- Optional mainnet or testnet forking.

### Default Accounts

When Anvil starts, it prints:

- Account addresses.
- Private keys.
- Mnemonic.
- RPC URL.
- Chain ID.

Warning: Anvil private keys are public development keys. Never use them on mainnet or with real funds.

### Connect Forge to Anvil

Terminal 1:

```bash
anvil
```

Terminal 2:

```bash
forge test --rpc-url http://127.0.0.1:8545
```

Deploy locally:

```bash
forge script script/Deploy.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <anvil_private_key> \
  --broadcast
```

### Fork Mainnet

```bash
anvil --fork-url $MAINNET_RPC_URL
```

Fork at a specific block:

```bash
anvil --fork-url $MAINNET_RPC_URL --fork-block-number 19000000
```

Use a fixed block number for deterministic tests.

### Why Forking Is Useful

Forking lets you test against real deployed contracts:

- Tokens.
- DEXes.
- Oracles.
- Lending protocols.
- Governance contracts.

Example use cases:

- Test your contract against mainnet USDC behavior.
- Simulate a DeFi integration.
- Reproduce a production bug.
- Test a migration before broadcasting.

> Related videos:
> - [Fork | Testing with Foundry](https://www.youtube.com/watch?v=eKxJZgp9CTg)
> - [Mint 1 Million DAI on Mainnet Fork | Testing with Foundry](https://www.youtube.com/watch?v=I8mzJxMBzs0)

[Back to top](#table-of-contents)

---

## 13. Chisel REPL

Chisel is an interactive Solidity REPL.

Start it with:

```bash
chisel
```

Use it for quick Solidity experiments without creating a full project.

### What Chisel Is Good For

- Testing arithmetic behavior.
- Checking type conversions.
- Trying ABI encoding.
- Exploring small snippets.
- Quickly evaluating expressions.

Example workflow:

```text
Welcome to Chisel
➜ uint256 x = 1 ether;
➜ x
```

### Debugging Use Cases

Use Chisel when:

- You want to test how Solidity casts a value.
- You forgot the result of an expression.
- You want to inspect ABI encoding quickly.
- You need a scratchpad while reading contract code.

Chisel is not a replacement for tests. It is a fast experimentation tool.

[Back to top](#table-of-contents)

---

## 14. Deploying Contracts

Foundry can deploy contracts directly with `forge create` or through Forge scripts.

> Related video: [Deploy Smart Contract With Foundry](https://www.youtube.com/watch?v=AxnvSYxQC5o)

### forge create

```bash
forge create src/Contract.sol:Contract \
  --rpc-url <url> \
  --private-key <key> \
  --broadcast
```

If the contract has constructor arguments:

```bash
forge create src/Token.sol:Token \
  --constructor-args "My Token" "MTK" 1000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Dry Run vs Broadcast

Without broadcasting, Foundry can simulate actions. With `--broadcast`, it sends transactions.

| Mode | What happens |
|---|---|
| Simulation / dry run | Foundry checks what would happen |
| `--broadcast` | Foundry submits transactions to the network |

Always simulate before broadcasting to a real network.

### Chain IDs

Confirm chain ID before deployment:

```bash
cast chain-id --rpc-url $RPC_URL
```

Set chain ID in `foundry.toml` or pass network-specific RPC URLs carefully.

### Gas Estimation

Foundry estimates gas before sending transactions. Still, you should:

- Check network congestion.
- Confirm account balance.
- Confirm RPC endpoint.
- Simulate first.
- Use a testnet or fork before mainnet.

### Verify Contracts

Common pattern:

```bash
forge verify-contract <address> src/Contract.sol:Contract \
  --chain-id <chain_id> \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

Verification requires exact compiler settings, optimizer settings, constructor args, and source.

### Deployment Safety Checklist

- Correct RPC URL.
- Correct chain ID.
- Correct private key or wallet.
- Correct constructor arguments.
- Tests passing.
- Simulation successful.
- Source can be verified.
- Admin/owner address is correct.
- No secrets committed.

[Back to top](#table-of-contents)

---

## 15. Forge Scripts Advanced

Forge scripts are Solidity scripts used for deployment and automation.

They usually live in:

```text
script/
```

### Basic Script

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Contract.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        new Contract();
        vm.stopBroadcast();
    }
}
```

Core broadcast pattern:

```solidity
vm.startBroadcast();
new Contract();
vm.stopBroadcast();
```

Run the script:

```bash
forge script script/Deploy.s.sol --broadcast
```

Usually you also pass RPC and key:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Simulation Before Execution

Run without `--broadcast` first:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL
```

Then broadcast:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Transaction Batching

Forge scripts can perform multiple actions:

```solidity
function run() external {
    vm.startBroadcast();

    Token token = new Token();
    Vault vault = new Vault(address(token));
    token.transferOwnership(address(vault));

    vm.stopBroadcast();
}
```

Foundry simulates the sequence first, then broadcasts transactions when requested.

### Broadcast With a Specific Sender

```solidity
uint256 deployerKey = vm.envUint("PRIVATE_KEY");

vm.startBroadcast(deployerKey);
new Contract();
vm.stopBroadcast();
```

### Reading Environment Variables

```solidity
uint256 privateKey = vm.envUint("PRIVATE_KEY");
address owner = vm.envAddress("OWNER");
string memory rpcUrl = vm.envString("RPC_URL");
```

> Related video: [Import wallet into Foundry script using cast](https://www.youtube.com/watch?v=7HRhRw3vrUI)

### Script Outputs

Foundry stores broadcast data under:

```text
broadcast/
```

This can include transaction data, receipts, and run metadata.

### Script Best Practices

- Keep scripts deterministic.
- Read addresses from environment variables or config files.
- Log deployed addresses.
- Simulate before broadcasting.
- Store deployment artifacts.
- Avoid hardcoded private keys.
- Separate local, testnet, and mainnet scripts if behavior differs.

[Back to top](#table-of-contents)

---

## 16. foundry.toml Configuration

`foundry.toml` controls project-level Foundry behavior.

> Related videos:
> - [Set Solidity Compiler Version | Testing with Foundry](https://www.youtube.com/watch?v=bmOxtjzFcbk)
> - [Remappings | Testing with Foundry](https://www.youtube.com/watch?v=7DK75j8csTA)

### Basic Example

```toml
[profile.default]
src = "src"
test = "test"
script = "script"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
chain_id = 31337

[fuzz]
runs = 1000

[invariant]
runs = 256
depth = 64
fail_on_revert = false
```

### profile.default

`profile.default` is the default configuration profile used by Forge.

Common settings:

| Setting | Meaning |
|---|---|
| `src` | Source contract directory |
| `test` | Test directory |
| `script` | Script directory |
| `out` | Artifact output directory |
| `libs` | Dependency directories |
| `solc_version` | Solidity compiler version |
| `optimizer` | Enable optimizer |
| `optimizer_runs` | Optimizer run count |
| `chain_id` | Default chain ID |

### Optimizer

```toml
optimizer = true
optimizer_runs = 200
```

General guidance:

- `200` is common for general deployment.
- Higher runs can help contracts called many times.
- Lower runs can reduce deployment bytecode size.
- Always benchmark meaningful changes.

### Chain ID

```toml
chain_id = 31337
```

Use local chain IDs for Anvil and correct chain IDs for target networks.

### Fuzz Settings

```toml
[fuzz]
runs = 1000
```

Increase runs for CI or security-sensitive code.

### Invariant Settings

```toml
[invariant]
runs = 256
depth = 64
fail_on_revert = false
```

Increase `runs` and `depth` when you want deeper exploration, but expect slower tests.

### Profiles

You can define multiple profiles:

```toml
[profile.default]
optimizer = true
optimizer_runs = 200

[profile.ci]
fuzz = { runs = 5000 }
invariant = { runs = 512, depth = 128 }
```

Use a profile:

```bash
FOUNDRY_PROFILE=ci forge test
```

### Remappings in Config

```toml
remappings = [
  "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
  "forge-std/=lib/forge-std/src/"
]
```

[Back to top](#table-of-contents)

---

## 17. Debugging

Foundry gives you several ways to debug contracts: logs, traces, transaction replay, local forks, and interactive debugging.

### Traces

Run tests with traces:

```bash
forge test -vvv
forge test -vvvv
forge test -vvvvv
```

Use traces to inspect:

- External calls.
- Internal calls.
- Reverts.
- Events.
- Logs.
- Gas usage.
- Call stack.

### Debug a Single Test

```bash
forge test --match-test testWithdraw -vvvv
```

This keeps output focused.

### console.log

```solidity
import "forge-std/console.sol";

console.log("amount", amount);
console.log("user", user);
```

Run with:

```bash
forge test -vv
```

> Related video: [Console Log | Testing with Foundry](https://www.youtube.com/watch?v=pO3kfXCFLuE)

### cast run

Replay a transaction:

```bash
cast run <tx_hash> --rpc-url $RPC_URL
```

Use `cast run` when debugging live or forked transactions. It is especially useful when:

- A deployment failed.
- A user transaction reverted.
- You need internal call traces.
- You are analyzing an exploit or incident.

### Debugger

Foundry includes interactive debugging workflows through Forge commands. A common pattern is to isolate the failing test, increase verbosity, and then use debugger support where appropriate.

```bash
forge test --match-test testName -vvvv
```

Practical debugging workflow:

1. Reproduce the failure.
2. Run only the failing test.
3. Add targeted logs.
4. Increase verbosity.
5. Inspect traces.
6. Reduce to a minimal failing case.
7. Add a regression test.

### Mainnet Fork Debugging

```bash
forge test --fork-url $MAINNET_RPC_URL --match-test testForkScenario -vvv
```

Use fork tests to reproduce issues involving deployed contracts, real token behavior, or protocol integrations.

> Related videos:
> - [Fork | Testing with Foundry](https://www.youtube.com/watch?v=eKxJZgp9CTg)
> - [Mint 1 Million DAI on Mainnet Fork | Testing with Foundry](https://www.youtube.com/watch?v=I8mzJxMBzs0)

[Back to top](#table-of-contents)

---

## 18. Best Practices

### Development

- Use Foundry for testing first.
- Prefer Solidity tests over JavaScript when testing contract logic.
- Keep tests close to the behavior they verify.
- Use clear test names.
- Use `setUp()` for shared deployment and state.
- Use helper functions to avoid repetitive setup.

### Testing

- Write unit tests for expected behavior.
- Write revert tests for invalid behavior.
- Use fuzzing aggressively for user inputs.
- Use invariant tests for protocol-level properties.
- Test edge cases: zero, one, max values, empty arrays, duplicate users, full balances.
- Use fork tests for integrations.
- Add regression tests for every bug found.

### Scripts and Deployment

- Keep scripts deterministic.
- Always simulate before broadcast.
- Confirm chain ID before sending transactions.
- Never commit private keys.
- Read secrets from environment variables.
- Log deployed addresses.
- Verify contracts after deployment.
- Use multisigs or hardware wallets for production admin roles.

### Security

- Treat `delegatecall`, upgradeability, low-level calls, and raw storage access as high-risk.
- Use fuzz and invariant tests for accounting logic.
- Test with malicious users, not only happy paths.
- Use mainnet forks for DeFi integrations.
- Keep admin and owner assumptions explicit.

### CI

Useful CI commands:

```bash
forge fmt --check
forge build
forge test
forge test --gas-report
forge coverage
```

For stronger CI:

```bash
FOUNDRY_PROFILE=ci forge test
```

[Back to top](#table-of-contents)

---

## 19. Common Errors

### chain_id mismatch

Symptoms:

- Transaction rejected.
- Signature invalid.
- Deployment goes to unexpected network.

Checks:

```bash
cast chain-id --rpc-url $RPC_URL
```

Fix:

- Confirm RPC URL.
- Confirm wallet network.
- Confirm `foundry.toml` chain ID.
- Confirm script target network.

### missing --broadcast

Symptom:

- Script appears to run, but no transaction appears on-chain.

Cause:

- Forge simulated the script but did not broadcast.

Fix:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### RPC issues

Symptoms:

- Timeout.
- Rate limit.
- Missing archive state.
- Fork tests fail at old blocks.

Fixes:

- Check RPC URL.
- Use a better RPC provider.
- Use an archive node for historical fork blocks.
- Retry with a fixed block number.

### incorrect ABI signature

Symptoms:

- `cast call` fails.
- Return data cannot decode.
- Function selector does not match.

Example problem:

```bash
cast call 0xToken "balanceOf()(uint256)" 0xUser
```

Correct:

```bash
cast call 0xToken "balanceOf(address)(uint256)" 0xUser
```

Use:

```bash
cast sig "balanceOf(address)"
```

### private key issues

Symptoms:

- Transaction signs from wrong account.
- Insufficient funds.
- Invalid private key format.

Fixes:

- Confirm the address:

```bash
cast wallet address --private-key $PRIVATE_KEY
```

- Confirm balance:

```bash
cast balance <address> --rpc-url $RPC_URL
```

- Never use a production private key in random scripts.

### remapping errors

Symptoms:

- Import not found.
- Solidity cannot resolve `forge-std/Test.sol`.

Fix:

```bash
forge install foundry-rs/forge-std
forge remappings
```

Add remappings if needed.

### expectRevert does not catch revert

Common causes:

- `vm.expectRevert` placed after the reverting call.
- Expected error data does not match.
- Custom error selector encoded incorrectly.
- The wrong call is reverting first.

Correct order:

```solidity
vm.expectRevert();
target.callThatReverts();
```

[Back to top](#table-of-contents)

---

## 20. Mental Model

Foundry stack:

| Tool | Mental model |
|---|---|
| `forge` | Development: build, test, script, deploy |
| `cast` | Interaction: call, send, encode, decode, inspect |
| `anvil` | Blockchain: local node and forks |
| `chisel` | Experimentation: Solidity REPL |

### One-Line Model

```text
forge = build/test/deploy
cast = talk to chains
anvil = run a chain
chisel = try Solidity quickly
```

### How the Pieces Work Together

Local development:

```bash
anvil
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
cast call <address> "someView()(uint256)" --rpc-url http://127.0.0.1:8545
```

Testing:

```bash
forge test
forge test -vvv
forge test --fork-url $MAINNET_RPC_URL
```

Debugging:

```bash
forge test --match-test testName -vvvv
cast run <tx_hash> --rpc-url $RPC_URL
```

Deployment:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast
```

### Practical Philosophy

Foundry rewards tight feedback loops:

- Write a small contract.
- Write a Solidity test.
- Run `forge test`.
- Add fuzz tests for input space.
- Add invariants for system properties.
- Fork real networks for integrations.
- Simulate before deployment.
- Broadcast only when you know what will happen.

[Back to top](#table-of-contents)

---

## 21. Daily Command Reference

### Project

```bash
forge init my_project
forge build
forge test
forge fmt
forge clean
```

### Tests

```bash
forge test
forge test -vvv
forge test --match-test testName
forge test --match-contract ContractTest
forge test --match-path test/File.t.sol
forge test --gas-report
forge coverage
```

### Dependencies

```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
forge remappings
```

### Scripts

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast
```

### Cast

```bash
cast chain-id --rpc-url $RPC_URL
cast balance <address> --rpc-url $RPC_URL
cast call <address> "owner()(address)" --rpc-url $RPC_URL
cast send <address> "transfer(address,uint256)" <to> <amount> --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast calldata "transfer(address,uint256)" <to> <amount>
cast sig "transfer(address,uint256)"
cast storage <address> <slot> --rpc-url $RPC_URL
cast run <tx_hash> --rpc-url $RPC_URL
```

### Anvil

```bash
anvil
anvil --fork-url $MAINNET_RPC_URL
anvil --fork-url $MAINNET_RPC_URL --fork-block-number <block>
```

### Useful Environment Variables

```bash
export RPC_URL="https://..."
export MAINNET_RPC_URL="https://..."
export PRIVATE_KEY="0x..."
export ETHERSCAN_API_KEY="..."
```

Warning: Do not commit `.env` files or private keys.

[Back to top](#table-of-contents)

---

## 22. Complete Foundry Testing Guide + Video Roadmap

This section turns the tutorial video list into a practical Foundry testing mini-manual. Use it after you understand the main Foundry tools, or follow it from top to bottom as a guided curriculum.

Each topic keeps the same pattern:

- What the topic is.
- Why it matters.
- Core commands or cheatcodes.
- Minimal example.
- Common mistakes.
- Practical testing advice.

### In this section
- [1. Introduction to Testing with Foundry](#1-introduction-to-testing-with-foundry)
- [2. Writing Basic Tests](#2-writing-basic-tests)
- [3. Setting the Solidity Compiler Version](#3-setting-the-solidity-compiler-version)
- [4. Remappings](#4-remappings)
- [5. Auto Format Code](#5-auto-format-code)
- [6. Console Log Debugging](#6-console-log-debugging)
- [7. Authentication / Access Control Testing](#7-authentication--access-control-testing)
- [8. Error and Revert Testing](#8-error-and-revert-testing)
- [9. Event Testing](#9-event-testing)
- [10. Time Testing](#10-time-testing)
- [11. Sending ETH in Tests](#11-sending-eth-in-tests)
- [12. Signature Testing](#12-signature-testing)
- [13. Fork Testing](#13-fork-testing)
- [14. Mainnet Fork Token Setup / Mint 1 Million DAI](#14-mainnet-fork-token-setup--mint-1-million-dai)
- [15. Fuzz Testing](#15-fuzz-testing)
- [16. Deployment Testing / Deploy Smart Contract With Foundry](#16-deployment-testing--deploy-smart-contract-with-foundry)
- [17. Inspecting Storage, Functions and ABI](#17-inspecting-storage-functions-and-abi)
- [18. Cast Wallet Management and Transactions](#18-cast-wallet-management-and-transactions)
- [19. Import Wallet into Foundry Script Using Cast](#19-import-wallet-into-foundry-script-using-cast)
- [Testing Roadmap Summary Table](#testing-roadmap-summary-table)
- [How to Study This Section Efficiently](#how-to-study-this-section-efficiently)

### 1. Introduction to Testing with Foundry

Foundry testing means writing tests in Solidity and running them with `forge test`.

What this is:

- `forge init` creates a Foundry project.
- `forge build` compiles contracts.
- `forge test` runs Solidity test contracts.
- Tests live close to your contracts and can use Solidity types, inheritance, interfaces, events, and custom errors directly.

Why it matters:

- You test contract behavior in the same language as the contracts.
- The feedback loop is fast.
- Cheatcodes let tests control caller, balance, time, block number, forks, storage, signatures, and expected failures.
- The workflow works well for protocol development, audits, and security-focused testing.

Core commands:

```bash
forge init my_project
cd my_project
forge build
forge test
forge test -vvv
```

Minimal example:

```text
my_project/
  src/Counter.sol
  test/Counter.t.sol
  foundry.toml
```

Common mistakes:

- Running tests before installing dependencies.
- Forgetting that only functions starting with `test` are run as tests.
- Expecting JavaScript-style test runners; Foundry tests are Solidity contracts.
- Ignoring failing traces instead of rerunning with `forge test -vvv`.

Practical testing advice:

- Start with deterministic unit tests.
- Add revert tests for every permission and input boundary.
- Add fuzz tests once the simple cases pass.
- Use fork tests for real deployed integrations, not for every unit test.

> Related video: [Introduction | Testing with Foundry](https://www.youtube.com/watch?v=tgs5q-GJmg4)

### 2. Writing Basic Tests

Basic Foundry tests are Solidity contracts stored under `test/`.

What this is:

- Test files commonly end in `.t.sol`.
- Test contracts usually inherit from `forge-std/Test.sol`.
- `setUp()` runs before each test.
- Functions whose names start with `test` are executed by Forge.
- Arrange / Act / Assert keeps tests readable.

Why it matters:

- Clean tests document intended contract behavior.
- A predictable structure makes failures easier to debug.
- `setUp()` prevents repeated deployment and user setup code.

Useful assertions:

- `assertEq(a, b)`  
  Checks that `a` and `b` are equal. Commonly used for balances, counters, addresses, strings, and return values.

- `assertTrue(condition)`  
  Checks that a condition evaluates to `true`.

- `assertFalse(condition)`  
  Checks that a condition evaluates to `false`.

- `assertGt(a, b)`  
  Checks that `a` is greater than `b`.

- `assertLt(a, b)`  
  Checks that `a` is less than `b`.

- `assertGe(a, b)`  
  Checks that `a` is greater than or equal to `b`.

- `assertLe(a, b)`  
  Checks that `a` is less than or equal to `b`.

Example:

```solidity
assertEq(token.totalSupply(), 1_000_000 ether);
assertTrue(vault.paused());
assertFalse(user == owner);
assertGt(address(vault).balance, 0);
assertLt(fee, MAX_FEE);
assertGe(userBalance, depositAmount);
assertLe(protocolFee, maxAllowedFee);
```

Example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter counter;
    address alice;

    function setUp() public {
        counter = new Counter();
        alice = makeAddr("alice");
    }

    function testIncrement() public {
        // Arrange is in setUp().

        // Act.
        counter.increment();

        // Assert.
        assertEq(counter.count(), 1);
        assertTrue(counter.count() > 0);
        assertFalse(counter.count() == 0);
    }
}
```

Good naming makes failures readable:

```solidity
function testDeposit() public {}
function test_RevertWhen_NotOwner() public {}
function testFuzz_Deposit(uint256 amount) public {}
```

Common mistakes:

- Naming a test `shouldDeposit()` instead of `testDeposit()`.
- Making tests depend on state from previous tests; `setUp()` runs fresh for each test.
- Asserting too little, such as only checking that a function does not revert.
- Mixing many behaviors into one large test.

Practical testing advice:

- Use one test for one behavior.
- Use names like `test_DepositUpdatesBalance()` and `test_RevertWhen_CallerNotOwner()`.
- Put repeated users, deployments, and approvals in `setUp()`.
- Prefer explicit assertions over comments explaining what should have happened.

> Related video: [How to Write Basic Tests | Testing with Foundry](https://www.youtube.com/watch?v=HA0GWauMOsU)

### 3. Setting the Solidity Compiler Version

Compiler settings control which Solidity compiler Foundry uses and how bytecode is optimized.

What this is:

- `pragma solidity` defines the compiler range accepted by a Solidity file.
- `solc_version` in `foundry.toml` pins the exact compiler used by Foundry.
- `auto_detect_solc` lets Foundry choose compiler versions based on file pragmas.
- Optimizer settings affect bytecode size, gas costs, and verification.

Why it matters:

- Solidity behavior can differ across versions.
- Production deployments must be reproducible.
- Verification can fail if compiler or optimizer settings do not match deployment.
- Dependencies may use different pragma ranges.

Contract pragma:

```solidity
pragma solidity ^0.8.24;
```

`foundry.toml` pin:

```toml
[profile.default]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
```

Auto-detect compiler versions for mixed projects:

```toml
[profile.default]
auto_detect_solc = true
```

Core commands:

```bash
forge build
forge build --force
forge test
```

Common compiler mismatch problems:

- `Source file requires different compiler version`.
- A dependency has a stricter pragma than your configured `solc_version`.
- Contract verification fails because optimizer settings differ.
- Local tests pass with one compiler but CI uses another.

Common mistakes:

- Assuming `pragma solidity ^0.8.20` means exactly `0.8.20`; it allows newer compatible versions.
- Changing optimizer settings after deployment and expecting verification to still match.
- Using `auto_detect_solc` when the team needs one pinned compiler for all contracts.

Practical testing advice:

- Pin `solc_version` for reproducible builds.
- Use `auto_detect_solc` when working with mixed-version dependencies.
- Keep compiler settings consistent between local development, CI, deployment, and verification.
- Rebuild with `forge clean && forge build` after changing compiler settings.

> Related video: [Set Solidity Compiler Version | Testing with Foundry](https://www.youtube.com/watch?v=bmOxtjzFcbk)

### 4. Remappings

Remappings tell the Solidity compiler how to resolve import aliases.

What this is:

- A remapping maps an import prefix to a local folder.
- Foundry dependencies usually live under `lib/`.
- Remappings can be discovered automatically, stored in `remappings.txt`, or configured in `foundry.toml`.

Why it matters:

- Imports like `forge-std/Test.sol` and `@openzeppelin/contracts/...` are not real absolute paths.
- Without remappings, the compiler cannot find installed libraries.
- Clean remappings keep imports readable and portable.

Example imports:

```solidity
import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```

Install dependencies:

```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
```

Core commands:

```bash
forge remappings
forge remappings > remappings.txt
```

Example remapping:

```text
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
forge-std/=lib/forge-std/src/
```

`foundry.toml` example:

```toml
remappings = [
  "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
  "forge-std/=lib/forge-std/src/"
]
```

Common import errors:

- `File not found`.
- `Source "@openzeppelin/..." not found`.
- Installing a dependency but importing the wrong prefix.
- Having conflicting remappings in `remappings.txt` and `foundry.toml`.

Practical testing advice:

- Run `forge remappings` after installing libraries.
- Keep imports stable across the project.
- Prefer common aliases such as `forge-std/` and `@openzeppelin/contracts/`.
- Use `foundry.toml` when you want config centralized; use `remappings.txt` when you want a simple explicit file.

> Related video: [Remappings | Testing with Foundry](https://www.youtube.com/watch?v=7DK75j8csTA)

### 5. Auto Format Code

`forge fmt` formats Solidity code using Foundry's formatter.

What this is:

- `forge fmt` rewrites Solidity files to a consistent style.
- `forge fmt --check` verifies formatting without changing files.

Why it matters:

- Formatting reduces noisy review comments.
- Consistent style makes test files easier to scan.
- CI formatting checks prevent style drift.

Format files:

```bash
forge fmt
```

Check formatting in CI:

```bash
forge fmt --check
```

Useful workflow:

```bash
forge fmt
forge build
forge test
```

CI example:

```bash
forge fmt --check
forge test
```

Common mistakes:

- Running `forge fmt` in a large branch and mixing formatting-only changes with logic changes.
- Forgetting to run `forge fmt --check` in CI.
- Being surprised when line wrapping changes a lot of code at once.

Practical testing advice:

- Format before committing.
- If a formatting diff is huge, commit formatting separately from behavior changes.
- Run `forge fmt --check` before review so reviewers focus on logic.

> Related video: [Auto Format Code | Testing with Foundry](https://www.youtube.com/watch?v=k55TIWUFLbQ)

### 6. Console Log Debugging

Foundry supports Solidity-side logging through `forge-std/console.sol`.

What this is:

- `console.log` prints values while tests run.
- Logs are shown when tests run with enough verbosity.
- Typed logs help when overloads are awkward.

Why it matters:

- Logs are fast feedback while writing tests.
- They help inspect balances, callers, hashes, signatures, and intermediate math.
- They are simpler than reading a full trace when you only need a few values.

Example:

```solidity
import "forge-std/console.sol";

function testDebugValue() public {
    uint256 x = 42;
    console.log("value:", x);
}
```

Run with enough verbosity:

```bash
forge test -vv
```

Typed logging examples:

```solidity
console.logUint(amount);
console.logAddress(user);
console.logBool(success);
console.logBytes32(hash);
```

Common mistakes:

- Running `forge test` without `-vv` and thinking logs are broken.
- Leaving noisy logs in committed tests.
- Using logs instead of assertions.

Logs vs traces:

- Use logs when you know which values you want to inspect.
- Use `forge test -vvv` for traces when a call stack or revert path is unclear.
- Use `-vvvv` when you need traces for passing tests too.

Practical testing advice:

- Add logs temporarily, then remove them once the assertion is clear.
- For fuzz failures, log bounded inputs and key state transitions.
- Prefer labels with `vm.label(address, "name")` when traces contain many addresses.

> Related video: [Console Log | Testing with Foundry](https://www.youtube.com/watch?v=pO3kfXCFLuE)

### 7. Authentication / Access Control Testing

Access control tests verify that authorized users can perform privileged actions and unauthorized users cannot.

What this is:

- `vm.prank(user)` changes `msg.sender` for the next call.
- `vm.startPrank(user)` changes `msg.sender` until `vm.stopPrank()`.
- `makeAddr("name")` creates readable deterministic test addresses.

Why it matters:

- Most protocol bugs involve the wrong caller being able to do something.
- Owner, role, guardian, operator, and user flows should all be tested separately.
- Revert tests prove unauthorized paths are actually blocked.

Core cheatcodes:

```solidity
address owner = makeAddr("owner");
address alice = makeAddr("alice");

vm.prank(alice);
vm.startPrank(owner);
vm.stopPrank();
```

Use `vm.prank(user)` for one call from a specific user:

```solidity
function test_RevertWhen_NotOwner() public {
    address alice = makeAddr("alice");

    vm.prank(alice);
    vm.expectRevert("Not owner");
    vault.setFee(100);
}
```

Use `vm.startPrank` and `vm.stopPrank` for multi-step flows:

```solidity
function testOwnerFlow() public {
    vm.startPrank(owner);
    vault.setFee(100);
    vault.pause();
    vm.stopPrank();

    assertEq(vault.fee(), 100);
    assertTrue(vault.paused());
}
```

Common mistakes:

- Forgetting `vm.stopPrank()` and accidentally running later calls as the wrong user.
- Using `vm.prank` before a helper function, then expecting it to affect calls inside later test code.
- Only testing that unauthorized users fail, without testing the authorized happy path.
- Testing `tx.origin` behavior by accident; use `msg.sender`-based access control.

Practical testing advice:

- Test the happy path for authorized accounts.
- Test reverts for unauthorized accounts.
- Test role transfer or ownership transfer if the contract supports it.
- Use different addresses for owner, admin, attacker, and normal user.
- Assert both permission failure and unchanged state after failure.

> Related video: [Authentication | Testing with Foundry](https://www.youtube.com/watch?v=gYwO3Jbi4O4)

### 8. Error and Revert Testing

Use `vm.expectRevert` before the call that should fail.

What this is:

- Revert tests prove invalid calls fail for the expected reason.
- `vm.expectRevert()` accepts any revert.
- `vm.expectRevert(bytes)` checks specific revert data.
- Custom errors are checked with selectors and encoded arguments.

Why it matters:

- Permission checks, input validation, deadlines, caps, and paused states are security boundaries.
- A test that only checks the happy path misses the contract's defensive behavior.

Core cheatcodes:

```solidity
vm.expectRevert();
vm.expectRevert("Amount is zero");
vm.expectRevert(MyError.selector);
vm.expectRevert(abi.encodeWithSelector(MyError.selector, arg));
```

Revert string example:

```solidity
function test_RevertWhen_AmountZero() public {
    vm.expectRevert("Amount is zero");
    vault.deposit(0);
}
```

Custom error example:

```solidity
error NotOwner(address caller);

function test_RevertWhen_NotOwnerCustomError() public {
    address alice = makeAddr("alice");

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, alice));
    vault.adminAction();
}
```

Any revert:

```solidity
vm.expectRevert();
target.callThatShouldFail();
```

Common mistakes:

- Placing `vm.expectRevert` after the reverting call.
- Expecting a revert string when the contract uses a custom error.
- Expecting only `MyError.selector` when the error includes arguments and you want to check them.
- Putting another external call between `expectRevert` and the expected failing call.

Practical testing advice:

- Use exact custom error checks for important validation.
- Use any-revert checks only when the reason is irrelevant.
- Test state is unchanged after a failed call if the function protects accounting.
- Put `expectRevert` immediately before the call that should fail.

> Related video: [Error | Testing with Foundry](https://www.youtube.com/watch?v=yY9lL4Jxkd8)

### 9. Event Testing

Use `vm.expectEmit` to verify that a contract emits the expected event.

What this is:

- Events are logs emitted by contracts.
- Indexed event parameters are stored as topics.
- Non-indexed parameters are stored as data.
- `vm.expectEmit` configures which topics and data Foundry should compare.

Why it matters:

- Frontends, subgraphs, indexers, analytics, and off-chain automation often depend on events.
- Event tests catch missing, misordered, or wrong event data.

Core cheatcode:

```solidity
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
```

Event example:

```solidity
event Deposit(address indexed user, uint256 amount);

function testDepositEmits() public {
    vm.expectEmit(true, false, false, true);
    emit Deposit(alice, 1 ether);

    vm.prank(alice);
    vault.deposit{value: 1 ether}();
}
```

`vm.expectEmit` arguments:

```solidity
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
```

Indexed parameters are stored in topics. Non-indexed parameters are stored in event data. For example, `address indexed user` is checked by a topic flag, while `uint256 amount` is checked by the data flag.

Transfer-style example:

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);

function testTransferEmits() public {
    vm.expectEmit(true, true, false, true);
    emit Transfer(alice, bob, 100);

    token.transferFrom(alice, bob, 100);
}
```

Common mistakes:

- Emitting the expected event after the actual call instead of before it.
- Setting topic flags incorrectly for indexed parameters.
- Forgetting event order matters when multiple events are emitted.
- Checking the wrong emitter when multiple contracts emit the same event.

Practical testing advice:

- Test events that external systems rely on.
- Use exact event checks for deposits, withdrawals, transfers, claims, and admin changes.
- Keep event tests small; state assertions should usually live beside event assertions.

> Related video: [Event | Testing with Foundry](https://www.youtube.com/watch?v=GYwKDSSpzjQ)

### 10. Time Testing

Time-dependent contracts need tests for deadlines, vesting, auctions, staking rewards, cooldowns, and timelocks.

What this is:

- `vm.warp(timestamp)` changes `block.timestamp`.
- `vm.roll(blockNumber)` changes `block.number`.
- Tests can simulate time passing without waiting.

Why it matters:

- Time boundaries are common sources of off-by-one bugs.
- Auctions, staking, vesting, cooldowns, deadlines, and timelocks all depend on exact time behavior.

Core cheatcodes:

```solidity
vm.warp(block.timestamp + 1 days);
vm.roll(block.number + 100);
```

Use `vm.warp` to change timestamp:

```solidity
function testClaimAfterVesting() public {
    vm.warp(block.timestamp + 365 days);
    vesting.claim();
}
```

Use `vm.roll` to change block number:

```solidity
function testExecuteAfterBlocks() public {
    vm.roll(block.number + 100);
    timelock.execute();
}
```

Deadline testing pattern:

```solidity
function testDeadlineBoundary() public {
    uint256 deadline = auction.deadline();

    vm.warp(deadline - 1);
    auction.bid{value: 1 ether}();

    vm.warp(deadline);
    vm.expectRevert("ended");
    auction.bid{value: 1 ether}();
}
```

Common mistakes:

- Testing only far before or far after a deadline.
- Forgetting that some contracts use `block.number`, not `block.timestamp`.
- Assuming "at deadline" means allowed; it depends on whether the code uses `<`, `<=`, `>`, or `>=`.
- Warping time without setting up the user balance or approval needed for the action.

Practical testing advice:

- Test just before the deadline.
- Test exactly at the deadline.
- Test after the deadline.
- Test block-based and timestamp-based logic separately.
- For staking or vesting, assert accrued amounts, not only that `claim()` succeeds.

> Related video: [Time | Testing with Foundry](https://www.youtube.com/watch?v=B_3Kax70sF4)

### 11. Sending ETH in Tests

Use `vm.deal` to give ETH to test addresses, then make payable calls with `{value: amount}`.

What this is:

- `vm.deal(user, amount)` sets an address's ETH balance in the test environment.
- Payable calls send ETH with `{value: amount}`.
- `address(contract).balance` checks ETH held by a contract.

Why it matters:

- ETH flows are common in vaults, auctions, mints, refunds, and fee collectors.
- Tests need funded users before they can send ETH.
- Contract balances and internal accounting should stay consistent.

Core cheatcodes and syntax:

```solidity
vm.deal(alice, 10 ether);
vault.deposit{value: 1 ether}();
address(vault).balance;
```

Example:

```solidity
function testDepositEth() public {
    vm.deal(alice, 10 ether);

    uint256 beforeBalance = address(vault).balance;

    vm.prank(alice);
    vault.deposit{value: 1 ether}();

    assertEq(address(vault).balance, beforeBalance + 1 ether);
    assertEq(vault.balanceOf(alice), 1 ether);
}
```

For withdrawals, check both contract and user balances before and after:

```solidity
uint256 aliceBefore = alice.balance;
vm.prank(alice);
vault.withdraw();
assertGt(alice.balance, aliceBefore);
```

Minimal receive example:

```solidity
receive() external payable {}
```

Common mistakes:

- Calling a payable function from an unfunded test address.
- Checking only internal balances and not actual ETH balances.
- Forgetting that sending ETH to a contract requires `receive()` or payable `fallback()` unless calling a payable function.
- Using `transfer` in contracts without considering gas stipend limitations.

Practical testing advice:

- Assert both contract ETH balance and user accounting.
- Test overpayment, zero value, and refund behavior where relevant.
- Use `vm.deal` for simple setup; use realistic deposits when testing full flows.

> Related video: [Send ETH | Testing with Foundry](https://www.youtube.com/watch?v=GuwUC-Wy_B0)

### 12. Signature Testing

Foundry can generate signatures in tests with `vm.sign`. This is useful for ECDSA verification, permits, meta-transactions, off-chain approvals, and replay-protection tests.

What this is:

- `vm.addr(privateKey)` derives an address from a test private key.
- `vm.sign(privateKey, digest)` signs a digest.
- Contracts often verify signatures with `ecrecover` or OpenZeppelin ECDSA helpers.

Why it matters:

- Many protocols use signatures for permits, claims, authorizations, order fills, and gasless actions.
- Signature tests catch digest mismatch bugs.
- Replay protection must be tested, not assumed.

Core cheatcodes:

```solidity
address signer = vm.addr(privateKey);
(uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
```

Example:

```solidity
function testRecoverSigner() public {
    uint256 privateKey = 0xA11CE;
    address signer = vm.addr(privateKey);

    bytes32 digest = keccak256(abi.encodePacked("approve", signer, uint256(1)));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

    address recovered = ecrecover(digest, v, r, s);
    assertEq(recovered, signer);
}
```

Digest styles at a simple level:

- Raw hash signatures sign exactly the `bytes32` digest you give to `vm.sign`.
- Ethereum signed messages add the `"\x19Ethereum Signed Message:\n32"` prefix before recovery.
- EIP-712 typed data signatures sign structured data with a domain separator, usually including `name`, `version`, `chainId`, and `verifyingContract`.

Replay-protection fields to include when appropriate:

- `nonce`
- `chainId`
- `deadline`
- `verifyingContract`
- signed action details such as user, amount, token, recipient, or order ID

Common mistakes:

- Signing `abi.encodePacked(...)` in the test while the contract verifies `abi.encode(...)`.
- Forgetting the Ethereum signed message prefix.
- Forgetting the EIP-712 domain separator.
- Not incrementing or consuming a nonce.
- Testing signature recovery but not testing replay failure.

Practical testing advice:

- Match the exact digest format your contract verifies.
- Include nonce, deadline, chain ID, and verifying contract when appropriate.
- Add replay tests to ensure the same signature cannot be reused.
- Add an expired deadline test and a wrong-signer test.

> Related video: [Signature | Testing with Foundry](https://www.youtube.com/watch?v=cs5IeYqviSQ)

### 13. Fork Testing

Fork testing lets tests run against live chain state while still executing locally.

What this is:

- A fork copies state from an RPC endpoint into your local test execution.
- You can interact with real deployed contracts and token balances.
- Fork state changes are local and temporary.

Why it matters:

- Integrations with real tokens, pools, or protocols often have details mocks miss.
- Fork tests are useful for migration scripts, liquidation flows, router integrations, and token behavior.
- Fixed block numbers make fork tests reproducible.

Core commands and cheatcodes:

CLI fork:

```bash
forge test --fork-url $MAINNET_RPC_URL
```

Cheatcode fork:

```solidity
function setUp() public {
    vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
}
```

Testing against a live token:

```solidity
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

function testMainnetUsdcBalance() public {
    vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    assertGt(usdc.balanceOf(0x55FE002aefF02F77364de339a1292923A15844B8), 0);
}
```

Use a fixed block for reproducibility:

```bash
forge test --fork-url $MAINNET_RPC_URL --fork-block-number 19000000
```

Common mistakes:

- Running fork tests without a fixed block number and getting different results later.
- Using an RPC that does not support the historical block you need.
- Assuming fork tests mutate real mainnet.
- Depending on live balances that can change if the block is not pinned.
- Making every unit test a fork test, which slows the suite.

RPC/archive node issues:

- Recent blocks usually work on standard RPCs.
- Old historical blocks may require an archive node.
- Rate limits can make fork tests flaky in CI.

Practical testing advice:

- Pin `--fork-block-number` for deterministic tests.
- Keep fork tests separate from fast unit tests when possible.
- Use real token addresses and minimal interfaces.
- Cache or configure reliable RPC URLs in CI.

> Related video: [Fork | Testing with Foundry](https://www.youtube.com/watch?v=eKxJZgp9CTg)

### 14. Mainnet Fork Token Setup / Mint 1 Million DAI

Fork tests often need token balances. The "mint 1 million DAI" idea is local fork manipulation only. It does not mint real DAI on mainnet.

What this is:

- You create local test balances on a fork so your integration test can run.
- Common approaches are impersonating a real holder, using a realistic transfer, or manipulating storage locally.
- DAI mainnet address: `0x6B175474E89094C44Da98b954EedeAC495271d0F`.
- DAI uses 18 decimals, so `1_000_000 ether` represents 1,000,000 DAI units.

Why it matters:

- Real integrations need realistic token balances.
- Fork token setup lets you test swaps, deposits, repayments, collateral, and liquidations against deployed contracts.
- Local setup is safer and faster than using a real funded account.

Preferred approach: impersonate a real holder at a fixed fork block.

Example:

```solidity
interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

function testGiveUserDaiOnFork() public {
    vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

    IERC20Like dai = IERC20Like(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address daiWhale = 0x0000000000000000000000000000000000000000; // replace with a real DAI holder
    address alice = makeAddr("alice");

    vm.prank(daiWhale);
    dai.transfer(alice, 1_000_000 ether);

    assertEq(dai.balanceOf(alice), 1_000_000 ether);
}
```

Alternative local-only setup:

- Use `deal(token, user, amount)` if available in your forge-std version and suitable for the token.
- Use storage manipulation only when you understand the token's storage layout.
- Prefer real transfers for integration behavior because hooks, fees, or transfer restrictions may matter.

Common mistakes:

- Thinking fork manipulation affects mainnet.
- Using a placeholder whale address without replacing it.
- Forgetting token decimals.
- Using a whale address that has balance at the latest block but not at your pinned fork block.
- Manipulating storage and bypassing behavior that the integration depends on.

Practical testing advice:

- Replace placeholder addresses with real holder addresses when writing actual fork tests.
- Some tokens have unusual decimals or transfer behavior.
- Storage manipulation can be powerful but is easy to get wrong; prefer realistic flows when possible.
- Fork balance changes are local simulation state only.
- Pin a fork block and record why the chosen holder has enough balance at that block.

> Related video: [Mint 1 Million DAI on Mainnet Fork | Testing with Foundry](https://www.youtube.com/watch?v=I8mzJxMBzs0)

### 15. Fuzz Testing

Any test with parameters becomes a fuzz test. Foundry generates many randomized inputs and tries to find values that break the property.

What this is:

- A test function with parameters is fuzzed automatically.
- `bound(value, min, max)` constrains a generated value into a useful range.
- `vm.assume(condition)` rejects inputs that do not satisfy a condition.
- Fuzz runs can be configured in `foundry.toml`.

Why it matters:

- Fuzzing finds edge cases humans do not naturally write.
- It is especially useful for amounts, ratios, rounding, array lengths, deadlines, and permissions.
- Good fuzz tests assert properties, not just successful execution.

Core tools:

```solidity
function testFuzz_Deposit(uint256 amount) public {}
amount = bound(amount, 1, 100 ether);
vm.assume(user != address(0));
```

`foundry.toml`:

```toml
[profile.default]
fuzz = { runs = 256 }
```

Example:

```solidity
function testFuzz_Deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);

    vm.deal(alice, amount);
    vm.prank(alice);
    vault.deposit{value: amount}();

    assertEq(vault.balanceOf(alice), amount);
}
```

Use `bound` for ranges:

```solidity
amount = bound(amount, 1, 100 ether);
```

Use `assume` for constraints:

```solidity
vm.assume(user != address(0));
```

Meaningful properties:

- Depositing `x` increases user shares by the expected amount.
- Withdrawing cannot return more than the user owns.
- Total accounting equals the sum of user balances.
- A capped value never exceeds the cap.
- Invalid users, zero amounts, and expired deadlines revert.

Common mistakes:

- Fuzzing without meaningful assertions.
- Using `vm.assume` too much, causing many rejected inputs.
- Forgetting to bound values away from impossible or irrelevant ranges.
- Testing behavior that depends on a fixed user while fuzzing arbitrary addresses.

Practical testing advice:

- Start with simple unit tests, then convert important amount tests into fuzz tests.
- Prefer `bound` for numeric ranges.
- Use `vm.assume` for constraints that cannot be expressed cleanly with `bound`.
- When Foundry finds a failing case, add a normal regression test for that exact input if it explains a real bug.

> Related video: [Fuzz | Testing with Foundry](https://www.youtube.com/watch?v=6sMOeuqwk-U)

### 16. Deployment Testing / Deploy Smart Contract With Foundry

Deployment testing verifies that scripts deploy the right contracts with the right constructor arguments, owners, roles, and configuration.

What this is:

- `forge create` deploys one contract directly.
- `forge script` runs a Solidity deployment script.
- Without `--broadcast`, scripts simulate.
- With `--broadcast`, scripts send transactions.

Why it matters:

- Deployment mistakes can permanently misconfigure contracts.
- Scripts should be repeatable, reviewable, and testable.
- Dry runs catch constructor, RPC, gas, and configuration issues before funds are at risk.

Direct deploy:

```bash
forge create src/MyToken.sol:MyToken \
  --rpc-url $RPC_URL \
  --account deployer \
  --constructor-args "My Token" "MTK"
```

Dry run a script:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL
```

Broadcast only after simulation:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Account-based broadcast:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --account deployer \
  --broadcast
```

Verification example:

```bash
forge verify-contract <address> src/Contract.sol:Contract \
  --chain-id <chain_id> \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

Common mistakes:

- Broadcasting to the wrong chain.
- Passing constructor args in the wrong order.
- Deploying with a raw private key exposed in shell history.
- Verifying with compiler settings that do not match the deployment.
- Forgetting to simulate before broadcast.

Deployment safety checklist:

- Correct chain ID.
- Correct owner.
- Correct constructor args.
- Expected deployed addresses logged.
- Simulation succeeds before broadcast.
- Deployer account has enough native token.
- RPC URL points to the intended network.
- Verification settings match compiler and optimizer config.

> Related video: [Deploy Smart Contract With Foundry](https://www.youtube.com/watch?v=AxnvSYxQC5o)

### 17. Inspecting Storage, Functions and ABI

`forge inspect` helps you inspect generated contract metadata without manually digging through `out/`.

What this is:

- `forge inspect` prints ABI, selectors, storage layout, bytecode, deployed bytecode, and other build metadata.
- It reads compiler output generated by Foundry.

Why it matters:

- Frontends need ABIs.
- Low-level integrations need selectors.
- Upgradeable contracts need storage layout review.
- Bytecode checks help with verification and deployment debugging.

Inspect ABI:

```bash
forge inspect src/Counter.sol:Counter abi
```

Inspect function selectors:

```bash
forge inspect src/Counter.sol:Counter methods
```

Inspect storage layout:

```bash
forge inspect src/Counter.sol:Counter storage-layout
```

Inspect bytecode:

```bash
forge inspect src/Counter.sol:Counter bytecode
forge inspect src/Counter.sol:Counter deployedBytecode
```

Common mistakes:

- Inspecting the wrong contract when a file contains multiple contracts.
- Ignoring storage layout changes before upgrading a proxy.
- Confusing creation bytecode with deployed runtime bytecode.
- Copying stale ABI after changing a contract.

Practical testing advice:

- Building frontend ABIs.
- Checking selector names.
- Reviewing upgradeable storage layout.
- Debugging raw storage reads.
- Run `forge build` before inspecting after changes.
- Save ABI outputs only when another tool needs a checked-in artifact.

> Related video: [Print Storage, Functions and ABI with Foundry](https://www.youtube.com/watch?v=puUL_vTrXhA)

### 18. Cast Wallet Management and Transactions

Cast can manage wallets and interact with deployed contracts from the terminal.

What this is:

- `cast wallet import` stores an encrypted local wallet.
- `cast wallet list` shows available local accounts.
- `cast call` performs read-only calls.
- `cast send` sends transactions.
- `--account` uses an imported wallet; `--private-key` passes a raw key directly.

Why it matters:

- Cast is the fastest way to inspect deployed contracts from the terminal.
- Account-based signing reduces repeated private-key exposure.
- Transaction commands are useful for testing deployments, admin actions, and emergency runbooks.

Import a wallet:

```bash
cast wallet import deployer --interactive
```

List wallets:

```bash
cast wallet list
```

Send a transaction:

```bash
cast send <address> "transfer(address,uint256)" <to> <amount> \
  --rpc-url $RPC_URL \
  --account deployer
```

Read a contract:

```bash
cast call <address> "balanceOf(address)(uint256)" <user> --rpc-url $RPC_URL
```

Check chain and balance:

```bash
cast chain-id --rpc-url $RPC_URL
cast balance <address> --rpc-url $RPC_URL
```

Common mistakes:

- Sending to the wrong chain.
- Mixing token decimals and raw integer amounts.
- Pasting private keys into shell history.
- Forgetting that `cast call` does not change state but `cast send` does.

Practical testing advice:

- Confirm chain ID before sending transactions.
- Confirm sender balance.
- Prefer account-based workflows over repeatedly pasting raw private keys.
- Keep production signing flows separate from local testing.
- Use `cast call` to verify state before and after `cast send`.

> Related video: [Manager Wallet and Send Transaction with Foundry Cast](https://www.youtube.com/watch?v=0AugPHQpmKQ)

### 19. Import Wallet into Foundry Script Using Cast

Using Cast-managed wallets can be safer than passing raw private keys directly in shell history or scripts. The `--account` workflow lets Forge use an imported wallet.

What this is:

- `cast wallet import` creates a named encrypted local account.
- `forge script --account <name>` uses that account for signing.
- Solidity scripts still use `vm.startBroadcast()` and `vm.stopBroadcast()`.

Why it matters:

- Raw private keys are easy to leak through shell history, logs, process lists, or committed scripts.
- Named accounts are easier to use consistently across deployment commands.
- The same deployment script can run locally, in staging, and in production with different accounts.

Import:

```bash
cast wallet import deployer --interactive
```

Run script with account:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --account deployer
```

Broadcast with account:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --account deployer \
  --broadcast
```

Contract script still uses normal broadcast flow:

```solidity
function run() external {
    vm.startBroadcast();
    new Contract();
    vm.stopBroadcast();
}
```

Common mistakes:

- Running `forge script --account deployer` without `--broadcast` and wondering why nothing deployed.
- Forgetting `vm.startBroadcast()` inside the script.
- Using the same wallet for local tests, testnets, and production.
- Committing keystore files, passwords, or environment secrets.

Production best practices:

- Use hardware wallets when possible.
- Use multisigs for production ownership and admin actions.
- Separate local, testnet, staging, and production accounts.
- Keep deployment accounts minimally funded.
- Store RPC URLs and non-secret config separately from signing material.

Practical testing advice:

- Do not commit keystore files or passwords.
- Use separate deployer accounts per network.
- Simulate before broadcast.
- Prefer hardware wallets or multisigs for production administration.
- After deployment, immediately check owner, chain ID, deployed code, and critical config.

> Related video: [Import wallet into Foundry script using cast](https://www.youtube.com/watch?v=7HRhRw3vrUI)

### Testing Roadmap Summary Table

| Topic | Main Tool | Core Commands / Cheatcodes | Practical Use | Video |
|---|---|---|---|---|
| Introduction to Testing with Foundry | Forge | `forge init`, `forge build`, `forge test` | Create, compile, and run Solidity-native tests | [Video](https://www.youtube.com/watch?v=tgs5q-GJmg4) |
| Writing Basic Tests | Forge / forge-std | `setUp()`, `assertEq`, `assertTrue`, `assertFalse`, `assertGt`, `assertLt` | Unit test core contract behavior | [Video](https://www.youtube.com/watch?v=HA0GWauMOsU) |
| Setting the Solidity Compiler Version | Forge | `solc_version`, `auto_detect_solc`, optimizer settings | Reproducible builds and verification | [Video](https://www.youtube.com/watch?v=bmOxtjzFcbk) |
| Remappings | Forge | `forge remappings`, `remappings.txt`, `foundry.toml` | Resolve dependency imports | [Video](https://www.youtube.com/watch?v=7DK75j8csTA) |
| Auto Format Code | Forge | `forge fmt`, `forge fmt --check` | Consistent Solidity formatting and CI checks | [Video](https://www.youtube.com/watch?v=k55TIWUFLbQ) |
| Console Log Debugging | Forge / forge-std | `console.log`, `console.logUint`, `forge test -vv` | Inspect values during test debugging | [Video](https://www.youtube.com/watch?v=pO3kfXCFLuE) |
| Authentication / Access Control Testing | Cheatcodes | `makeAddr`, `vm.prank`, `vm.startPrank`, `vm.stopPrank` | Test owner, role, and unauthorized flows | [Video](https://www.youtube.com/watch?v=gYwO3Jbi4O4) |
| Error and Revert Testing | Cheatcodes | `vm.expectRevert`, custom error selectors | Verify invalid calls fail correctly | [Video](https://www.youtube.com/watch?v=yY9lL4Jxkd8) |
| Event Testing | Cheatcodes | `vm.expectEmit` | Verify logs consumed by frontends and indexers | [Video](https://www.youtube.com/watch?v=GYwKDSSpzjQ) |
| Time Testing | Cheatcodes | `vm.warp`, `vm.roll` | Test deadlines, vesting, auctions, staking, cooldowns | [Video](https://www.youtube.com/watch?v=B_3Kax70sF4) |
| Sending ETH in Tests | Cheatcodes | `vm.deal`, payable `{value: amount}` calls | Test deposits, withdrawals, refunds, and balances | [Video](https://www.youtube.com/watch?v=GuwUC-Wy_B0) |
| Signature Testing | Cheatcodes / Solidity | `vm.addr`, `vm.sign`, `ecrecover` | Test permits, claims, orders, and replay protection | [Video](https://www.youtube.com/watch?v=cs5IeYqviSQ) |
| Fork Testing | Forge / Cheatcodes | `forge test --fork-url`, `vm.createSelectFork` | Test real deployed integrations locally | [Video](https://www.youtube.com/watch?v=eKxJZgp9CTg) |
| Mainnet Fork Token Setup / Mint 1 Million DAI | Fork tests | `vm.prank`, local fork token setup, realistic transfers | Give local fork users token balances for integration tests | [Video](https://www.youtube.com/watch?v=I8mzJxMBzs0) |
| Fuzz Testing | Forge | Parameterized tests, `bound`, `vm.assume`, fuzz runs | Find edge cases across many inputs | [Video](https://www.youtube.com/watch?v=6sMOeuqwk-U) |
| Deployment Testing / Deploy Smart Contract With Foundry | Forge scripts | `forge create`, `forge script`, `--broadcast`, `forge verify-contract` | Simulate and broadcast deployments | [Video](https://www.youtube.com/watch?v=AxnvSYxQC5o) |
| Inspecting Storage, Functions and ABI | Forge | `forge inspect ... abi`, `methods`, `storage-layout`, `bytecode` | Review ABI, selectors, bytecode, and upgrade storage | [Video](https://www.youtube.com/watch?v=puUL_vTrXhA) |
| Cast Wallet Management and Transactions | Cast | `cast wallet import`, `cast wallet list`, `cast call`, `cast send` | Read state and send transactions from the terminal | [Video](https://www.youtube.com/watch?v=0AugPHQpmKQ) |
| Import Wallet into Foundry Script Using Cast | Cast / Forge scripts | `--account`, `cast wallet import`, `vm.startBroadcast()` | Run deployment scripts without raw private keys | [Video](https://www.youtube.com/watch?v=7HRhRw3vrUI) |

### How to Study This Section Efficiently

Recommended order:

1. Basic tests: learn `test/`, `Test.sol`, `setUp()`, assertions, and arrange / act / assert.
2. Core cheatcodes: practice `prank`, `deal`, `warp`, `expectRevert`, and `expectEmit`.
3. Fuzz testing: convert amount and boundary tests into parameterized tests with meaningful assertions.
4. Fork testing: pin a block and test one real token or protocol integration.
5. Scripts and deployment: dry run scripts before broadcasting, then verify config and ownership.
6. Cast wallet and transactions: use `cast call` for reads, `cast send` for writes, and `--account` for safer signing.
7. Inspect/debug tools: use `console.log`, traces, and `forge inspect` when behavior is unclear.

Best study loop:

```bash
forge test
forge test -vvv
forge fmt --check
forge inspect src/Counter.sol:Counter methods
```

Build confidence in layers. First prove simple behavior, then reverts, then events, then edge cases, then real integration assumptions on a fork.

[Back to top](#table-of-contents)

---

## Final Study Tips

- Learn `forge test -vvv` early. Traces make Solidity debugging much less mysterious.
- Use cheatcodes to model real users, time, balances, and expected failures.
- Fuzz anything that accepts user-controlled numeric input.
- Add invariants for accounting systems, vaults, lending protocols, staking systems, and tokens.
- Use Anvil forks before trusting integrations.
- Use Cast constantly; it turns the terminal into an Ethereum workbench.
- Simulate deployments before broadcasting.
- Keep production keys far away from casual local testing.

[Back to top](#table-of-contents)
