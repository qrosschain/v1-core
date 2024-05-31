# Qross

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/qrosschain/v1-core/master/image.svg" width="500">
</div>

**QrossFactory** is a smart contract designed to facilitate the creation of cross-chain compatible ERC20 and ERC721 tokens. It simplifies the deployment process of these tokens by providing a factory pattern for their creation. The key components and functionalities of the QrossFactory are:

1. **Router and LINK Addresses**:

   - `router`: An address of the Chainlink router contract used for cross-chain communication.
   - `link`: An address of the LINK token contract used for paying fees.

2. **Events and Errors**:

   - `TokenCreated`: Emitted when a new token is created, capturing the token's address and the creator's address.
   - `CREATE2FailedOnDeploy`: Error thrown if the contract deployment via CREATE2 fails.

3. **Constructor**:

   - Initializes the factory with the router and LINK token addresses.

4. **Token Creation Functions**:

   - `createERC20`: Creates a new ERC20Q token, initializes it, and emits the `TokenCreated` event.
   - `createERC721`: Creates a new ERC721Q token, initializes it, and emits the `TokenCreated` event.

5. **Deployment Function**:
   - `deploy`: Uses the CREATE2 opcode to deploy a new contract with a unique address determined by a salt value. It combines the bytecode and constructor arguments.

### Cross-Chain Mint and Transfer of ERC20Q and ERC721Q

```solidity
import {ERC20Q} from "@qross/v1-core/contracts/ERC20Q.sol";
import {ERC721Q} from "@qross/v1-core/contracts/ERC721Q.sol";

contract MyToken is ERC20Q {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20Q(name_, symbol_) {}
}

contract MyNFT is ERC721Q {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721Q(name_, symbol_) {}
}

/**
 * After creating a token, the owner must initialize it.
 */

ERC20Q(payable(token)).init(msg.sender, router, link, maxSupply, tokenPrice);
ERC721Q(payable(token)).init(msg.sender, router, link, maxSupply, tokenPrice, baseURI);
```

**Cross-chain minting and transferring** in ERC20Q and ERC721Q contracts leverage Chainlink's CCIP (Cross-Chain Interoperability Protocol) to facilitate communication and asset transfer across different blockchain networks.

#### ERC20Q Cross-Chain Functionality

1. **Transfer Function**:
   - `transfer(to, value, chainSelector)`: Transfers tokens within the same chain or burns them and initiates a cross-chain transfer if `chainSelector` is non-zero.
2. **TransferFrom Function**:
   - `transferFrom(from, to, value, chainSelector)`: Similar to `transfer`, but for approved transfers.
3. **Cross-Minting**:
   - `_crossMint(account, value, chainSelector)`: Handles the cross-chain minting process by constructing and sending a CCIP message.

#### ERC721Q Cross-Chain Functionality

1. **TransferFrom Function**:

   - `transferFrom(from, to, tokenId, chainSelector)`: Transfers the token within the same chain or burns it and initiates a cross-chain transfer if `chainSelector` is non-zero.

2. **SafeTransferFrom Function**:

   - `safeTransferFrom(from, to, tokenId, chainSelector)`: Similar to `transferFrom`, but includes safety checks.

3. **Cross-Minting**:
   - `_crossMint(to, tokenId, chainSelector)`: Handles the cross-chain minting process by constructing and sending a CCIP message.

### Dev

