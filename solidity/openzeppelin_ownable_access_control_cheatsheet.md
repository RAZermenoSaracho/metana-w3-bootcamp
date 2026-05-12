# OpenZeppelin Ownable & AccessControl Cheatsheet

> A practical guide to ownership, two-step ownership, and role-based access control in Solidity using OpenZeppelin.

---

## How to Use This Cheatsheet

- Use this when deciding who should be allowed to call sensitive functions.
- Use the examples as small patterns, not full production systems.
- Prefer OpenZeppelin implementations over writing access control from scratch.
- Test both authorized and unauthorized users.

Security warning: access control bugs are often catastrophic. A missing modifier can mean unlimited minting, stolen treasury funds, broken upgrades, or permanent protocol takeover.

---

## Table of Contents

- [1. Access Control Mental Model](#1-access-control-mental-model)
- [2. Ownable](#2-ownable)
- [3. Ownable2Step](#3-ownable2step)
- [4. AccessControl](#4-accesscontrol)
- [5. Ownable vs Ownable2Step vs AccessControl](#5-ownable-vs-ownable2step-vs-accesscontrol)
- [6. Best Practices for Admin Accounts](#6-best-practices-for-admin-accounts)
- [7. Testing Access Control with Foundry](#7-testing-access-control-with-foundry)
- [8. Common Access Control Vulnerabilities](#8-common-access-control-vulnerabilities)
- [9. Audit Checklist](#9-audit-checklist)
- [10. Mental Models](#10-mental-models)
- [11. Recommended Learning Exercises](#11-recommended-learning-exercises)

---

## 1. Access Control Mental Model

Access control means deciding who is allowed to call a function.

Smart contracts are public by default. Anyone can see them, call public/external functions, build bots around them, and compose them with other contracts. If a function changes critical state, the contract must explicitly restrict who can call it.

### Function Categories

| Type | Meaning | Example |
|---|---|---|
| Public function | Anyone can call it | `deposit()`, `transfer()` |
| Permissioned function | Only approved users can call it | `mint()` with `MINTER_ROLE` |
| Admin-only function | Only owner/admin can call it | `setFee()` |
| Role-based function | Caller needs a specific role | `pause()` with `PAUSER_ROLE` |

### Privileged Actions

These usually need access control:

- Minting tokens.
- Pausing or unpausing contracts.
- Upgrading contracts.
- Changing fees.
- Withdrawing treasury funds.
- Setting oracle addresses.
- Setting routers, bridges, or external integrations.
- Granting or revoking roles.
- Emergency rescue functions.

### Why Access Control Bugs Are Critical

If the wrong person can call a privileged function, they may be able to:

- Mint unlimited tokens.
- Drain funds.
- Pause the protocol forever.
- Upgrade to malicious code.
- Change an oracle to manipulate prices.
- Grant themselves more permissions.

Core question:

> Who is allowed to call this function, and what happens if the wrong person can call it?

### Practical Rule

For every external/public function, ask:

- Does it change important state?
- Does it move funds?
- Does it change permissions?
- Does it affect pricing, accounting, or upgrades?
- Should this be public, owner-only, or role-gated?

[Back to top](#table-of-contents)

---

## 2. Ownable

`Ownable` is OpenZeppelin's simplest ownership pattern. One address is the owner, and functions can be restricted with `onlyOwner`.

### What Ownable Is

`Ownable` gives your contract:

- `owner()`: returns the current owner.
- `onlyOwner`: modifier that restricts a function to the owner.
- `transferOwnership(newOwner)`: moves ownership to another address.
- `renounceOwnership()`: sets owner to `address(0)`.

OpenZeppelin Contracts v5 uses constructor owner setup:

```solidity
constructor() Ownable(msg.sender) {}
```

### How onlyOwner Works

This:

```solidity
function setFee(uint256 newFee) external onlyOwner {
    feeBps = newFee;
}
```

means:

```text
if msg.sender != owner, revert
```

### Minimal Ownable Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {
    uint256 public feeBps;

    constructor() Ownable(msg.sender) {}

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 1_000, "fee too high");
        feeBps = newFeeBps;
    }
}
```

### onlyOwner Protected Function Example

```solidity
contract Treasury is Ownable {
    constructor() payable Ownable(msg.sender) {}

    function emergencyWithdraw(address payable to) external onlyOwner {
        require(to != address(0), "zero address");
        to.transfer(address(this).balance);
    }
}
```

Security note: emergency withdraw functions are powerful. They should be owner-only, tested, documented, and ideally controlled by a multisig in production.

### Transferring Ownership

```solidity
contract AdminExample is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}
}
```

Usage:

```solidity
adminExample.transferOwnership(newOwner);
```

After this call:

- `owner()` becomes `newOwner`.
- The old owner loses `onlyOwner` permission.
- The new owner does not need to accept in plain `Ownable`.

### Dangerous renounceOwnership Example

```solidity
function disableAdminForever() external onlyOwner {
    renounceOwnership();
}
```

After renouncing:

```text
owner() == address(0)
```

Any `onlyOwner` function becomes impossible to call.

This may be intentional for immutable systems. It is dangerous if the protocol still needs:

- Pausing.
- Upgrades.
- Emergency recovery.
- Fee changes.
- Oracle updates.

### When Ownable Is Enough

Use `Ownable` when:

- The contract is simple.
- There is only one admin.
- Admin powers are limited.
- You are building a learning project or internal tool.
- The owner will be a multisig for production.

Common use cases:

- Simple admin controls.
- Setting config values.
- Pausing/unpausing.
- Emergency withdraws.
- Managing allowlists in small projects.

### When Ownable Is Too Simple

`Ownable` may be too simple when:

- Multiple teams need different permissions.
- One account should mint but not upgrade.
- One account should pause but not withdraw funds.
- Treasury, operations, and upgrades should be separate.
- You need independent grant/revoke flows.

Use `AccessControl` when permissions need separation.

### Security Concerns

- Single admin key risk.
- Accidental `renounceOwnership()`.
- Transferring ownership to the wrong address.
- Transferring ownership to a contract that cannot manage it.
- Using a personal EOA instead of a multisig.
- Owner compromise means all owner powers are compromised.

### Common Mistakes

- Forgetting `onlyOwner` on sensitive functions.
- Using `tx.origin` instead of `msg.sender`.
- Deploying with the wrong initial owner.
- Renouncing ownership before the system is truly immutable.
- Assuming ownership transfer requires acceptance. Plain `Ownable` does not.
- Giving ownership to an EOA for production.

### Ownable Audit Checklist

- Who is the initial owner?
- Is the owner expected to be an EOA, multisig, or timelock?
- Does every sensitive function use `onlyOwner`?
- Is `renounceOwnership()` acceptable for this system?
- Could ownership be transferred to the wrong address?
- Are owner-only functions tested for authorized and unauthorized callers?
- Are owner powers documented?
- Can the owner drain funds, mint tokens, change fees, or upgrade?

[Back to top](#table-of-contents)

---

## 3. Ownable2Step

`Ownable2Step` is a safer ownership pattern where the new owner must accept ownership.

### What Ownable2Step Is

Plain `Ownable.transferOwnership(newOwner)` changes ownership immediately.

`Ownable2Step` uses a two-step flow:

1. Current owner calls `transferOwnership(newOwner)`.
2. Pending owner calls `acceptOwnership()`.

The contract also exposes:

- `owner()`: current owner.
- `pendingOwner()`: address that can accept ownership.
- `acceptOwnership()`: completes the transfer.

### Why It Is Safer

Two-step ownership helps prevent:

- Transferring ownership to the wrong address.
- Transferring ownership to an address no one controls.
- Transferring ownership to a contract that cannot call admin functions.

The old owner remains owner until the pending owner accepts.

### Minimal Ownable2Step Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProductionAdmin is Ownable2Step {
    uint256 public feeBps;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 1_000, "fee too high");
        feeBps = newFeeBps;
    }
}
```

Note: `Ownable2Step` inherits from `Ownable`, so the constructor calls `Ownable(initialOwner)`.

### Ownership Transfer Flow

```solidity
// Step 1: current owner starts transfer.
contractInstance.transferOwnership(newOwner);

// owner() is still old owner.
// pendingOwner() is newOwner.

// Step 2: pending owner accepts.
contractInstance.acceptOwnership();

// owner() is now newOwner.
```

### When to Prefer Ownable2Step

Use `Ownable2Step` when:

- The contract is production-facing.
- Ownership mistakes would be dangerous.
- Ownership may move to a multisig.
- Admin powers include upgrades, treasury, pausing, or oracle changes.
- You want a safer handoff process.

### Security Benefits and Limitations

Benefits:

- Prevents immediate accidental ownership loss.
- Forces new owner to prove it can call the contract.
- Works well with multisig handoffs.

Limitations:

- Still only one owner.
- Does not separate permissions.
- Pending owner must remember to call `acceptOwnership()`.
- If the current owner is compromised, attacker can still start transfers and use owner powers.

### Common Mistakes

- Forgetting to call `acceptOwnership()`.
- Assuming ownership changed immediately after `transferOwnership()`.
- Transferring to a contract that cannot call `acceptOwnership()`.
- Not checking `pendingOwner()` during admin handoff.
- Using `Ownable2Step` when multiple roles are actually needed.

### Ownable2Step Audit Checklist

- Is `Ownable2Step` used for production owner handoffs?
- Is the initial owner correct?
- Does the pending owner have a way to call `acceptOwnership()`?
- Are tests checking `owner()` before and after acceptance?
- Are tests checking `pendingOwner()`?
- Is ownership transfer documented for operations?
- Should this system use roles instead of one owner?

[Back to top](#table-of-contents)

---

## 4. AccessControl

`AccessControl` is OpenZeppelin's role-based permission system.

### What AccessControl Is

Instead of one owner, contracts define roles.

Example roles:

- `MINTER_ROLE`
- `BURNER_ROLE`
- `PAUSER_ROLE`
- `UPGRADER_ROLE`
- `TREASURER_ROLE`

Each role is a `bytes32` identifier:

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```

### Core AccessControl API

| Function / value | Purpose |
|---|---|
| `DEFAULT_ADMIN_ROLE` | Admin role for roles by default |
| `onlyRole(ROLE)` | Restricts a function to callers with `ROLE` |
| `grantRole(ROLE, account)` | Grants a role |
| `revokeRole(ROLE, account)` | Revokes a role |
| `renounceRole(ROLE, account)` | Caller gives up their own role |
| `_grantRole(ROLE, account)` | Internal role grant, often used in constructor |
| `_revokeRole(ROLE, account)` | Internal role revoke |
| `hasRole(ROLE, account)` | Checks whether account has role |
| `getRoleAdmin(ROLE)` | Returns which role administers a role |

### DEFAULT_ADMIN_ROLE

`DEFAULT_ADMIN_ROLE` is very powerful.

By default:

- It is the admin of every role.
- It can grant roles.
- It can revoke roles.
- It is also its own admin.

Security warning: treat `DEFAULT_ADMIN_ROLE` like a super admin. In production, it should usually be a multisig or timelock, not a personal EOA.

### Minimal AccessControl Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleExample is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public value;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function setValue(uint256 newValue) external onlyRole(MANAGER_ROLE) {
        value = newValue;
    }
}
```

### Token Minter Role Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MintableToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin) ERC20("Example Token", "EXT") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

### Pauser Role Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract PausableVault is AccessControl, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function deposit() external payable whenNotPaused {
        // deposit logic
    }
}
```

### Granting and Revoking Roles

```solidity
contract RoleAdminExample is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function addMinter(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function removeMinter(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }
}
```

### Checking Roles with hasRole

```solidity
function canMint(address account) external view returns (bool) {
    return hasRole(MINTER_ROLE, account);
}
```

Use `hasRole` for reads and UI checks. Use `onlyRole` to enforce permissions.

### Role Admin Relationships

Every role has an admin role. The admin role controls who can grant or revoke that role.

Default:

```text
DEFAULT_ADMIN_ROLE administers every role.
```

You can create separate admin roles for better separation:

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");

constructor(address admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_ADMIN_ROLE, admin);
    _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
}
```

Now `MINTER_ADMIN_ROLE` manages `MINTER_ROLE`.

### When AccessControl Is Better Than Ownable

Use `AccessControl` when:

- Multiple permissions are needed.
- Different teams/users should manage different functions.
- Roles need to be granted and revoked independently.
- The protocol has minting, pausing, treasury, upgrades, or operations roles.

### How Roles Separate Responsibilities

Example:

| Role | Can do | Cannot do |
|---|---|---|
| `MINTER_ROLE` | Mint tokens | Upgrade contract |
| `PAUSER_ROLE` | Pause system | Withdraw treasury |
| `TREASURER_ROLE` | Move treasury funds | Mint tokens |
| `UPGRADER_ROLE` | Upgrade implementation | Change oracle |
| `DEFAULT_ADMIN_ROLE` | Manage roles | Should not do daily ops |

### Security Risks

- `DEFAULT_ADMIN_ROLE` is very powerful.
- Admin roles can grant/revoke roles.
- Bad role hierarchy can centralize too much power.
- Giving too many roles to one account creates key risk.
- Forgetting to assign admin roles can lock role management.
- Losing the only admin can make roles unrecoverable.
- Role holders may be EOAs with weak operational security.

### Common Mistakes

- Granting `DEFAULT_ADMIN_ROLE` to many accounts.
- Forgetting to grant a needed role in the constructor.
- Using `_grantRole` in public functions instead of protected admin flows.
- Thinking `hasRole` protects a function by itself.
- Using one role for everything.
- Not testing role revocation.

### AccessControl Audit Checklist

- Which roles exist?
- Who has each role?
- Which role administers each role?
- Is `DEFAULT_ADMIN_ROLE` controlled by a multisig or timelock?
- Can role admins grant themselves dangerous permissions?
- Are role grants and revokes tested?
- Are unauthorized callers tested?
- Is any sensitive function missing `onlyRole`?
- Are role events emitted through standard `grantRole`/`revokeRole`?
- Is there a recovery plan if an admin key is lost?

[Back to top](#table-of-contents)

---

## 5. Ownable vs Ownable2Step vs AccessControl

### Comparison Table

| Feature | Ownable | Ownable2Step | AccessControl |
|---|---|---|---|
| Simplicity | Very simple | Simple | More complex |
| Safety | Basic | Safer owner transfer | Depends on role design |
| Flexibility | Low | Low | High |
| Best use case | One admin, simple contract | One admin, production handoff | Multiple independent permissions |
| Number of admins | One owner | One owner plus pending owner during transfer | Many role holders |
| Role separation | No | No | Yes |
| Production suitability | Okay if owner is multisig and powers are limited | Better for production ownership | Best for complex protocols |
| Common risks | Wrong owner, renounce, single key | Pending owner never accepts | Bad role hierarchy, overpowered admin |

### Use Ownable When

- The contract is simple.
- There is only one admin.
- Admin powers are limited.
- It is a learning project or simple internal tool.
- You do not need separate minter, pauser, treasury, or upgrader roles.

### Use Ownable2Step When

- Ownership mistakes would be dangerous.
- The contract is production-facing.
- Ownership may be transferred to a multisig.
- You want safer ownership transfer.
- You still only need one admin.

### Use AccessControl When

- Multiple permissions are needed.
- Different teams/users should manage different functions.
- Roles need to be granted/revoked independently.
- The protocol has minting, pausing, treasury, upgrades, or operations roles.
- You need cleaner separation of responsibilities.

### Practical Decision Rule

```text
One simple admin?                  Ownable
One admin but safer handoff?       Ownable2Step
Many permissions or teams?         AccessControl
```

[Back to top](#table-of-contents)

---

## 6. Best Practices for Admin Accounts

Admin account design is part of smart contract security.

### Practical Best Practices

- Avoid using a personal EOA for production ownership.
- Prefer multisig wallets for admin roles.
- Use hardware wallets for sensitive keys.
- Separate roles by responsibility.
- Do not give `DEFAULT_ADMIN_ROLE` to too many accounts.
- Document who owns each role.
- Test admin flows.
- Test unauthorized access.
- Emit events for admin changes.
- Think about emergency recovery.
- Think carefully before renouncing ownership or roles.

### Recommended Production Pattern

| Permission | Recommended holder |
|---|---|
| Owner / upgrade admin | Multisig or timelock |
| `DEFAULT_ADMIN_ROLE` | Multisig or timelock |
| `PAUSER_ROLE` | Multisig plus limited emergency operator |
| `MINTER_ROLE` | Controlled minter contract or multisig |
| `TREASURER_ROLE` | Treasury multisig |
| Daily operations role | Limited hot wallet if necessary |

### Security Notes

- A multisig reduces single-key risk but does not remove governance risk.
- A timelock gives users time to react to dangerous changes.
- Hot wallets should have limited permissions.
- Admin powers should be as narrow as possible.
- Every role holder is part of the threat model.

[Back to top](#table-of-contents)

---

## 7. Testing Access Control with Foundry

Access control should be tested from both sides:

- Authorized users can call protected functions.
- Unauthorized users revert.

Useful Foundry cheatcodes:

- `vm.prank(user)`: next call is from `user`.
- `vm.startPrank(user)`: all calls are from `user` until `vm.stopPrank()`.
- `vm.expectRevert(...)`: next call must revert.

### Example Contract Under Test

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AdminTarget is Ownable2Step, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public value;

    constructor(address admin) Ownable(admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function ownerSetValue(uint256 newValue) external onlyOwner {
        value = newValue;
    }

    function managerSetValue(uint256 newValue) external onlyRole(MANAGER_ROLE) {
        value = newValue;
    }
}
```

### onlyOwner Success Test

```solidity
function testOwnerCanSetValue() public {
    vm.prank(owner);
    target.ownerSetValue(123);

    assertEq(target.value(), 123);
}
```

### onlyOwner Revert Test

OpenZeppelin v5 uses custom errors:

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

function testNonOwnerCannotSetValue() public {
    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
    target.ownerSetValue(123);
}
```

### Ownable2Step Transfer + Accept Test

```solidity
function testTwoStepOwnershipTransfer() public {
    vm.prank(owner);
    target.transferOwnership(alice);

    assertEq(target.owner(), owner);
    assertEq(target.pendingOwner(), alice);

    vm.prank(alice);
    target.acceptOwnership();

    assertEq(target.owner(), alice);
    assertEq(target.pendingOwner(), address(0));
}
```

### AccessControl grantRole Test

```solidity
function testAdminCanGrantManagerRole() public {
    bytes32 role = target.MANAGER_ROLE();

    vm.prank(owner);
    target.grantRole(role, alice);

    assertTrue(target.hasRole(role, alice));
}
```

### AccessControl Unauthorized Role Revert Test

```solidity
import "@openzeppelin/contracts/access/IAccessControl.sol";

function testUserWithoutRoleCannotSetValue() public {
    bytes32 role = target.MANAGER_ROLE();

    vm.prank(alice);
    vm.expectRevert(
        abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            role
        )
    );
    target.managerSetValue(999);
}
```

### Revoke Role Test

```solidity
function testRevokedRoleCannotCall() public {
    bytes32 role = target.MANAGER_ROLE();

    vm.startPrank(owner);
    target.grantRole(role, alice);
    target.revokeRole(role, alice);
    vm.stopPrank();

    assertFalse(target.hasRole(role, alice));
}
```

### Practical Testing Advice

- Test every sensitive function with authorized and unauthorized callers.
- Test ownership transfer before and after acceptance.
- Test role grants and revokes.
- Test that revoked users lose permission.
- Test that the wrong role cannot call the function.
- Test zero address and invalid config where relevant.

[Back to top](#table-of-contents)

---

## 8. Common Access Control Vulnerabilities

### Missing Access Modifier

Mistake:

```solidity
function mint(address to, uint256 amount) external {
    _mint(to, amount);
}
```

Impact:

- Anyone can mint unlimited tokens.

Mitigation:

```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(to, amount);
}
```

### Wrong Role on Function

Mistake:

```solidity
function upgradeTo(address impl) external onlyRole(PAUSER_ROLE) {
    _upgradeTo(impl);
}
```

Impact:

- A pauser can upgrade the protocol.

Mitigation:

- Use a dedicated `UPGRADER_ROLE`.
- Test that each role can only call intended functions.

### Using tx.origin for Authorization

Mistake:

```solidity
require(tx.origin == owner(), "not owner");
```

Impact:

- Phishing contracts can trick the owner into calling a malicious intermediary.

Mitigation:

- Use `msg.sender`.
- Use `onlyOwner` or `onlyRole`.

### Overly Powerful Admin

Mistake:

- One hot wallet has owner, minter, pauser, upgrader, and treasury permissions.

Impact:

- One compromised key can take over the whole protocol.

Mitigation:

- Use multisigs.
- Separate roles.
- Give hot wallets limited permissions.

### Forgotten Initializer in Upgradeable Contracts

Mistake:

- Upgradeable implementation or proxy is deployed without initializing ownership/roles.

Impact:

- An attacker may initialize the contract and become owner/admin.

Mitigation:

- Use OpenZeppelin upgradeable initializers correctly.
- Disable initializers on implementation contracts.
- Test deployment scripts.

### Ownership Transferred to Wrong Address

Mistake:

```solidity
transferOwnership(wrongAddress);
```

Impact:

- Admin control may be lost or given to an attacker.

Mitigation:

- Use `Ownable2Step`.
- Verify addresses before transactions.
- Transfer to multisigs carefully.

### Renouncing Ownership Too Early

Mistake:

- Owner renounces before final config is complete.

Impact:

- Protocol may lose ability to pause, upgrade, recover, or fix config.

Mitigation:

- Renounce only when immutability is intended.
- Test system behavior after renounce.
- Document which functions become unusable.

### Role Admin Misconfiguration

Mistake:

- No account can administer a critical role.
- A low-trust role administers a high-trust role.

Impact:

- Roles may become unrecoverable or too easy to abuse.

Mitigation:

- Review `getRoleAdmin(role)`.
- Use dedicated admin roles.
- Test grant/revoke paths.

### Public Function That Should Be Internal

Mistake:

```solidity
function updateAccounting(address user) public {
    balances[user] = 0;
}
```

Impact:

- Anyone can call internal maintenance logic.

Mitigation:

- Use `internal` for helper functions.
- Use access modifiers for external admin functions.

### Upgrade Functions Without Proper Access Control

Mistake:

```solidity
function upgradeTo(address newImplementation) external {
    _upgradeTo(newImplementation);
}
```

Impact:

- Anyone can upgrade to malicious code.

Mitigation:

```solidity
function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
{}
```

[Back to top](#table-of-contents)

---

## 9. Audit Checklist

Use this checklist on every contract review.

### Sensitive Function Review

- Does every sensitive function have the right modifier?
- Can any public function change critical state?
- Who can mint?
- Who can burn?
- Who can pause?
- Who can unpause?
- Who can upgrade?
- Who can withdraw funds?
- Who can change fees?
- Who can change oracle addresses?
- Who can change routers, bridges, or external integrations?
- Who can grant or revoke roles?

### Ownership Review

- Is the initial owner correct?
- Is ownership transferable safely?
- Should `Ownable2Step` be used?
- Is `renounceOwnership()` acceptable?
- What breaks after renouncing ownership?
- Is owner a multisig or personal EOA?

### Role Review

- Is `DEFAULT_ADMIN_ROLE` controlled safely?
- Are role admin relationships correct?
- Can a low-trust role grant itself high-trust permissions?
- Are too many roles assigned to one account?
- Is there a recovery plan if an admin key is lost?
- Are role grants and revokes visible through events?

### Testing Review

- Are access control tests included?
- Are unauthorized callers tested?
- Are authorized callers tested?
- Are ownership transfers tested?
- Is the `Ownable2Step` accept flow tested?
- Are `grantRole`, `revokeRole`, and `renounceRole` tested?
- Are deployment scripts assigning correct owners and roles?

[Back to top](#table-of-contents)

---

## 10. Mental Models

- `Ownable` = one admin key.
- `Ownable2Step` = one admin key with safer handoff.
- `AccessControl` = many permissions split by role.
- `DEFAULT_ADMIN_ROLE` = super admin.
- `onlyOwner` / `onlyRole` = function gate.
- Admin mistake = protocol risk.
- Hot wallet role = assume it can be compromised.
- Multisig = better key management, not magic security.
- Renounce = burn the admin key.
- Upgrade permission = permission to change the rules.

Practical intuition:

```text
Access control is not just "who can call this?"
It is "who can change the system's rules, money, and safety controls?"
```

[Back to top](#table-of-contents)

---

## 11. Recommended Learning Exercises

1. Create a simple `Ownable` vault with `onlyOwner` emergency withdraw.
2. Convert it to `Ownable2Step`.
3. Add a pauser role using `AccessControl`.
4. Add a minter role to an ERC20 token.
5. Write Foundry tests for authorized and unauthorized calls.
6. Test role revocation.
7. Test what happens after renouncing ownership.
8. Build an audit checklist for your own contract.

Suggested study order:

1. Build with `Ownable`.
2. Replace it with `Ownable2Step`.
3. Add one role with `AccessControl`.
4. Add role revocation tests.
5. Review every privileged function and write down who can call it.

Final rule:

> Access control should be boring, explicit, tested, and easy to explain.

[Back to top](#table-of-contents)
