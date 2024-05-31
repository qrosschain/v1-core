// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
.....................................................
:'#######::'########:::'#######:::'######:::'######::
'##.... ##: ##.... ##:'##.... ##:'##... ##:'##... ##:
 ##:::: ##: ##:::: ##: ##:::: ##: ##:::..:: ##:::..::
 ##:::: ##: ########:: ##:::: ##:. ######::. ######::
 ##:'## ##: ##.. ##::: ##:::: ##::..... ##::..... ##:
 ##:.. ##:: ##::. ##:: ##:::: ##:'##::: ##:'##::: ##:
: ##### ##: ##:::. ##:. #######::. ######::. ######::
:.....:..::..:::::..:::.......::::......::::......:::
 */

import {ERC20Q} from "@qross/v1-core/contracts/ERC20Q.sol";
import {ERC721Q} from "@qross/v1-core/contracts/ERC721Q.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract QrossFactory is ReentrancyGuard {
    event TokenCreated(address indexed tokenAddress, address indexed creator);

    error CREATE2FailedOnDeploy();
    error AlreadyInitialized();
    error NotOwner();

    address public router;
    address public link;
    bool public initialized;

    address private owner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function init(address router_, address link_) external onlyOwner {
        if (initialized) revert AlreadyInitialized();
        router = router_;
        link = link_;
        initialized = true;
    }

    function createERC20(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 tokenPrice
    ) public nonReentrant returns (ERC20Q token) {
        bytes32 salt = keccak256(abi.encode(msg.sender, name, symbol));
        address tokenAddress = deployCreate2Contract(
            type(ERC20Q).creationCode,
            abi.encode(address(this), name, symbol),
            salt
        );
        token = ERC20Q(payable(tokenAddress));
        token.init(msg.sender, router, link, maxSupply, tokenPrice);
        emit TokenCreated(tokenAddress, msg.sender);
    }

    function createERC721(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 tokenPrice,
        string memory baseURI
    ) public nonReentrant returns (ERC721Q token) {
        bytes32 salt = keccak256(abi.encode(msg.sender, name, symbol, baseURI));
        address tokenAddress = deployCreate2Contract(
            type(ERC721Q).creationCode,
            abi.encode(address(this), name, symbol, baseURI),
            salt
        );
        token = ERC721Q(payable(tokenAddress));
        token.init(msg.sender, router, link, maxSupply, tokenPrice);
        emit TokenCreated(tokenAddress, msg.sender);
    }

    function deployCreate2Contract(
        bytes memory bytecode,
        bytes memory constructorArgs,
        bytes32 salt
    ) internal returns (address contractAddress) {
        bytes memory deploymentBytecode = abi.encodePacked(
            bytecode,
            constructorArgs
        );
        assembly {
            contractAddress := create2(
                0,
                add(deploymentBytecode, 0x20),
                mload(deploymentBytecode),
                salt
            )
        }
        if (contractAddress == address(0)) revert CREATE2FailedOnDeploy();
    }
}
