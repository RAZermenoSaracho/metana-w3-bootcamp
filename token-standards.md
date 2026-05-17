# Token Standards

Token standards are shared rules that smart contracts follow so wallets, exchanges, marketplaces, games, block explorers, and DeFi protocols can interact with tokens in a predictable way.

Without standards, every token would have a different API. Wallets would need custom code for every project. Exchanges would need custom integrations for every asset. Standards turn tokens into a common language.

---

## Table of Contents

### Foundations
- [1. Why Token Standards Exist](#1-why-token-standards-exist)
- [2. ERC20](#2-erc20)
- [3. ERC721](#3-erc721)
- [4. ERC1155 Intro](#4-erc1155-intro)
- [5. ERC1155](#5-erc1155)
- [6. Comparison Tables](#6-comparison-tables)
- [7. Common Token Standard Mistakes](#7-common-token-standard-mistakes)
- [8. Interview Tips](#8-interview-tips)
- [9. Key Takeaways](#9-key-takeaways)

---

## 1. Why Token Standards Exist

### Mental Model

A token standard is like a power outlet shape.

If every house had a different outlet shape, every device would need a custom plug. Because outlets are standardized, many devices can plug into many buildings.

ERC standards do the same for smart contracts:

- Wallets know how to show balances.
- DEXs know how to move tokens.
- Marketplaces know how to display NFTs.
- Games know how to transfer inventory items.
- Block explorers know how to index events.

### What ERC Means

ERC means Ethereum Request for Comments. It is a proposal format for Ethereum application standards. ERC20, ERC721, and ERC1155 are three of the most important token standards.

| Standard | Main Use | Token Type |
|---|---|---|
| ERC20 | Currencies, governance tokens, stablecoins | Fungible |
| ERC721 | Unique NFTs, collectibles, one-of-one assets | Non-fungible |
| ERC1155 | Game items, editions, mixed token systems | Multi-token |

---

## 2. ERC20

ERC20 is the standard interface for fungible tokens on Ethereum.

### What Problem ERC20 Solves

Before ERC20, each token contract could expose different function names:

```solidity
sendCoin(address to, uint256 amount)
moveTokens(address user, uint256 value)
transferBalance(address receiver, uint256 tokens)
```

That would make integrations painful. A wallet would not know which function to call.

ERC20 standardizes the minimum API:

```solidity
transfer(address to, uint256 amount)
approve(address spender, uint256 amount)
transferFrom(address from, address to, uint256 amount)
balanceOf(address account)
allowance(address owner, address spender)
totalSupply()
```

### Fungible Tokens Explained Simply

Fungible means each unit is interchangeable with another unit of the same token.

Mental model:

- 1 USDC in your wallet is equivalent to 1 USDC in my wallet.
- A $10 bill can be swapped for another $10 bill.
- One token unit does not have a unique identity.

ERC20 tokens are good for:

- Stablecoins like USDC and DAI.
- Wrapped assets like WETH.
- Governance tokens.
- Reward points.
- In-game currencies.
- Protocol shares or accounting units.

### Why Standards Matter

Because ERC20 exists:

- MetaMask can display token balances.
- Uniswap can trade unknown ERC20 tokens if liquidity exists.
- Aave can accept supported ERC20 deposits.
- Bridges can lock and mint ERC20 representations.
- Block explorers can show transfer history from events.

The standard makes composability possible. Composability means contracts can plug into each other like reusable building blocks.

### ERC20 Interface

```solidity
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

### Core ERC20 Functions

#### `totalSupply`

Returns the total number of token units that currently exist.

```solidity
uint256 supply = token.totalSupply();
```

If a token can mint or burn, `totalSupply` changes over time.

#### `balanceOf`

Returns how many token units an address owns.

```solidity
uint256 aliceBalance = token.balanceOf(alice);
```

This is a read-only view into the token contract's internal accounting.

Mental model:

```text
ERC20 contract ledger

Alice   -> 100 tokens
Bob     ->  50 tokens
DEX     -> 900 tokens
```

The token does not live inside Alice's wallet. The token contract stores a mapping that says Alice has a balance.

#### `transfer`

Moves tokens from `msg.sender` to another address.

```solidity
token.transfer(bob, 10e18);
```

Equivalent idea:

```text
Alice calls transfer(Bob, 10)

Alice balance: 100 -> 90
Bob balance:    50 -> 60
```

`transfer` is used when the token owner directly sends their own tokens.

#### `approve`

Gives another address permission to spend up to a certain amount of your tokens.

```solidity
token.approve(uniswapRouter, 100e18);
```

This does not move tokens. It only creates permission.

Mental model:

```text
Alice says:
"Uniswap Router may spend up to 100 of my tokens."
```

The token contract stores:

```text
allowance[Alice][UniswapRouter] = 100
```

#### `allowance`

Returns how many tokens a spender is still allowed to spend from an owner's balance.

```solidity
uint256 remaining = token.allowance(alice, uniswapRouter);
```

Allowances are critical for DeFi because users often need contracts to move tokens on their behalf.

#### `transferFrom`

Moves tokens from one address to another using a previously granted allowance.

```solidity
token.transferFrom(alice, pool, 25e18);
```

Usually called by a contract, not by the token owner.

Flow:

```text
1. Alice approves DEX to spend 100 TOKEN.
2. Alice calls swap on DEX.
3. DEX calls TOKEN.transferFrom(Alice, DEX, 100).
4. TOKEN checks allowance and balance.
5. TOKEN moves tokens and reduces allowance.
```

### Events

Events are logs emitted by contracts. Off-chain systems use them to index token activity.

#### `Transfer`

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

Emitted when tokens move, mint, or burn.

Common meanings:

| Event | Meaning |
|---|---|
| `Transfer(alice, bob, amount)` | Alice sent tokens to Bob |
| `Transfer(address(0), alice, amount)` | Minted tokens to Alice |
| `Transfer(alice, address(0), amount)` | Burned Alice's tokens |

#### `Approval`

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value);
```

Emitted when an owner updates a spender's allowance.

Wallets and explorers use this to show approvals.

### Decimals Explained

ERC20 balances are integers. Solidity does not use floating-point numbers for token balances.

`decimals` tells frontends how to display the integer.

Example with 18 decimals:

```text
Human display: 1.5 TOKEN
Raw integer:   1500000000000000000
Solidity:      1.5 * 10^18
```

In Solidity, write:

```solidity
uint256 oneToken = 1e18;
uint256 halfToken = 0.5e18; // Valid numeric literal in Solidity
```

Common decimals:

| Token | Decimals |
|---|---:|
| ETH / WETH | 18 |
| DAI | 18 |
| USDC | 6 |
| USDT | 6 |

Important: decimals are display metadata. They do not automatically change math. Your contract must use the token's actual decimals correctly.

### ERC20 Lifecycle

Typical lifecycle:

```text
Deploy token contract
        |
        v
Mint initial supply
        |
        v
Distribute tokens
        |
        v
Users transfer / approve / trade
        |
        v
Optional minting, burning, pausing, governance, upgrades
```

### Minting vs Transferring

Minting creates new tokens.

```text
totalSupply: 1,000 -> 1,100
Alice:          50 ->   150
```

Transferring moves existing tokens.

```text
totalSupply: 1,000 -> 1,000
Alice:         150 ->   100
Bob:            25 ->    75
```

Burning destroys tokens.

```text
totalSupply: 1,000 -> 900
Alice:         150 ->  50
```

### Allowances and DeFi

Allowances are one of the main reasons ERC20 works well with DeFi.

Smart contracts cannot take tokens from your wallet unless the token contract allows them to. `approve` is how you grant that permission.

Common DeFi examples:

- Swap tokens on Uniswap.
- Deposit USDC into Aave.
- Add liquidity to Curve.
- Stake governance tokens.
- Pay a protocol using an ERC20.

### How DEXs Use `approve` + `transferFrom`

Example: Alice swaps USDC for WETH.

```text
Alice wallet
  |
  | 1. approve(router, 100 USDC)
  v
USDC contract
  |
  | stores allowance[Alice][Router] = 100
  v
Alice wallet
  |
  | 2. swapExactTokensForETH(...)
  v
DEX Router
  |
  | 3. transferFrom(Alice, Pair, 100 USDC)
  v
USDC contract
```

The router does not own Alice's tokens before the swap. It only has permission to pull them during the transaction.

### Minimal ERC20 Implementation Example

This is educational, not production-ready. Use OpenZeppelin for real projects.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MinimalERC20 {
    string public name = "Bootcamp Token";
    string public symbol = "BOOT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance too low");

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero address");
        require(balanceOf[from] >= amount, "balance too low");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "zero address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }
}
```

### OpenZeppelin ERC20

OpenZeppelin provides audited, widely used implementations.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BootcampToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Bootcamp Token", "BOOT")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
```

### Common ERC20 Extensions

#### `ERC20Burnable`

Allows token holders to destroy their own tokens.

Useful for:

- Reducing supply.
- Redeeming wrapped assets.
- Burning game currency.

```solidity
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BurnableToken is ERC20Burnable {
    constructor() ERC20("Burnable Token", "BURN") {
        _mint(msg.sender, 1000e18);
    }
}
```

#### `ERC20Pausable`

Allows transfers to be paused in emergencies.

Useful for:

- Exploit response.
- Migration windows.
- Compliance controls.

Tradeoff: pausing introduces trust assumptions. Users must trust the pauser role.

#### `ERC20Permit`

Allows approvals by signature instead of requiring a separate approval transaction.

Why it matters:

- Better UX.
- Saves one transaction.
- Useful for gasless flows and DeFi routers.

Normal flow:

```text
approve transaction -> swap transaction
```

Permit flow:

```text
sign permit off-chain -> swap transaction uses signature
```

#### AccessControl Integration

For production systems, avoid giving one private key too much power. Role-based permissions are clearer.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin) ERC20("Role Token", "ROLE") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

### Security Considerations

- Use OpenZeppelin unless you have a strong reason not to.
- Be careful with mint permissions. Unlimited minting can destroy token value.
- Avoid hidden transfer fees unless clearly documented.
- Be careful with blacklist or pause logic because it changes user trust assumptions.
- Handle non-standard ERC20s in integrations. Some older tokens do not return `bool`.
- Use `SafeERC20` when your contract interacts with external ERC20s.
- Avoid approving unlimited allowances to untrusted contracts.
- Consider allowance race conditions when changing non-zero allowances.
- Emit events correctly for mints, burns, approvals, and transfers.

Example safe integration:

```solidity
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount) external {
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }
}
```

### Common ERC20 Mistakes

| Mistake | Why It Is Bad |
|---|---|
| Confusing `approve` with transfer | Approval only grants permission; it does not move tokens |
| Ignoring decimals | USDC has 6 decimals, many tokens have 18 |
| Using raw `transferFrom` without checking behavior | Some tokens are non-standard |
| Giving unlimited approvals to malicious contracts | The spender can drain approved tokens |
| Forgetting access control on `mint` | Anyone could create tokens |
| Assuming ERC20 tokens are held inside wallets | Balances live in the token contract |
| Not emitting events | Indexers and UIs may break |

### Real-World Examples

#### USDC

USDC is a centralized stablecoin backed by off-chain reserves. It is used for payments, DeFi collateral, trading pairs, and treasury management.

Important traits:

- Usually 6 decimals.
- Has centralized issuer controls.
- Integrates deeply across exchanges and DeFi.

#### DAI

DAI is a decentralized stablecoin associated with MakerDAO/Sky. It is generated through collateralized debt positions and protocol mechanisms.

Important traits:

- 18 decimals.
- Used heavily in DeFi.
- More protocol-driven than a fully centralized stablecoin.

#### WETH

WETH is wrapped ETH. Native ETH is not ERC20, so WETH wraps ETH into an ERC20-compatible token.

Mental model:

```text
Deposit 1 ETH into WETH contract -> receive 1 WETH
Burn 1 WETH from WETH contract   -> receive 1 ETH
```

WETH exists because DeFi contracts prefer standardized ERC20 interactions.

### Foundry Testing Examples

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BootcampToken} from "../src/BootcampToken.sol";

contract BootcampTokenTest is Test {
    BootcampToken token;
    address owner = address(1);
    address alice = address(2);
    address spender = address(3);

    function setUp() public {
        token = new BootcampToken(owner);
    }

    function testInitialSupplyGoesToOwner() public view {
        assertEq(token.balanceOf(owner), 1_000_000e18);
    }

    function testTransfer() public {
        vm.prank(owner);
        token.transfer(alice, 100e18);

        assertEq(token.balanceOf(alice), 100e18);
        assertEq(token.balanceOf(owner), 999_900e18);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(owner);
        token.approve(spender, 50e18);

        vm.prank(spender);
        token.transferFrom(owner, alice, 20e18);

        assertEq(token.balanceOf(alice), 20e18);
        assertEq(token.allowance(owner, spender), 30e18);
    }

    function testCannotTransferMoreThanBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(owner, 1e18);
    }
}
```

---

## 3. ERC721

ERC721 is the standard interface for non-fungible tokens, commonly called NFTs.

### What NFTs Really Are

An NFT is a unique token recorded by a smart contract.

The token itself is not usually the image, video, or game item file. The token is an on-chain ownership record that usually points to metadata, and the metadata points to media.

Typical NFT:

```text
ERC721 token ID #42
        |
        v
tokenURI()
        |
        v
metadata JSON
        |
        v
image / animation / attributes
```

### Fungible vs Non-Fungible

Fungible:

- Every unit is the same.
- 1 USDC equals 1 USDC.
- Balance is the important question.

Non-fungible:

- Each token has a unique ID.
- CryptoPunk #7804 is not the same as CryptoPunk #3100.
- Ownership of a specific ID is the important question.

Mental model:

- ERC20 is like dollars in a bank account.
- ERC721 is like numbered tickets, deeds, certificates, or collectibles.

### Token IDs

Each ERC721 token has a unique `uint256 tokenId`.

```text
Collection: BootcampBadges

Token #1 -> Alice
Token #2 -> Bob
Token #3 -> Alice
```

Alice owns two NFTs, but they are separate assets with different IDs.

### Ownership Model

ERC721 tracks:

- Which address owns a token ID.
- How many NFTs each address owns.
- Who is approved to transfer a specific token.
- Which operators are approved to transfer all of an owner's tokens.

Core questions:

```solidity
ownerOf(42);        // Who owns token #42?
balanceOf(alice);  // How many NFTs does Alice own?
```

### Metadata

Metadata describes what the NFT represents.

Common metadata fields:

- `name`
- `description`
- `image`
- `attributes`

The ERC721 contract usually returns a URI from `tokenURI(tokenId)`. That URI points to JSON metadata.

### `tokenURI`

`tokenURI` connects the on-chain token to off-chain or on-chain metadata.

```solidity
function tokenURI(uint256 tokenId) public view returns (string memory);
```

Example return values:

```text
ipfs://bafy.../42.json
https://api.example.com/metadata/42
data:application/json;base64,...
```

### NFT Collections

An NFT collection is one ERC721 contract that manages many token IDs.

Examples:

- Bored Ape Yacht Club.
- CryptoPunks style collectibles.
- Event attendance badges.
- Game characters.
- Real estate certificates.
- Membership passes.

The collection contract defines minting rules, transfer behavior, metadata logic, and permissions.

### Minting NFTs

Minting creates a new unique token ID.

```solidity
_safeMint(alice, 1);
```

Minting should answer:

- Who is allowed to mint?
- How many can be minted?
- How is the token ID assigned?
- What metadata does the token point to?
- Can metadata change later?

### `safeTransferFrom`

ERC721 has both regular and safe transfer functions.

```solidity
safeTransferFrom(from, to, tokenId);
```

Safe transfers check whether the receiving contract knows how to handle NFTs.

### Why Safe Transfers Exist

If you transfer an NFT to a contract that has no withdrawal logic and does not understand ERC721, the NFT can become stuck.

Safe transfer flow:

```text
Alice transfers NFT to contract
        |
        v
ERC721 checks recipient
        |
        v
If recipient is a contract, call onERC721Received
        |
        v
Recipient must return correct selector
```

Receiver example:

```solidity
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTVault is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
```

### ERC721 Events

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
```

Meanings:

| Event | Meaning |
|---|---|
| `Transfer(address(0), alice, tokenId)` | Mint |
| `Transfer(alice, bob, tokenId)` | Transfer |
| `Transfer(alice, address(0), tokenId)` | Burn |
| `Approval(owner, spender, tokenId)` | Spender can transfer one NFT |
| `ApprovalForAll(owner, operator, true)` | Operator can transfer all owner's NFTs |

### OpenZeppelin ERC721

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BootcampBadge is ERC721, Ownable {
    uint256 public nextTokenId;
    string private baseTokenURI;

    constructor(address initialOwner, string memory baseURI)
        ERC721("Bootcamp Badge", "BADGE")
        Ownable(initialOwner)
    {
        baseTokenURI = baseURI;
    }

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = ++nextTokenId;
        _safeMint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
```

### Base URI

Many collections store one base URI and build token metadata paths from token IDs.

```text
baseURI = ipfs://bafyCollectionCID/
tokenId = 42
tokenURI = ipfs://bafyCollectionCID/42
```

Some projects use `.json`:

```text
ipfs://bafyCollectionCID/42.json
```

OpenZeppelin's default `tokenURI` concatenates `_baseURI()` and `tokenId`.

### On-Chain vs Off-Chain Metadata

| Metadata Type | How It Works | Pros | Cons |
|---|---|---|---|
| Off-chain HTTP | `tokenURI` points to server API | Flexible, easy to update | Centralized, can disappear |
| IPFS | `tokenURI` points to content-addressed metadata | More decentralized, content integrity | Must pin content |
| On-chain JSON | Contract returns JSON directly | Strong permanence | More expensive |
| On-chain SVG/art | Art generated in contract | Fully on-chain | Complexity and gas costs |

### NFT Metadata JSON Structure

```json
{
  "name": "Bootcamp Badge #1",
  "description": "A badge awarded for completing the Web3 bootcamp NFT module.",
  "image": "ipfs://bafybeigdyrzt.../badge-1.png",
  "attributes": [
    {
      "trait_type": "Level",
      "value": "Beginner"
    },
    {
      "trait_type": "Cohort",
      "value": "Spring"
    }
  ]
}
```

Marketplaces read this JSON to display the NFT.

### Real-World Examples

- Profile picture collections.
- Music NFTs.
- Membership passes.
- Event tickets.
- In-game characters.
- Tokenized certificates.
- Domain names like ENS names.
- Real-world asset claims.

### Common NFT Misconceptions

| Misconception | Reality |
|---|---|
| The image is stored in the wallet | The wallet owns a token ID; metadata points to the image |
| NFTs are always images | NFTs are unique tokenized records and can represent many things |
| NFT ownership automatically gives copyright | Legal rights depend on license terms |
| IPFS means permanent by default | Someone must pin or host the content |
| `tokenURI` cannot change | It depends on the contract design |
| All NFTs are ERC721 | ERC1155 is also common |

### Security Considerations

- Use `_safeMint` when minting to arbitrary addresses.
- Protect mint functions with correct access control or payment logic.
- Avoid reentrancy problems when minting and refunding ETH.
- Be clear whether metadata is mutable or frozen.
- Avoid predictable randomness for valuable reveal mechanics.
- Limit max supply if scarcity matters.
- Be careful with `setApprovalForAll`; malicious operators can transfer all NFTs.
- Validate token existence before returning metadata.

### Gas Considerations

ERC721 can be expensive when minting many NFTs one by one.

Common gas patterns:

- Store a base URI instead of one full URI per token.
- Avoid large strings on-chain.
- Use batch minting extensions only when appropriate.
- Consider ERC721A-style implementations for large mint batches.
- Use ERC1155 if many tokens share the same contract and batch transfers matter.

### Minimal ERC721 Example

Educational only.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MinimalERC721 {
    string public name = "Minimal NFT";
    string public symbol = "MNFT";

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "not minted");
        return owner;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "zero address");
        return balances[owner];
    }

    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "not authorized");

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == from, "wrong owner");
        require(to != address(0), "zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");

        delete getApproved[tokenId];
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "zero address");
        require(owners[tokenId] == address(0), "already minted");

        owners[tokenId] = to;
        balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return spender == owner
            || getApproved[tokenId] == spender
            || isApprovedForAll[owner][spender];
    }
}
```

### Foundry Testing Examples

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BootcampBadge} from "../src/BootcampBadge.sol";

contract BootcampBadgeTest is Test {
    BootcampBadge badge;
    address owner = address(1);
    address alice = address(2);
    address bob = address(3);

    function setUp() public {
        badge = new BootcampBadge(owner, "ipfs://bafyExample/");
    }

    function testOwnerCanMint() public {
        vm.prank(owner);
        uint256 tokenId = badge.mint(alice);

        assertEq(tokenId, 1);
        assertEq(badge.ownerOf(1), alice);
        assertEq(badge.balanceOf(alice), 1);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert();
        badge.mint(alice);
    }

    function testTokenURIUsesBaseURI() public {
        vm.prank(owner);
        badge.mint(alice);

        assertEq(badge.tokenURI(1), "ipfs://bafyExample/1");
    }

    function testTransferFromApprovedUser() public {
        vm.prank(owner);
        badge.mint(alice);

        vm.prank(alice);
        badge.approve(bob, 1);

        vm.prank(bob);
        badge.transferFrom(alice, bob, 1);

        assertEq(badge.ownerOf(1), bob);
    }
}
```

---

## 4. ERC1155 Intro

ERC1155 is a multi-token standard. One contract can manage many token types at once.

### Why ERC1155 Was Created

ERC20 and ERC721 are useful, but they separate token types into different contracts.

Imagine a game with:

- Gold coins.
- Health potions.
- Swords.
- Armor.
- Rare one-of-one artifacts.
- Event tickets.

Using only ERC20 and ERC721, the game might need many contracts:

```text
Gold ERC20
Potion ERC20 or ERC721
Sword ERC721
Armor ERC721
Ticket ERC721
```

ERC1155 lets one contract manage all of these.

### Problems with ERC20 + ERC721 Separation

- Many contracts to deploy and manage.
- More gas overhead.
- Harder inventory indexing.
- No native batch transfers across token types.
- Repeated approval flows.

ERC1155 was designed for systems where many asset types belong together.

### Multi-Token Contracts

ERC1155 balances are tracked by both token ID and owner.

```text
balanceOf[Alice][Gold] = 1000
balanceOf[Alice][Sword] = 1
balanceOf[Alice][Potion] = 25
```

Each token ID can behave like:

- A fungible token.
- A non-fungible token.
- A semi-fungible token.

### Semi-Fungible Assets

A semi-fungible asset is fungible within a category but distinct from other categories.

Examples:

- 500 copies of the same concert ticket section.
- 10,000 identical game potions.
- 100 edition prints of the same artwork.
- 50 swords of the same type.

Token ID #7 might represent "Bronze Sword", and many users can own copies of that same ID.

### Gaming Use Cases

ERC1155 is common for games because games often have many item types:

| Token ID | Item | Fungibility |
|---:|---|---|
| 1 | Gold | Fungible |
| 2 | Health Potion | Fungible |
| 3 | Bronze Sword | Semi-fungible |
| 4 | Dragon Crown | Non-fungible if supply is 1 |

### Gas Efficiency Benefits

ERC1155 supports batch operations.

Instead of:

```text
transfer sword
transfer potion
transfer shield
transfer gold
```

You can do:

```text
safeBatchTransferFrom(alice, bob, [sword, potion, shield, gold], [1, 5, 1, 100])
```

One transaction can move many token IDs.

---

## 5. ERC1155

### ERC1155 Architecture

ERC1155 has:

- One contract.
- Many token IDs.
- A balance per owner per token ID.
- Single and batch transfer functions.
- Single and batch mint patterns.
- A shared metadata URI pattern.

Mental model:

```text
ERC1155 Inventory Contract

              Gold  Potion  Sword  Crown
Alice         1000     10      1      0
Bob            250      3      0      1
GameVault   90000   5000    100      0
```

### Token IDs and Balances

Unlike ERC721, ERC1155 does not have `ownerOf(tokenId)` because many addresses can own the same token ID.

Instead:

```solidity
balanceOf(alice, 1); // Alice's balance of token ID 1
```

Batch balance check:

```solidity
balanceOfBatch(accounts, ids);
```

### Batch Transfers

Single transfer:

```solidity
safeTransferFrom(from, to, id, amount, data);
```

Batch transfer:

```solidity
safeBatchTransferFrom(from, to, ids, amounts, data);
```

The `ids` and `amounts` arrays must match by index:

```text
ids     = [1, 2, 3]
amounts = [100, 5, 1]

Transfer:
100 units of token #1
5 units of token #2
1 unit of token #3
```

### Batch Minting

OpenZeppelin provides `_mintBatch`.

```solidity
uint256[] memory ids = new uint256[](3);
uint256[] memory amounts = new uint256[](3);

ids[0] = 1;
ids[1] = 2;
ids[2] = 3;

amounts[0] = 100;
amounts[1] = 10;
amounts[2] = 1;

_mintBatch(player, ids, amounts, "");
```

### Metadata System

ERC1155 usually has one URI template for all token IDs.

```solidity
uri(1);
```

Returns something like:

```text
ipfs://bafyExample/{id}.json
```

### URI Substitution

ERC1155 defines an `{id}` substitution pattern. Clients replace `{id}` with the token ID as a 64-character lowercase hexadecimal string, padded with zeros.

Example:

```text
Token ID: 1
Hex ID:   0000000000000000000000000000000000000000000000000000000000000001

URI:
ipfs://bafyExample/{id}.json

Resolved:
ipfs://bafyExample/0000000000000000000000000000000000000000000000000000000000000001.json
```

This surprises beginners because ERC721 often uses decimal IDs like `1.json`, while ERC1155 commonly expects padded hex IDs.

### OpenZeppelin ERC1155

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GameItems is ERC1155, Ownable {
    uint256 public constant GOLD = 1;
    uint256 public constant POTION = 2;
    uint256 public constant SWORD = 3;
    uint256 public constant DRAGON_CROWN = 4;

    constructor(address initialOwner)
        ERC1155("ipfs://bafyGameItems/{id}.json")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }
}
```

### Game Economy Example

```text
Player completes quest
        |
        v
Game backend or game contract decides rewards
        |
        v
Mint:
- 100 GOLD
- 3 POTION
- 1 SWORD
        |
        v
Player inventory updates in wallet/game UI
```

ERC1155 is useful because all rewards can be minted in one batch.

### Real-World Examples

- Game inventories.
- OpenSea shared storefront style collections.
- NFT editions.
- Membership tiers.
- Event ticket batches.
- Collectible card games.
- Asset bundles.

### ERC1155 vs ERC721

Use ERC721 when each token is individually unique and needs simple marketplace compatibility.

Use ERC1155 when:

- You have many item types.
- You need editions or semi-fungible items.
- Batch transfer or batch minting matters.
- One contract should manage a whole inventory system.

### ERC1155 vs ERC20

ERC20 is best when you have one fungible asset per contract, like a stablecoin.

ERC1155 can represent fungible balances too, but it is less common for major currencies because ERC20 has deeper DeFi compatibility.

### Gas Comparisons

General intuition:

| Operation | ERC20 | ERC721 | ERC1155 |
|---|---:|---:|---:|
| Transfer one fungible asset | Efficient | Not applicable | Efficient |
| Transfer one unique NFT | Not applicable | Standard | Works, but less common |
| Transfer many token types | Requires many calls/contracts | Requires many calls | Designed for this |
| Mint many item types | Requires many calls/contracts | Requires many calls | Batch minting |

ERC1155 does not always mean cheaper for every single action. Its advantage is strongest when handling multiple token IDs together.

### Common Misconceptions

| Misconception | Reality |
|---|---|
| ERC1155 is only for games | Games are common, but editions, tickets, and bundles also fit |
| ERC1155 replaces ERC721 | ERC721 remains better for many one-of-one NFT collections |
| Every ERC1155 token is fungible | Each ID can be fungible, semi-fungible, or supply-1 |
| `uri(id)` returns a unique string per ID automatically | Often it returns a template with `{id}` |
| ERC1155 works everywhere ERC721 works | Marketplace and wallet support can differ |

### Security Considerations

- Use safe transfer functions.
- Implement receiver hooks correctly for contracts that receive ERC1155 tokens.
- Validate array lengths in custom batch logic.
- Protect minting with roles.
- Be careful with operator approvals; `setApprovalForAll` gives access to all token IDs.
- Clearly define max supply per ID if scarcity matters.
- Avoid trusting metadata alone for game logic. Important game state should be verified on-chain or by trusted game servers.

Receiver example:

```solidity
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ERC1155Vault is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}
```

### Minimal ERC1155 Example

Educational only.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MinimalERC1155 {
    mapping(uint256 => mapping(address => uint256)) private balances;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return balances[id][account];
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata
    ) external {
        require(to != address(0), "zero address");
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "not approved");
        require(balances[id][from] >= amount, "balance too low");

        balances[id][from] -= amount;
        balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function mint(address to, uint256 id, uint256 amount) external {
        require(to != address(0), "zero address");

        balances[id][to] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }
}
```

### Foundry Testing Examples

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameItems} from "../src/GameItems.sol";

contract GameItemsTest is Test {
    GameItems items;
    address owner = address(1);
    address alice = address(2);
    address bob = address(3);

    function setUp() public {
        items = new GameItems(owner);
    }

    function testOwnerCanMintPotion() public {
        vm.prank(owner);
        items.mint(alice, items.POTION(), 5);

        assertEq(items.balanceOf(alice, items.POTION()), 5);
    }

    function testBatchMint() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = items.GOLD();
        ids[1] = items.SWORD();
        amounts[0] = 100;
        amounts[1] = 1;

        vm.prank(owner);
        items.mintBatch(alice, ids, amounts);

        assertEq(items.balanceOf(alice, items.GOLD()), 100);
        assertEq(items.balanceOf(alice, items.SWORD()), 1);
    }

    function testApprovedOperatorCanTransfer() public {
        vm.prank(owner);
        items.mint(alice, items.GOLD(), 100);

        vm.prank(alice);
        items.setApprovalForAll(bob, true);

        vm.prank(bob);
        items.safeTransferFrom(alice, bob, items.GOLD(), 30, "");

        assertEq(items.balanceOf(alice, items.GOLD()), 70);
        assertEq(items.balanceOf(bob, items.GOLD()), 30);
    }

    function testURI() public view {
        assertEq(items.uri(items.GOLD()), "ipfs://bafyGameItems/{id}.json");
    }
}
```

---

## 6. Comparison Tables

### ERC20 vs ERC721

| Feature | ERC20 | ERC721 |
|---|---|---|
| Token type | Fungible | Non-fungible |
| Main question | How many tokens does an address have? | Who owns this token ID? |
| Identity | Units are interchangeable | Each token ID is unique |
| Balance model | `balanceOf(owner)` | `balanceOf(owner)` counts NFTs |
| Ownership lookup | No `ownerOf` | `ownerOf(tokenId)` |
| Metadata | Usually name, symbol, decimals | Per-token metadata through `tokenURI` |
| Common use | Stablecoins, governance, DeFi | Art, badges, membership, collectibles |
| Transfer | `transfer(to, amount)` | `transferFrom(from, to, tokenId)` |
| Approval | Amount-based allowance | Token approval or operator approval |

### ERC721 vs ERC1155

| Feature | ERC721 | ERC1155 |
|---|---|---|
| Contract model | One collection of unique token IDs | One contract with many token types |
| Token uniqueness | Each token ID has one owner | Each token ID can have many holders |
| Ownership lookup | `ownerOf(id)` | No `ownerOf`; use `balanceOf(account, id)` |
| Batch operations | Not native in base standard | Native batch transfers and batch balances |
| Metadata | `tokenURI(id)` | `uri(id)` template with `{id}` |
| Best fit | Unique collectibles | Game items, editions, bundles |
| Marketplace support | Very broad | Broad, but sometimes more nuanced |
| Gas profile | Simple for individual NFTs | Efficient for many IDs at once |

### ERC20 vs ERC1155

| Feature | ERC20 | ERC1155 |
|---|---|---|
| Number of token types per contract | Usually one | Many |
| Fungible support | Yes | Yes, per token ID |
| DeFi compatibility | Excellent | More limited for standard DeFi |
| Batch transfers | Not native | Native |
| Decimals | Standard optional display convention | Not part of the same core pattern |
| Use case | Currency-like tokens | Inventory systems and multi-asset contracts |
| Approval model | Allowance by amount | Operator approval for all IDs |

---

## 7. Common Token Standard Mistakes

| Mistake | Better Mental Model |
|---|---|
| Thinking wallets physically contain tokens | Token contracts store balances and ownership records |
| Treating all tokens like ERC20s | ERC20, ERC721, and ERC1155 have different ownership and approval models |
| Assuming approval means transfer | Approval creates permission; a later call moves the asset |
| Ignoring metadata trust | NFT value often depends on where metadata points and whether it can change |
| Using custom token code casually | Standards have edge cases; OpenZeppelin reduces implementation risk |
| Forgetting receiver hooks | Safe ERC721/ERC1155 transfers to contracts require receiver support |
| Assuming ERC1155 has `ownerOf` | ERC1155 supports shared balances per ID, so ownership is balance-based |
| Overusing admin powers | Mint, pause, blacklist, and URI setters are trust assumptions users should understand |

---

## 8. Interview Tips

- Explain ERC20 as a standardized ledger of fungible balances.
- Explain `approve` and `transferFrom` using a DEX swap flow.
- Mention that ERC20 balances live in the token contract, not inside wallets.
- Explain NFTs as unique token IDs, not as image files.
- Explain that `tokenURI` usually points to metadata, and metadata points to media.
- Mention why safe transfers exist: to prevent tokens from being stuck in contracts.
- Explain ERC1155 as a multi-token inventory contract.
- Be clear that ERC1155 does not replace ERC721 or ERC20 in every situation.
- Bring up OpenZeppelin and `SafeERC20` when discussing production code.
- Mention access control, metadata mutability, approvals, and mint permissions as common security areas.

---

## 9. Key Takeaways

- ERC20 is for fungible assets like stablecoins, governance tokens, and wrapped assets.
- ERC721 is for unique assets where each token ID has one owner.
- ERC1155 is for multi-token systems where one contract manages many token IDs.
- Standards matter because they let wallets, exchanges, marketplaces, and protocols integrate with unknown tokens.
- `approve` does not transfer ERC20 tokens; it grants permission.
- NFT media is usually not stored directly in the token. The token points to metadata.
- IPFS metadata is only persistent if someone pins or hosts it.
- Use OpenZeppelin for production implementations.
- Design token permissions carefully. Minting, pausing, approvals, and metadata updates are major trust assumptions.
