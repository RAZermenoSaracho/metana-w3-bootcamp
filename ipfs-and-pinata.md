# Introduction to IPFS and Pinata

NFTs often need images, metadata, attributes, animations, and other files. Ethereum can store small pieces of data directly on-chain, but storing large files on-chain is expensive. IPFS is a common way to store NFT data with better decentralization and content integrity than a normal web server.

Pinata is a pinning service that helps keep IPFS files available.

---

## Table of Contents

- [1. How to Persist NFT Data with IPFS](#1-how-to-persist-nft-data-with-ipfs)
- [2. What Is IPFS](#2-what-is-ipfs)
- [3. What Is an IPFS CID](#3-what-is-an-ipfs-cid)
- [4. What Is an IPFS Pinning Service](#4-what-is-an-ipfs-pinning-service)
- [5. Why NFT Data Should Be Hosted on IPFS](#5-why-nft-data-should-be-hosted-on-ipfs)
- [6. How Do You Upload to IPFS](#6-how-do-you-upload-to-ipfs)
- [7. Example Solidity Integration](#7-example-solidity-integration)
- [8. Foundry Testing Examples](#8-foundry-testing-examples)
- [9. Common Mistakes](#9-common-mistakes)
- [10. Interview Tips](#10-interview-tips)
- [11. Key Takeaways](#11-key-takeaways)

---

## 1. How to Persist NFT Data with IPFS

### Why NFT Metadata Matters

An NFT contract usually stores ownership, not the full artwork.

For an ERC721 token, the contract can answer:

```text
Who owns token #1?
What URI describes token #1?
```

The metadata answers:

```text
What is token #1 called?
What image should marketplaces display?
What traits does it have?
What external links or animation files belong to it?
```

Without metadata, a marketplace may know that Alice owns token #1, but it may not know what token #1 looks like.

### Why Storing Images Directly On-Chain Is Expensive

Ethereum storage is intentionally expensive because every full node must store and verify the blockchain state.

Mental model:

- Uploading an image to a normal server stores it once.
- Storing an image on Ethereum asks the network to preserve it in blockchain state.
- Every node has to carry that data.

This is why most NFT projects avoid storing large PNG, JPG, GIF, MP4, or GLB files directly in contract storage.

On-chain data can be powerful, but it should be used deliberately.

### Typical NFT Architecture

```text
User wallet
   |
   | owns
   v
ERC721 / ERC1155 smart contract
   |
   | tokenURI(tokenId)
   v
Metadata JSON
   |
   | image / animation_url
   v
Image, video, 3D file, or other media
```

### NFT Image Flow

```text
1. Create image file
        |
        v
2. Upload image to IPFS
        |
        v
3. Receive image CID
        |
        v
4. Put image URI inside metadata JSON
        |
        v
5. Upload metadata JSON to IPFS
        |
        v
6. Store metadata URI in NFT contract
```

### Metadata Flow

Example:

```text
image.png
  -> uploaded to IPFS
  -> ipfs://bafyImageCid/image.png

1.json
  -> contains "image": "ipfs://bafyImageCid/image.png"
  -> uploaded to IPFS
  -> ipfs://bafyMetadataCid/1.json

NFT contract
  -> tokenURI(1) returns ipfs://bafyMetadataCid/1.json
```

### `tokenURI` Relationship

`tokenURI` is the bridge between the on-chain token and its metadata.

```solidity
function tokenURI(uint256 tokenId) public view returns (string memory);
```

Marketplaces call `tokenURI`, fetch the JSON, then fetch the image from the JSON.

```text
OpenSea / wallet / frontend
        |
        | calls tokenURI(1)
        v
NFT contract
        |
        | returns ipfs://bafyMetadataCid/1.json
        v
Marketplace fetches metadata
        |
        | reads image field
        v
Marketplace fetches image
```

---

## 2. What Is IPFS

IPFS stands for InterPlanetary File System. It is a peer-to-peer protocol for storing and sharing files by their content.

### Decentralized File Storage Explained Simply

Traditional web:

```text
Where is the file?
https://example.com/images/cat.png
```

IPFS:

```text
What is the file?
ipfs://bafy...contentHash...
```

Traditional URLs point to a location. IPFS CIDs point to content.

### Mental Model

IPFS is like asking:

> "Does anyone in the network have the file whose fingerprint is this exact hash?"

Instead of:

> "Please ask this specific company's server for `/image.png`."

### Content-Addressed Storage

IPFS uses content addressing. A file is identified by a cryptographic hash of its content.

If the content changes, the hash changes.

That means:

- You can verify that the file you received is the file you asked for.
- A project cannot silently change the file while keeping the same CID.
- The CID acts like a fingerprint for the data.

### IPFS vs Traditional Servers

| Feature | Traditional Server | IPFS |
|---|---|---|
| Address style | Location-based URL | Content-based CID |
| Example | `https://example.com/1.json` | `ipfs://bafy.../1.json` |
| Who serves it | Specific server | Any peer or gateway with the content |
| If file changes | Same URL can return different content | CID changes |
| Availability | Depends on server uptime | Depends on peers pinning/hosting content |
| Trust model | Trust server operator | Verify content by hash |

### Why IPFS Matters in Web3

Web3 applications often care about:

- User ownership.
- Public verification.
- Reduced platform dependence.
- Long-term availability.
- Fewer centralized points of failure.

IPFS helps because NFT metadata can be referenced by content rather than by a mutable server URL.

---

## 3. What Is an IPFS CID

CID means Content Identifier.

It is the identifier IPFS uses to find and verify content.

### What a CID Is

A CID is not a random ID. It is derived from the content and encoding details.

Example CIDs:

```text
QmYwAPJzv5CZsnAzt8auVZRnG9j3vKys4p6n4JV7X7rj3A
bafybeigdyrzt5sfp7udm7hu76szxp4ewnyxcl4wbrf77s2nnd5xnprbbdm
```

The first style is commonly CIDv0. The second style is commonly CIDv1.

### Why Hashes Identify Content

A cryptographic hash is like a fingerprint:

- Same file -> same hash.
- Different file -> different hash.
- Tiny change -> very different hash.

Example:

```text
metadata A:
{"name":"Badge #1"}

metadata B:
{"name":"Badge #2"}

Different content means different CID.
```

### Why Changing a File Changes the CID

If you upload `1.json`, then edit one character and upload again, the CID changes.

This is a feature, not a bug.

It prevents silent changes:

```text
Old CID -> old content
New CID -> new content
```

If an NFT contract stores the old CID, users can detect that the referenced metadata did not change.

### CIDv0 vs CIDv1

| Feature | CIDv0 | CIDv1 |
|---|---|---|
| Common prefix | Usually starts with `Qm` | Often starts with `bafy` |
| Encoding | Base58btc | Supports multiple encodings, often base32 |
| Gateway subdomains | Less ideal | Better support |
| Modern recommendation | Older but common | Preferred for newer usage |

CIDv1 is commonly used with subdomain gateways because it can be encoded in a DNS-safe lowercase format.

### How Gateways Work

Browsers do not natively load `ipfs://` in all contexts. Gateways provide HTTP access to IPFS content.

IPFS URI:

```text
ipfs://bafyMetadataCid/1.json
```

Gateway URL:

```text
https://ipfs.io/ipfs/bafyMetadataCid/1.json
https://gateway.pinata.cloud/ipfs/bafyMetadataCid/1.json
```

Subdomain gateway:

```text
https://bafyMetadataCid.ipfs.dweb.link/1.json
```

Important: the gateway is just a way to access IPFS through HTTP. The canonical NFT metadata URI should often remain `ipfs://...`.

---

## 4. What Is an IPFS Pinning Service

### Why Files Disappear If Nobody Hosts Them

IPFS does not magically store every file forever.

If nobody has your file anymore, the network cannot serve it.

Mental model:

- A CID tells the network what file you want.
- Pinning makes sure someone keeps a copy available.
- Without a pinned or hosted copy, the CID may become unreachable.

### What Pinning Means

Pinning means telling an IPFS node:

```text
Keep this content. Do not garbage collect it.
```

When content is pinned, that node continues storing and serving it.

### Persistence Problem Explained

IPFS gives content addressing, not automatic permanence.

These are different:

| Concept | Meaning |
|---|---|
| Content addressing | The CID verifies what the file is |
| Availability | Someone can serve the file |
| Permanence | The file remains available over time |

Pinning helps with availability and persistence.

### Why Pinata Exists

Pinata is a service that pins IPFS content for you. Instead of running your own IPFS infrastructure, you can upload files through Pinata and rely on Pinata to keep them available.

Pinata helps with:

- Uploading files and folders.
- Pinning content.
- Managing CIDs.
- Using gateways.
- Team workflows.
- API-based uploads.

### Other Pinning Services

Other common options include:

- NFT.Storage.
- web3.storage.
- Filebase.
- Infura IPFS.
- Fleek.
- Running your own IPFS node.

The right choice depends on reliability, cost, API needs, gateway performance, and decentralization goals.

---

## 5. Why NFT Data Should Be Hosted on IPFS

### Risks of Centralized Hosting

If NFT metadata points to a normal server:

```text
https://my-nft-project.com/api/token/1
```

The project team can:

- Change the metadata.
- Change the image.
- Shut down the server.
- Lose the domain.
- Block requests.
- Accidentally break the API.

That does not always mean centralized hosting is unacceptable, but users should understand the trust assumption.

### Broken NFT Metadata Examples

Broken metadata can look like:

- Images no longer loading.
- Collection traits disappearing.
- All NFTs showing the same placeholder.
- Marketplaces unable to refresh metadata.
- API returning `404`.
- Domain expiring and being bought by someone else.

### Why Decentralization Matters

NFT buyers often expect that the asset they bought will continue to resolve to the same content. IPFS helps because the content is identified by CID.

If metadata is:

```text
ipfs://bafyOriginalMetadata/1.json
```

Then a server operator cannot silently change what that CID means. They would need a new CID.

### Permanence

IPFS improves permanence when content is pinned by one or more reliable parties.

Best practice:

- Pin through a service like Pinata.
- Keep backups.
- Consider multiple pinning providers for important collections.
- Store final IPFS URIs in the contract.
- Freeze metadata when appropriate.

### Trust Assumptions

Different designs have different trust assumptions.

| Design | Trust Assumption |
|---|---|
| HTTP API metadata | Trust server operator to keep serving correct data |
| IPFS metadata, mutable base URI | Trust contract admin not to change base URI |
| IPFS metadata, frozen URI | Trust pinning availability |
| Fully on-chain metadata | Trust contract code and chain permanence |

### NFT Metadata Rug-Pull Examples

A metadata rug pull happens when the asset's metadata changes in a way that harms holders.

Examples:

- Art replaced with a blank image.
- Rare traits changed after mint.
- Metadata server shut down after selling out.
- Reveal process swaps promised art for lower-quality assets.
- Admin changes base URI to point to different content.

IPFS does not solve every rug risk, but it makes content changes visible because changed content gets a changed CID.

---

## 6. How Do You Upload to IPFS

### Upload Flow Step-by-Step

For an NFT collection, the usual flow is:

```text
1. Prepare image files
2. Upload image folder to IPFS
3. Copy image CID
4. Create metadata JSON files using image ipfs:// URIs
5. Upload metadata folder to IPFS
6. Copy metadata CID
7. Set contract base URI to ipfs://metadataCID/
8. Mint NFTs
9. Verify tokenURI returns the expected metadata URI
10. Pin and back up content
```

### Using Pinata

Typical Pinata dashboard flow:

```text
1. Create Pinata account
2. Open upload page
3. Upload image file or image folder
4. Wait for Pinata to return a CID
5. Use that CID in metadata JSON
6. Upload metadata JSON file or folder
7. Copy metadata CID
8. Use ipfs://metadataCID/... in your smart contract
```

### Uploading Images

Suppose you upload a folder:

```text
images/
  1.png
  2.png
  3.png
```

Pinata returns:

```text
bafyImagesCid
```

Your image URIs become:

```text
ipfs://bafyImagesCid/1.png
ipfs://bafyImagesCid/2.png
ipfs://bafyImagesCid/3.png
```

### Uploading Metadata JSON

Metadata folder:

```text
metadata/
  1.json
  2.json
  3.json
```

Each JSON file references the image:

```json
{
  "name": "Bootcamp Badge #1",
  "description": "A badge for completing a Web3 bootcamp lesson.",
  "image": "ipfs://bafyImagesCid/1.png",
  "attributes": [
    {
      "trait_type": "Track",
      "value": "Solidity"
    },
    {
      "trait_type": "Level",
      "value": "Beginner"
    }
  ]
}
```

Pinata returns metadata folder CID:

```text
bafyMetadataCid
```

The token URI becomes:

```text
ipfs://bafyMetadataCid/1.json
```

### Getting a CID

After upload, Pinata displays a CID. You may see:

```text
bafybeigdyrzt5sfp7udm7hu76szxp4ewnyxcl4wbrf77s2nnd5xnprbbdm
```

Use it in an IPFS URI:

```text
ipfs://bafybeigdyrzt5sfp7udm7hu76szxp4ewnyxcl4wbrf77s2nnd5xnprbbdm
```

For folders:

```text
ipfs://bafyFolderCid/1.json
ipfs://bafyFolderCid/image.png
```

### Creating an `ipfs://` URI

The canonical form:

```text
ipfs://<CID>
ipfs://<CID>/<path-inside-folder>
```

Examples:

```text
ipfs://bafyImagesCid/1.png
ipfs://bafyMetadataCid/1.json
```

### Using IPFS Gateways

To view in a normal browser:

```text
https://gateway.pinata.cloud/ipfs/bafyMetadataCid/1.json
https://ipfs.io/ipfs/bafyMetadataCid/1.json
```

For NFT metadata, prefer storing:

```text
ipfs://bafyMetadataCid/1.json
```

instead of:

```text
https://gateway.pinata.cloud/ipfs/bafyMetadataCid/1.json
```

Reason: gateway URLs depend on a specific gateway provider. `ipfs://` keeps the reference provider-neutral.

### Example Pinata Upload Flow

```text
Step 1: Upload images folder

images/
  1.png
  2.png

Pinata returns:
ipfs://bafyImagesCid

Step 2: Create metadata files

metadata/1.json:
{
  "name": "Bootcamp Badge #1",
  "description": "Completed the token standards module.",
  "image": "ipfs://bafyImagesCid/1.png"
}

metadata/2.json:
{
  "name": "Bootcamp Badge #2",
  "description": "Completed the IPFS module.",
  "image": "ipfs://bafyImagesCid/2.png"
}

Step 3: Upload metadata folder

Pinata returns:
ipfs://bafyMetadataCid

Step 4: Use base URI in contract

baseURI = "ipfs://bafyMetadataCid/"
tokenURI(1) = "ipfs://bafyMetadataCid/1.json"
```

### Common Upload Mistakes

| Mistake | Fix |
|---|---|
| Upload metadata before knowing image CID | Upload images first, then write metadata |
| Use `https://` gateway URL in `image` field when `ipfs://` is better | Prefer `ipfs://CID/path` |
| Forget file extensions | Match exactly: `1.json`, `1.png` |
| Use wrong folder level | Check whether CID points to folder or file |
| Change metadata after setting URI | New content creates new CID |
| Do not pin content | Use Pinata or another pinning setup |
| Use ERC1155 decimal filenames instead of padded hex | Follow ERC1155 `{id}` convention when needed |

---

## 7. Example Solidity Integration

### Simple ERC721 Metadata Setup

This contract uses a base URI. If base URI is `ipfs://bafyMetadataCid/`, then token `1` resolves to `ipfs://bafyMetadataCid/1`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleIPFSNFT is ERC721, Ownable {
    uint256 public nextTokenId;
    string private baseTokenURI;

    constructor(address initialOwner, string memory baseURI)
        ERC721("Simple IPFS NFT", "SINFT")
        Ownable(initialOwner)
    {
        baseTokenURI = baseURI;
    }

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = ++nextTokenId;
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
```

If you want `.json` at the end, override `tokenURI`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract JsonMetadata is ERC721 {
    using Strings for uint256;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        return string.concat(_baseURI(), tokenId.toString(), ".json");
    }
}
```

Example result:

```text
baseURI:     ipfs://bafyMetadataCid/
tokenURI(1): ipfs://bafyMetadataCid/1.json
```

### Immutable Base URI Pattern

If metadata should never change, do not include a setter.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FrozenMetadataNFT is ERC721, Ownable {
    string private immutable baseTokenURI;
    uint256 public nextTokenId;

    constructor(address initialOwner, string memory baseURI)
        ERC721("Frozen Metadata NFT", "FREEZE")
        Ownable(initialOwner)
    {
        baseTokenURI = baseURI;
    }

    function mint(address to) external onlyOwner {
        _safeMint(to, ++nextTokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
```

Tradeoff:

- Immutable URI improves trust.
- Mutable URI allows fixing mistakes.

For production collections, teams often use a reveal phase, then freeze metadata after reveal.

### ERC1155 Metadata Setup

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IPFSGameItems is ERC1155, Ownable {
    uint256 public constant GOLD = 1;
    uint256 public constant POTION = 2;

    constructor(address initialOwner)
        ERC1155("ipfs://bafyGameMetadata/{id}.json")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }
}
```

ERC1155 metadata files often use padded hex names:

```text
metadata/
  0000000000000000000000000000000000000000000000000000000000000001.json
  0000000000000000000000000000000000000000000000000000000000000002.json
```

### Example ERC721 Metadata JSON

```json
{
  "name": "Simple IPFS NFT #1",
  "description": "An example NFT whose metadata and image are stored on IPFS.",
  "image": "ipfs://bafyImagesCid/1.png",
  "external_url": "https://example.com/nft/1",
  "attributes": [
    {
      "trait_type": "Background",
      "value": "Blue"
    },
    {
      "trait_type": "Level",
      "value": 1
    },
    {
      "trait_type": "Completed Module",
      "value": "IPFS"
    }
  ]
}
```

### Example ERC1155 Metadata JSON

```json
{
  "name": "Health Potion",
  "description": "Restores health inside the Bootcamp RPG.",
  "image": "ipfs://bafyGameImages/potion.png",
  "properties": {
    "rarity": "Common",
    "category": "Consumable"
  }
}
```

---

## 8. Foundry Testing Examples

### Test ERC721 `tokenURI`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleIPFSNFT} from "../src/SimpleIPFSNFT.sol";

contract SimpleIPFSNFTTest is Test {
    SimpleIPFSNFT nft;
    address owner = address(1);
    address alice = address(2);

    function setUp() public {
        nft = new SimpleIPFSNFT(owner, "ipfs://bafyMetadataCid/");
    }

    function testMintAndTokenURI() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.tokenURI(1), "ipfs://bafyMetadataCid/1");
    }

    function testOwnerCanUpdateBaseURI() public {
        vm.prank(owner);
        nft.mint(alice);

        vm.prank(owner);
        nft.setBaseURI("ipfs://bafyNewMetadataCid/");

        assertEq(nft.tokenURI(1), "ipfs://bafyNewMetadataCid/1");
    }

    function testNonOwnerCannotUpdateBaseURI() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.setBaseURI("ipfs://malicious/");
    }
}
```

### Test Metadata Freeze Assumption

If a collection claims metadata is frozen, test that no setter exists or that calling one is impossible.

```solidity
function testFrozenBaseURI() public {
    FrozenMetadataNFT frozen = new FrozenMetadataNFT(owner, "ipfs://bafyFrozen/");

    vm.prank(owner);
    frozen.mint(alice);

    assertEq(frozen.tokenURI(1), "ipfs://bafyFrozen/1");
}
```

### Test ERC1155 URI Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IPFSGameItems} from "../src/IPFSGameItems.sol";

contract IPFSGameItemsTest is Test {
    IPFSGameItems items;
    address owner = address(1);
    address alice = address(2);

    function setUp() public {
        items = new IPFSGameItems(owner);
    }

    function testURIUsesTemplate() public view {
        assertEq(items.uri(items.POTION()), "ipfs://bafyGameMetadata/{id}.json");
    }

    function testMintPotion() public {
        vm.prank(owner);
        items.mint(alice, items.POTION(), 3);

        assertEq(items.balanceOf(alice, items.POTION()), 3);
    }
}
```

---

## 9. Common Mistakes

### Mistake: Thinking IPFS Means Permanent Forever

IPFS does not guarantee permanent storage by itself. A CID may stop resolving if nobody hosts the content.

Fix:

- Pin files.
- Use reliable pinning providers.
- Keep backups.
- Consider multiple providers for valuable collections.

### Mistake: Storing Gateway URLs as Canonical Metadata

Gateway URL:

```text
https://gateway.pinata.cloud/ipfs/bafyMetadataCid/1.json
```

Better canonical URI:

```text
ipfs://bafyMetadataCid/1.json
```

Gateways can go down or rate limit. `ipfs://` is provider-neutral.

### Mistake: Uploading Metadata Before Images

Metadata usually needs image CIDs. Upload images first, then build metadata.

### Mistake: Wrong Folder Structure

If you upload a folder, paths matter.

If the uploaded folder contains:

```text
metadata/
  1.json
```

Your URI may be:

```text
ipfs://CID/1.json
```

or:

```text
ipfs://CID/metadata/1.json
```

depending on how the folder was uploaded. Always test gateway resolution before setting the contract URI.

### Mistake: Assuming Metadata Is Immutable Because It Uses IPFS

The content at a CID is immutable, but the contract may still allow changing the base URI to a different CID.

Check the contract:

```solidity
function setBaseURI(string calldata newBaseURI) external onlyOwner;
```

If this exists, metadata can change unless ownership is renounced, the setter is disabled, or metadata is frozen by design.

### Mistake: ERC1155 `{id}` Filename Confusion

ERC1155 clients often expect padded hex filenames.

Token ID `1`:

```text
0000000000000000000000000000000000000000000000000000000000000001.json
```

Not always:

```text
1.json
```

### Mistake: Forgetting JSON Validity

Small JSON mistakes can break display:

- Trailing commas.
- Wrong quotes.
- Incorrect field names.
- Invalid image URI.
- Missing file extension.

Validate JSON before uploading.

---

## 10. Interview Tips

- Explain that NFTs usually store ownership on-chain and metadata/media off-chain.
- Explain `tokenURI` as the link between token ID and metadata.
- Describe IPFS as content-addressed storage, not a blockchain.
- Be clear that a CID identifies content, not a company server.
- Mention that changing a file changes its CID.
- Explain pinning as keeping content available.
- Mention that IPFS does not guarantee permanence unless content is pinned or hosted.
- Prefer `ipfs://` as the canonical NFT URI and use gateways only for HTTP access.
- Discuss metadata mutability as a trust assumption.
- Know the upload order: images first, metadata second, contract URI last.

---

## 11. Key Takeaways

- NFT metadata tells wallets and marketplaces what an NFT represents.
- Storing large media directly on Ethereum is usually too expensive.
- IPFS identifies files by content, not by server location.
- A CID is a fingerprint for content. Change the content and the CID changes.
- IPFS improves integrity, but availability requires pinning.
- Pinata is a pinning service that helps keep IPFS files online.
- Use `ipfs://CID/path` in metadata and contracts when possible.
- Upload images first, then metadata JSON, then set the contract URI.
- Test every metadata URL before minting or revealing.
- Metadata mutability is a major trust assumption in NFT projects.