```bash
PK=""
ADDR=$(cast wallet address --private-key $PK)

A_RPC="https://api.avax-test.network/ext/bc/C/rpc"
A_ROUTER="0xF694E193200268f9a4868e4Aa017A0118C9a8177"
A_LINK="0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
A_POLYGON_SELECTOR="16281711391670634445"
A_VER="https://api.routescan.io/v2/network/testnet/evm/43113/etherscan"

P_RPC="https://rpc-amoy.polygon.technology"
P_ROUTER="0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2"
P_LINK="0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904"
P_AVALANCHE_SELECTOR="14767482510784806043"
P_VER="https://api-amoy.polygonscan.com/api"

####################################################################################

# Create QrossFactory on Avalanche
forge create contracts/QrossFactory.sol:QrossFactory --rpc-url $A_RPC --constructor-args $A_ROUTER $A_LINK --private-key $PK --optimizer-runs 200 --gas-limit 5000000

# AFTER DEPLOY, SEND QF IN TERMINAL!!!!!
QF=""
# AFTER DEPLOY, SEND QF IN TERMINAL!!!!!

# Create token
cast send $QF "createERC20(string,string,uint256,uint256)" "Hello Token" "HLL" 10000000000000000000000 10000000000 --rpc-url $A_RPC --private-key $PK --gas-limit 2000000

# AFTER DEPLOY, SEND TOKEN IN TERMINAL!!!!!
TOKEN=""
# AFTER DEPLOY, SEND TOKEN IN TERMINAL!!!!!

# Mint 7 tokens
cast send $TOKEN "mint(address,uint256)" $ADDR 7000000000000000000 --value 70000000000 --private-key $PK --rpc-url $A_RPC

# Cross Mint 7 tokens
cast send $TOKEN "mint(address,uint256,uint64)" $ADDR 7000000000000000000 $A_POLYGON_SELECTOR --value 70000000000 --private-key $PK --rpc-url $A_RPC

# Cross Transfer 7 tokens
cast send $TOKEN "transfer(address,uint256,uint64)" $ADDR 7000000000000000000 $A_POLYGON_SELECTOR --private-key $PK --rpc-url $A_RPC

####################################################################################

# Create QrossFactory on Polygon
forge create contracts/QrossFactory.sol:QrossFactory --rpc-url $P_RPC --constructor-args $P_ROUTER $P_LINK --private-key $PK --optimizer-runs 200 --gas-limit 5000000

# AFTER CREATE TOKEN, SEND QF IN TERMINAL!!!!!
QF=""
# AFTER CREATE TOKEN, SEND QF IN TERMINAL!!!!!

# Create token
cast send $QF "createERC20(string,string,uint256,uint256)" "Hello Token" "HLL" 10000000000000000000000 10000000000 --rpc-url $P_RPC --private-key $PK --gas-limit 2000000

# AFTER DEPLOY, SEND TOKEN IN TERMINAL!!!!!
TOKEN=""
# AFTER DEPLOY, SEND TOKEN IN TERMINAL!!!!!

# Mint 7 tokens
cast send $TOKEN "mint(address,uint256)" $ADDR 7000000000000000000 --value 70000000000 --private-key $PK --rpc-url $P_RPC

# Cross Mint 7 tokens
cast send $TOKEN "mint(address,uint256,uint64)" $ADDR 7000000000000000000 $P_AVALANCHE_SELECTOR --value 70000000000 --private-key $PK --rpc-url $P_RPC

# Cross Transfer 7 tokens
cast send $TOKEN "transfer(address,uint256,uint64)" $ADDR 7000000000000000000 $P_AVALANCHE_SELECTOR --private-key $PK --rpc-url $P_RPC

####################################################################################

A_ARGS_QF=$(cast abi-encode "constructor(address,address)" $A_ROUTER $A_LINK)
A_ARGS_TOKEN=$(cast abi-encode "constructor(address,string,string,uint256,uint256,address,address)" $ADDR "Hello Token" "HLL" 10000000000000000000000 10000000000 $A_ROUTER $A_LINK)

# Verify QrossFactory on Avalanche
forge verify-contract $QF contracts/QrossFactory.sol:QrossFactory --verifier-url $A_VER --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version "0.8.24" --constructor-args $A_ARGS_QF

# Veerify token on Avalanche
forge verify-contract $TOKEN contracts/ERC20Q.sol:ERC20Q --verifier-url $A_VER --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version "0.8.24" --constructor-args $A_ARGS_TOKEN

####################################################################################

P_ARGS_QF=$(cast abi-encode "constructor(address,address)" $P_ROUTER $P_LINK)
P_ARGS_TOKEN=$(cast abi-encode "constructor(address,string,string,uint256,uint256,address,address)" $ADDR "Hello Token" "HLL" 10000000000000000000000 10000000000 $P_ROUTER $P_LINK)

# Verify QrossFactory on Polygon (NEED polygonscan api key)
forge verify-contract $QF contracts/QrossFactory.sol:QrossFactory --verifier-url $P_VER --etherscan-api-key "" --num-of-optimizations 200 --compiler-version "0.8.24" --constructor-args $P_ARGS_QF

# Veerify token on Polygon (NEED polygonscan api key)
forge verify-contract $HIT contracts/ERC20Q.sol:ERC20Q --verifier-url $P_VER --etherscan-api-key "" --num-of-optimizations 200 --compiler-version "0.8.24" --constructor-args $P_ARGS_TOKEN

####################################################################################

# A_CROSS_MINT_HEX=$(cast abi-encode "mint(address,uint256,uint64)" $ADDR 7000000000000000000 $A_POLYGON_SELECTOR)
# P_CROSS_MINT_HEX=$(cast abi-encode "mint(address,uint256,uint64)" $ADDR 7000000000000000000 $P_AVALANCHE_SELECTOR)

# CREATE_ERC20_HEX=$(cast abi-encode "createERC20(string,string,uint256,uint256)" "Hi Token" "HIT" 10000000000000000000000 10000000000)
# MINT_HEX=$(cast abi-encode "mint(address,uint256)" $ADDR 7000000000000000000)

# BYTECODE=$(forge inspect QrossFactory bytecode)
# SALT="0x0000000000000000000000000000000000000000000000000000000012345678"

# A_DEPLOYER=$(forge create contracts/Create2Deployer.sol:Create2Deployer --rpc-url $A_RPC --private-key $PK --json | jq -r '.deployedTo')
# QF=$(cast call $A_DEPLOYER "getAddress(bytes,bytes32)" $BYTECODE $SALT --rpc-url $A_RPC)
# cast send $A_DEPLOYER "deploy(bytes,uint256)" $BYTECODE $SALT --rpc-url $A_RPC --private-key $PK
# cast send $QF "init(address,address)" $A_ROUTER $A_LINK --rpc-url $A_RPC --private-key $PK --gas-limit 3000000

# P_DEPLOYER=$(forge create contracts/Create2Deployer.sol:Create2Deployer --rpc-url $P_RPC --private-key $PK --json | jq -r '.deployedTo')
# CREATE2_FACTORY_ADDRESS=$(cast call $P_DEPLOYER "getAddress(bytes,bytes32)" $BYTECODE $SALT --rpc-url $P_RPC)
# cast send $P_DEPLOYER "deploy(bytes,uint256)" $BYTECODE $SALT --rpc-url $P_RPC --private-key $PK --gas-limit 4500000
# cast send $QF "init(address,address)" $P_ROUTER $P_LINK --rpc-url $P_RPC --private-key $PK --gas-limit 3000000

####################################################################################
```
